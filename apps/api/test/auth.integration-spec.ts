import { INestApplication, ValidationPipe } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import cookieParser = require("cookie-parser");
import request = require("supertest");
import { AppModule } from "../src/app.module";
import { PrismaService } from "../src/database/prisma.service";

describe("Authentication integration", () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix("api");
    app.use(cookieParser());
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await prisma.$transaction([
      prisma.shipment.deleteMany(),
      prisma.walletTransaction.deleteMany(),
      prisma.auditEvent.deleteMany(),
      prisma.notificationOutbox.deleteMany(),
      prisma.verificationChallenge.deleteMany(),
      prisma.session.deleteMany(),
      prisma.user.deleteMany(),
    ]);
  });

  afterAll(async () => {
    await app.close();
  });

  async function codeFor(template: string, challengeId: string) {
    const notification = await prisma.notificationOutbox.findUniqueOrThrow({
      where: { idempotencyKey: `${template}:${challengeId}` },
    });
    return (notification.payload as unknown as { code: string }).code;
  }

  it("enforces authentication input and password policies at the API boundary", async () => {
    await request(app.getHttpServer())
      .post("/api/auth/register")
      .send({
        firstName: "A".repeat(21),
        lastName: "Lovelace",
        email: "not-an-email",
        phoneNumber: "+23480abc",
        password: "weak-password",
      })
      .expect(400);

    await request(app.getHttpServer())
      .post("/api/auth/register")
      .send({
        firstName: "Ada",
        lastName: "Lovelace",
        email: "ada-policy@example.com",
        phoneNumber: "+2348012345678",
        password: "AdaSecure123!",
      })
      .expect(400);

    await request(app.getHttpServer())
      .post("/api/auth/login")
      .send({ email: "invalid", password: "password" })
      .expect(400);
  });

  it("completes registration, email verification, protected access, refresh rotation, and logout", async () => {
    const registration = await request(app.getHttpServer())
      .post("/api/auth/register")
      .send({
        firstName: "Ada",
        lastName: "Lovelace",
        email: "ada@example.com",
        phoneNumber: "+2348012345678",
        password: "StrongPassword123!",
      })
      .expect(201);

    expect(registration.body).toMatchObject({
      requiresVerification: true,
      destination: "a***@example.com",
    });
    const verificationCode = await codeFor(
      "EMAIL_VERIFICATION_CODE",
      registration.body.challengeId,
    );

    const verified = await request(app.getHttpServer())
      .post("/api/auth/verify-email")
      .send({
        challengeId: registration.body.challengeId,
        code: verificationCode,
      })
      .expect(200);

    expect(verified.body.accessToken).toEqual(expect.any(String));
    expect(verified.body.user).toMatchObject({ email: "ada@example.com" });
    const firstCookie = verified.headers["set-cookie"][0] as string;

    await request(app.getHttpServer())
      .get("/api/dashboard")
      .set("Authorization", `Bearer ${verified.body.accessToken}`)
      .expect(200)
      .expect(({ body }) =>
        expect(body.metrics).toEqual({
          totalShipments: 12,
          totalExports: 4,
          totalImports: 8,
        }),
      );

    const refreshed = await request(app.getHttpServer())
      .post("/api/auth/refresh")
      .set("Cookie", firstCookie)
      .expect(200);
    const rotatedCookie = refreshed.headers["set-cookie"][0] as string;
    expect(refreshed.body.accessToken).toEqual(expect.any(String));
    await request(app.getHttpServer())
      .post("/api/auth/refresh")
      .set("Cookie", firstCookie)
      .expect(401);

    await request(app.getHttpServer())
      .post("/api/auth/logout")
      .set("Cookie", rotatedCookie)
      .expect(200);
    await request(app.getHttpServer())
      .post("/api/auth/refresh")
      .set("Cookie", rotatedCookie)
      .expect(401);
  });

  it("requires an emailed code after password validation and permits password reset", async () => {
    const password = "StrongPassword123!";
    const registration = await request(app.getHttpServer())
      .post("/api/auth/register")
      .send({
        firstName: "Grace",
        lastName: "Hopper",
        email: "grace@example.com",
        password,
      })
      .expect(201);
    const emailCode = await codeFor(
      "EMAIL_VERIFICATION_CODE",
      registration.body.challengeId,
    );
    await request(app.getHttpServer())
      .post("/api/auth/verify-email")
      .send({ challengeId: registration.body.challengeId, code: emailCode })
      .expect(200);

    const login = await request(app.getHttpServer())
      .post("/api/auth/login")
      .send({ email: "grace@example.com", password })
      .expect(200);
    expect(login.body).not.toHaveProperty("accessToken");
    const loginCode = await codeFor("SIGN_IN_CODE", login.body.challengeId);
    await request(app.getHttpServer())
      .post("/api/auth/verify-login")
      .send({ challengeId: login.body.challengeId, code: "000000" })
      .expect(400);
    const completedLogin = await request(app.getHttpServer())
      .post("/api/auth/verify-login")
      .send({ challengeId: login.body.challengeId, code: loginCode })
      .expect(200);
    expect(completedLogin.body.accessToken).toEqual(expect.any(String));

    const resetRequest = await request(app.getHttpServer())
      .post("/api/auth/forgot-password")
      .send({ email: "grace@example.com" })
      .expect(200);
    const resetCode = await codeFor(
      "PASSWORD_RESET_CODE",
      resetRequest.body.challengeId,
    );
    await request(app.getHttpServer())
      .post("/api/auth/reset-password")
      .send({
        challengeId: resetRequest.body.challengeId,
        code: resetCode,
        newPassword: "NewStrongPassword456!",
      })
      .expect(200);

    await request(app.getHttpServer())
      .post("/api/auth/login")
      .send({ email: "grace@example.com", password })
      .expect(401);
    await request(app.getHttpServer())
      .post("/api/auth/login")
      .send({ email: "grace@example.com", password: "NewStrongPassword456!" })
      .expect(200);
  });
});
