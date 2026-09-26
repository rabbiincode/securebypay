import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from "@nestjs/common";
import { NotificationStatus, Prisma } from "@prisma/client";
import { PrismaService } from "../database/prisma.service";
import { EmailProvider } from "./email.provider";

type TemplatePayload = {
  code: string;
  firstName: string;
  expiresInMinutes: number;
};

@Injectable()
export class NotificationService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(NotificationService.name);
  private timer?: NodeJS.Timeout;
  private processing = false;
  constructor(
    private readonly prisma: PrismaService,
    private readonly email: EmailProvider,
  ) {}

  onModuleInit() {
    this.timer = setInterval(() => void this.processPending(), 5_000);
    this.timer.unref();
    void this.processPending();
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  async enqueue(
    tx: Prisma.TransactionClient,
    input: {
      idempotencyKey: string;
      recipient: string;
      template: string;
      payload: TemplatePayload;
    },
  ) {
    await tx.notificationOutbox.upsert({
      where: { idempotencyKey: input.idempotencyKey },
      create: input,
      update: {},
    });
  }

  async processPending() {
    if (this.processing) return;
    this.processing = true;
    try {
      await this.prisma.notificationOutbox.updateMany({
        where: {
          status: NotificationStatus.PROCESSING,
          lockedAt: { lt: new Date(Date.now() - 5 * 60_000) },
        },
        data: {
          status: NotificationStatus.FAILED,
          lockedAt: null,
          nextAttemptAt: new Date(),
          lastError: "Worker lease expired before delivery completed",
        },
      });
      const candidates = await this.prisma.notificationOutbox.findMany({
        where: {
          status: {
            in: [NotificationStatus.PENDING, NotificationStatus.FAILED],
          },
          nextAttemptAt: { lte: new Date() },
          attempts: { lt: 5 },
        },
        orderBy: { createdAt: "asc" },
        take: 10,
      });
      for (const candidate of candidates) {
        const claimed = await this.prisma.notificationOutbox.updateMany({
          where: {
            id: candidate.id,
            status: candidate.status,
            attempts: candidate.attempts,
          },
          data: {
            status: NotificationStatus.PROCESSING,
            lockedAt: new Date(),
            attempts: { increment: 1 },
          },
        });
        if (claimed.count !== 1) continue;
        await this.deliver(candidate.id);
      }
    } finally {
      this.processing = false;
    }
  }

  private async deliver(id: string) {
    const notification = await this.prisma.notificationOutbox.findUniqueOrThrow(
      { where: { id } },
    );
    try {
      const message = this.render(
        notification.template,
        notification.payload as TemplatePayload,
      );
      const providerId = await this.email.send({
        to: notification.recipient,
        ...message,
      });
      await this.prisma.notificationOutbox.update({
        where: { id },
        data: {
          status: NotificationStatus.SENT,
          providerId,
          sentAt: new Date(),
          lockedAt: null,
          lastError: null,
        },
      });
    } catch (error) {
      const delayMinutes = Math.min(2 ** notification.attempts, 60);
      await this.prisma.notificationOutbox.update({
        where: { id },
        data: {
          status: NotificationStatus.FAILED,
          lockedAt: null,
          lastError:
            error instanceof Error
              ? error.message.slice(0, 500)
              : "Unknown provider error",
          nextAttemptAt: new Date(
            Date.now() +
              delayMinutes * 60_000 +
              Math.floor(Math.random() * 15_000),
          ),
        },
      });
      this.logger.warn(`Notification ${id} failed and was scheduled for retry`);
    }
  }

  private render(template: string, payload: TemplatePayload) {
    const purpose =
      template === "SIGN_IN_CODE"
        ? "sign in"
        : template === "PASSWORD_RESET_CODE"
          ? "reset your password"
          : "verify your email";
    const subject = `Your SecureByPay verification code`;
    const text = `Hello ${payload.firstName}, use ${payload.code} to ${purpose}. It expires in ${payload.expiresInMinutes} minutes. If it is not in your inbox, please check your spam folder.`;
    const html = `<p>Hello ${this.escape(payload.firstName)},</p><p>Use this code to ${purpose}:</p><p style="font-size:28px;font-weight:700;letter-spacing:6px">${payload.code}</p><p>It expires in ${payload.expiresInMinutes} minutes. If you did not request this, you can ignore this email.</p><p><strong>If you cannot find this email in your inbox, please check your spam folder.</strong></p>`;
    return { subject, text, html };
  }

  private escape(value: string) {
    return value.replace(
      /[&<>"']/g,
      (character) =>
        ({
          "&": "&amp;",
          "<": "&lt;",
          ">": "&gt;",
          '"': "&quot;",
          "'": "&#039;",
        })[character]!,
    );
  }
}
