import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { Prisma, WalletTransactionType } from "@prisma/client";
import { EnvService } from "../config/env.service";
import { PrismaService } from "../database/prisma.service";
import { SimulatedTopUpDto } from "./dto/simulated-top-up.dto";

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: EnvService,
  ) {}

  async findUserByEmail(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
      select: { id: true, email: true, firstName: true, lastName: true },
    });
    if (!user) throw new NotFoundException("Recipient was not found");
    return user;
  }

  async simulateTopUp(actorUserId: string, input: SimulatedTopUpDto) {
    const defaultSetting =
      process.env.NODE_ENV === "production" ? "false" : "true";
    if (
      this.config.get("PAYMENT_SIMULATION_ENABLED", defaultSetting) !== "true"
    ) {
      throw new ForbiddenException("Payment simulation is disabled");
    }

    const recipient = await this.prisma.user.findUnique({
      where: { email: input.recipientEmail.trim().toLowerCase() },
      select: { id: true },
    });
    if (!recipient) throw new NotFoundException("Recipient was not found");

    const amount = new Prisma.Decimal(input.amount);
    if (!amount.isPositive()) throw new BadRequestException("Invalid amount");

    const previous = await this.prisma.walletTransaction.findUnique({
      where: { idempotencyKey: input.idempotencyKey },
    });
    if (previous) {
      this.assertMatchingReplay(previous, actorUserId, recipient.id, amount);
      return this.result(previous, true);
    }

    try {
      const transaction = await this.prisma.$transaction(async (database) => {
        const updated = await database.user.update({
          where: { id: recipient.id },
          data: { walletBalance: { increment: amount } },
          select: { walletBalance: true },
        });
        const created = await database.walletTransaction.create({
          data: {
            recipientId: recipient.id,
            actorUserId,
            type: WalletTransactionType.SIMULATED_TOP_UP,
            amount,
            balanceAfter: updated.walletBalance,
            idempotencyKey: input.idempotencyKey,
            description: input.description,
          },
        });
        await database.auditEvent.create({
          data: {
            userId: actorUserId,
            action: "ADMIN_SIMULATED_WALLET_TOP_UP",
            metadata: {
              transactionId: created.id,
              recipientId: recipient.id,
              amount: amount.toFixed(2),
            },
          },
        });
        return created;
      });
      return this.result(transaction, false);
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === "P2002"
      ) {
        const existing = await this.prisma.walletTransaction.findUniqueOrThrow({
          where: { idempotencyKey: input.idempotencyKey },
        });
        this.assertMatchingReplay(existing, actorUserId, recipient.id, amount);
        return this.result(existing, true);
      }
      throw error;
    }
  }

  private assertMatchingReplay(
    transaction: {
      actorUserId: string;
      recipientId: string;
      amount: Prisma.Decimal;
    },
    actorUserId: string,
    recipientId: string,
    amount: Prisma.Decimal,
  ) {
    if (
      transaction.actorUserId !== actorUserId ||
      transaction.recipientId !== recipientId ||
      !transaction.amount.equals(amount)
    ) {
      throw new ConflictException(
        "The idempotency key was already used for a different request",
      );
    }
  }

  private result(
    transaction: {
      id: string;
      type: WalletTransactionType;
      amount: Prisma.Decimal;
      balanceAfter: Prisma.Decimal;
      idempotencyKey: string;
      createdAt: Date;
    },
    replayed: boolean,
  ) {
    return {
      id: transaction.id,
      type: transaction.type,
      amount: transaction.amount.toFixed(2),
      balanceAfter: transaction.balanceAfter.toFixed(2),
      idempotencyKey: transaction.idempotencyKey,
      createdAt: transaction.createdAt,
      replayed,
    };
  }
}
