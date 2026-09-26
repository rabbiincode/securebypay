import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { ChallengePurpose, Prisma, User } from "@prisma/client";
import { JwtService } from "@nestjs/jwt";
import * as argon2 from "argon2";
import { createHash, createHmac, randomBytes, randomInt } from "node:crypto";
import { PrismaService } from "../database/prisma.service";
import { NotificationService } from "../notifications/notification.service";
import { EnvService } from "../config/env.service";
import { LoginDto } from "./dto/login.dto";
import { RegisterDto } from "./dto/register.dto";
import {
  assertPasswordExcludesPersonalData,
  passwordContainsPersonalData,
} from "./password-policy";

const CODE_TTL_MINUTES = 5;
const MAX_CODE_ATTEMPTS = 5;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: EnvService,
    private readonly notifications: NotificationService,
  ) {}

  async register(input: RegisterDto) {
    const email = input.email.trim().toLowerCase();
    assertPasswordExcludesPersonalData(input.password, input);
    if (await this.prisma.user.findUnique({ where: { email } }))
      throw new ConflictException("An account with this email already exists");
    const user = await this.prisma.user.create({
      data: {
        email,
        firstName: input.firstName.trim(),
        lastName: input.lastName.trim(),
        phoneNumber: input.phoneNumber?.trim(),
        passwordHash: await argon2.hash(input.password),
      },
    });
    const challenge = await this.issueChallenge(
      user,
      ChallengePurpose.EMAIL_VERIFICATION,
    );
    await this.audit(user.id, "account.registered");
    return {
      requiresVerification: true,
      challengeId: challenge.id,
      destination: this.maskEmail(email),
      expiresInSeconds: CODE_TTL_MINUTES * 60,
    };
  }

  async login(input: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: input.email.trim().toLowerCase() },
    });
    if (
      !user?.passwordHash ||
      !(await argon2.verify(user.passwordHash, input.password))
    )
      throw new UnauthorizedException("Invalid email or password");
    if (passwordContainsPersonalData(input.password, user))
      throw new UnauthorizedException("Invalid email or password");
    if (!user.emailVerified)
      throw new ForbiddenException({
        message: "Email verification required",
        code: "EMAIL_NOT_VERIFIED",
      });
    const challenge = await this.issueChallenge(user, ChallengePurpose.SIGN_IN);
    await this.audit(user.id, "sign_in.challenge_created");
    return {
      requiresVerification: true,
      challengeId: challenge.id,
      destination: this.maskEmail(user.email),
      expiresInSeconds: CODE_TTL_MINUTES * 60,
    };
  }

  async verifySignIn(challengeId: string, code: string) {
    const user = await this.consumeChallenge(
      challengeId,
      code,
      ChallengePurpose.SIGN_IN,
    );
    await this.audit(user.id, "sign_in.completed");
    return this.createSession(user);
  }

  async verifyEmail(challengeId: string, code: string) {
    const user = await this.consumeChallenge(
      challengeId,
      code,
      ChallengePurpose.EMAIL_VERIFICATION,
    );
    const verifiedUser = await this.prisma.user.update({
      where: { id: user.id },
      data: { emailVerified: new Date() },
    });
    await this.audit(user.id, "email.verified");
    return this.createSession(verifiedUser);
  }

  async resendEmailVerification(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
    });
    if (user && !user.emailVerified)
      await this.issueChallenge(user, ChallengePurpose.EMAIL_VERIFICATION);
    return {
      message:
        "If the account exists and is not verified, a new code has been sent.",
    };
  }

  async requestPasswordReset(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
    });
    const challengeId = user
      ? (await this.issueChallenge(user, ChallengePurpose.PASSWORD_RESET)).id
      : randomBytes(16).toString("hex");
    return {
      message: "If the account exists, a password-reset code has been sent.",
      challengeId,
    };
  }

  async resetPassword(challengeId: string, code: string, newPassword: string) {
    const pendingChallenge = await this.prisma.verificationChallenge.findUnique(
      { where: { id: challengeId }, include: { user: true } },
    );
    if (pendingChallenge?.purpose === ChallengePurpose.PASSWORD_RESET) {
      assertPasswordExcludesPersonalData(newPassword, pendingChallenge.user);
    }
    const user = await this.consumeChallenge(
      challengeId,
      code,
      ChallengePurpose.PASSWORD_RESET,
    );
    const passwordHash = await argon2.hash(newPassword);
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: user.id },
        data: { passwordHash },
      }),
      this.prisma.session.updateMany({
        where: { userId: user.id, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
      this.prisma.auditEvent.create({
        data: { userId: user.id, action: "password.reset" },
      }),
    ]);
    return { message: "Password reset successfully. Please sign in." };
  }

  async refresh(refreshToken: string) {
    if (!refreshToken) throw new UnauthorizedException();
    try {
      await this.jwt.verifyAsync(refreshToken, {
        secret: this.config.getOrThrow("JWT_REFRESH_SECRET"),
      });
    } catch {
      throw new UnauthorizedException();
    }
    const session = await this.prisma.session.findUnique({
      where: { refreshTokenHash: this.tokenHash(refreshToken) },
      include: { user: true },
    });
    if (!session || session.revokedAt || session.expiresAt <= new Date())
      throw new UnauthorizedException();
    await this.prisma.session.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });
    return this.createSession(session.user);
  }

  async logout(refreshToken?: string) {
    if (refreshToken)
      await this.prisma.session.updateMany({
        where: {
          refreshTokenHash: this.tokenHash(refreshToken),
          revokedAt: null,
        },
        data: { revokedAt: new Date() },
      });
    return { message: "Logged out" };
  }

  async logoutAll(userId: string) {
    await this.prisma.session.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    await this.audit(userId, "sessions.revoked_all");
    return { message: "All sessions have been logged out" };
  }

  private async issueChallenge(user: User, purpose: ChallengePurpose) {
    const code = randomInt(100000, 1000000).toString();
    const challenge = await this.prisma.$transaction(async (tx) => {
      await tx.verificationChallenge.updateMany({
        where: { userId: user.id, purpose, consumedAt: null },
        data: { consumedAt: new Date() },
      });
      const created = await tx.verificationChallenge.create({
        data: {
          userId: user.id,
          purpose,
          codeHash: this.codeHash(code),
          expiresAt: new Date(Date.now() + CODE_TTL_MINUTES * 60_000),
        },
      });
      const template =
        purpose === ChallengePurpose.SIGN_IN
          ? "SIGN_IN_CODE"
          : purpose === ChallengePurpose.PASSWORD_RESET
            ? "PASSWORD_RESET_CODE"
            : "EMAIL_VERIFICATION_CODE";
      await this.notifications.enqueue(tx, {
        idempotencyKey: `${template}:${created.id}`,
        recipient: user.email,
        template,
        payload: {
          code,
          firstName: user.firstName,
          expiresInMinutes: CODE_TTL_MINUTES,
        },
      });
      return created;
    });
    void this.notifications.processPending();
    return challenge;
  }

  private async consumeChallenge(
    challengeId: string,
    code: string,
    purpose: ChallengePurpose,
  ) {
    const challenge = await this.prisma.verificationChallenge.findUnique({
      where: { id: challengeId },
      include: { user: true },
    });
    if (
      !challenge ||
      challenge.purpose !== purpose ||
      challenge.consumedAt ||
      challenge.expiresAt <= new Date() ||
      challenge.attempts >= MAX_CODE_ATTEMPTS
    )
      throw new BadRequestException(
        "The verification code is invalid or expired",
      );
    if (this.codeHash(code) !== challenge.codeHash) {
      await this.prisma.verificationChallenge.update({
        where: { id: challenge.id },
        data: { attempts: { increment: 1 } },
      });
      throw new BadRequestException(
        "The verification code is invalid or expired",
      );
    }
    const consumed = await this.prisma.verificationChallenge.updateMany({
      where: { id: challenge.id, consumedAt: null },
      data: { consumedAt: new Date() },
    });
    if (consumed.count !== 1)
      throw new BadRequestException(
        "The verification code is invalid or expired",
      );
    return challenge.user;
  }

  private async createSession(user: User) {
    const nonce = randomBytes(32).toString("hex");
    const refreshToken = await this.jwt.signAsync(
      { sub: user.id, nonce, type: "refresh" },
      {
        secret: this.config.getOrThrow("JWT_REFRESH_SECRET"),
        expiresIn: "30d",
      },
    );
    await this.prisma.session.create({
      data: {
        userId: user.id,
        refreshTokenHash: this.tokenHash(refreshToken),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });
    const accessToken = await this.jwt.signAsync(
      { sub: user.id, email: user.email, role: user.role, type: "access" },
      {
        secret: this.config.getOrThrow("JWT_ACCESS_SECRET"),
        expiresIn: this.config.get("ACCESS_TOKEN_TTL", "15m"),
      },
    );
    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
      },
      accessToken,
      refreshToken,
    };
  }

  private codeHash(code: string) {
    return createHmac(
      "sha256",
      this.config.getOrThrow<string>("OTP_HASH_SECRET"),
    )
      .update(code)
      .digest("hex");
  }
  private tokenHash(token: string) {
    return createHash("sha256").update(token).digest("hex");
  }
  private maskEmail(email: string) {
    const [local, domain] = email.split("@");
    return `${local.slice(0, 1)}***@${domain}`;
  }
  private async audit(
    userId: string,
    action: string,
    metadata?: Prisma.InputJsonValue,
  ) {
    await this.prisma.auditEvent.create({ data: { userId, action, metadata } });
  }
}
