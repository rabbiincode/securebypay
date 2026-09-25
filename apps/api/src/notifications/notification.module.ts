import { Global, Module } from '@nestjs/common';
import { EmailProvider } from './email.provider';
import { NotificationService } from './notification.service';

@Global()
@Module({ providers: [EmailProvider, NotificationService], exports: [NotificationService] })
export class NotificationModule {}
