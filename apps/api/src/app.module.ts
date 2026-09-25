import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { HealthController } from './health.controller';
import { NotificationModule } from './notifications/notification.module';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { DashboardModule } from './dashboard/dashboard.module';
import { EnvModule } from './config/env.module';

@Module({
  imports: [EnvModule, ThrottlerModule.forRoot([{ ttl: 60_000, limit: 100 }]), DatabaseModule, NotificationModule, AuthModule, DashboardModule],
  controllers: [HealthController],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
