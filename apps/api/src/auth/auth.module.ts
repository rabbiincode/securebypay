import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { AccessTokenGuard } from './access-token.guard';

@Module({ imports: [JwtModule.register({})], controllers: [AuthController], providers: [AuthService, AccessTokenGuard], exports: [JwtModule, AccessTokenGuard] })
export class AuthModule {}
