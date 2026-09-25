import { Injectable, Logger } from '@nestjs/common';
import { EnvService } from '../config/env.service';

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
    if (this.config.get<string>('EMAIL_DELIVERY_ENABLED', 'false') !== 'true') {
      this.logger.log(`Email delivery disabled; accepted message for ${this.mask(message.to)}`);
      return `local-${Date.now()}`;
    }

    const apiKey = this.config.getOrThrow<string>('SENDGRID_API_KEY');
    const fromEmail = this.config.getOrThrow<string>('SENDGRID_FROM_EMAIL');
    const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: message.to }] }],
        from: { email: fromEmail, name: this.config.get('SENDGRID_FROM_NAME', 'SecureByPay') },
        subject: message.subject,
        content: [{ type: 'text/plain', value: message.text }, { type: 'text/html', value: message.html }],
      }),
    });
    if (!response.ok) throw new Error(`SendGrid rejected the message with status ${response.status}`);
    return response.headers.get('x-message-id') ?? `sendgrid-${Date.now()}`;
  }

  private mask(email: string) {
    const [local, domain] = email.split('@');
    return `${local.slice(0, 1)}***@${domain}`;
  }
}
