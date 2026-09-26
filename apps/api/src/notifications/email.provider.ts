import { Injectable, Logger } from "@nestjs/common";
import { request } from "node:https";
import { EnvService } from "../config/env.service";

export interface EmailMessage {
  to: string;
  subject: string;
  text: string;
  html: string;
}

@Injectable()
export class EmailProvider {
  private readonly logger = new Logger(EmailProvider.name);
  constructor(private readonly config: EnvService) {}

  async send(message: EmailMessage): Promise<string> {
    if (this.config.get<string>("EMAIL_DELIVERY_ENABLED", "false") !== "true") {
      this.logger.log(
        `Email delivery disabled; accepted message for ${this.mask(message.to)}`,
      );
      return `local-${Date.now()}`;
    }

    const apiKey = this.config.getOrThrow<string>("SENDGRID_API_KEY");
    const fromEmail = this.config.getOrThrow<string>("SENDGRID_FROM_EMAIL");
    const payload = JSON.stringify({
      personalizations: [{ to: [{ email: message.to }] }],
      from: {
        email: fromEmail,
        name: this.config.get("SENDGRID_FROM_NAME", "SecureByPay"),
      },
      subject: message.subject,
      content: [
        { type: "text/plain", value: message.text },
        { type: "text/html", value: message.html },
      ],
    });

    const response = await this.postToSendGrid(apiKey, payload);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw new Error(
        `SendGrid rejected the message with status ${response.statusCode}`,
      );
    }
    return response.messageId ?? `sendgrid-${Date.now()}`;
  }

  private postToSendGrid(
    apiKey: string,
    payload: string,
  ): Promise<{ statusCode: number; messageId?: string }> {
    return new Promise((resolve, reject) => {
      const outgoing = request(
        "https://api.sendgrid.com/v3/mail/send",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
            "Content-Length": Buffer.byteLength(payload),
          },
          timeout: 15_000,
        },
        (response) => {
          response.resume();
          response.on("end", () =>
            resolve({
              statusCode: response.statusCode ?? 500,
              messageId: Array.isArray(response.headers["x-message-id"])
                ? response.headers["x-message-id"][0]
                : response.headers["x-message-id"],
            }),
          );
        },
      );
      outgoing.on("timeout", () =>
        outgoing.destroy(new Error("SendGrid request timed out")),
      );
      outgoing.on("error", reject);
      outgoing.end(payload);
    });
  }

  private mask(email: string) {
    const [local, domain] = email.split("@");
    return `${local.slice(0, 1)}***@${domain}`;
  }
}
