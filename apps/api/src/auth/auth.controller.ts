import { Body, Controller, HttpCode, Post, Req, Res, UseGuards } from '@nestjs/common';
import { ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import type { Request, Response } from 'express';
import { AccessTokenGuard } from './access-token.guard';
import { AuthService } from './auth.service';
import { AuthUser, CurrentUser } from './auth-user.decorator';
import { EmailDto } from './dto/email.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { VerifyCodeDto } from './dto/verify-code.dto';

@ApiTags('authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @ApiCreatedResponse({ description: 'Account created; email verification required' })
  register(@Body() input: RegisterDto) { return this.auth.register(input); }

  @Post('verify-email')
  @HttpCode(200)
  @Throttle({ default: { limit: 8, ttl: 60_000 } })
  async verifyEmail(@Body() input: VerifyCodeDto, @Res({ passthrough: true }) response: Response) {
    return this.withSessionCookie(response, await this.auth.verifyEmail(input.challengeId, input.code));
  }

  @Post('resend-email-verification')
  @HttpCode(200)
  @Throttle({ default: { limit: 3, ttl: 60_000 } })
  resendEmailVerification(@Body() input: EmailDto) { return this.auth.resendEmailVerification(input.email); }

  @Post('login')
  @HttpCode(200)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @ApiOkResponse({ description: 'Password accepted; email verification code required' })
  login(@Body() input: LoginDto) { return this.auth.login(input); }

  @Post('verify-login')
  @HttpCode(200)
  @Throttle({ default: { limit: 8, ttl: 60_000 } })
  async verifyLogin(@Body() input: VerifyCodeDto, @Res({ passthrough: true }) response: Response) {
    return this.withSessionCookie(response, await this.auth.verifySignIn(input.challengeId, input.code));
  }

  @Post('forgot-password')
  @HttpCode(200)
  @Throttle({ default: { limit: 3, ttl: 60_000 } })
  forgotPassword(@Body() input: EmailDto) { return this.auth.requestPasswordReset(input.email); }

  @Post('reset-password')
  @HttpCode(200)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  resetPassword(@Body() input: ResetPasswordDto) { return this.auth.resetPassword(input.challengeId, input.code, input.newPassword); }

  @Post('refresh')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  async refresh(@Req() request: Request, @Res({ passthrough: true }) response: Response) {
    return this.withSessionCookie(response, await this.auth.refresh(request.cookies?.refresh_token));
  }

  @Post('logout')
  @HttpCode(200)
  async logout(@Req() request: Request, @Res({ passthrough: true }) response: Response) {
    const result = await this.auth.logout(request.cookies?.refresh_token);
    response.clearCookie('refresh_token', { path: '/api/auth' });
    return result;
  }

  @Post('logout-all')
  @HttpCode(200)
  @UseGuards(AccessTokenGuard)
  async logoutAll(@CurrentUser() user: AuthUser, @Res({ passthrough: true }) response: Response) {
    const result = await this.auth.logoutAll(user.sub);
    response.clearCookie('refresh_token', { path: '/api/auth' });
    return result;
  }

  private withSessionCookie(response: Response, result: { refreshToken: string; [key: string]: unknown }) {
    const production = process.env.NODE_ENV === 'production';
    response.cookie('refresh_token', result.refreshToken, { httpOnly: true, secure: production, sameSite: production ? 'none' : 'lax', path: '/api/auth', maxAge: 30 * 24 * 60 * 60 * 1000 });
    const { refreshToken: _, ...body } = result;
    return body;
  }
}
