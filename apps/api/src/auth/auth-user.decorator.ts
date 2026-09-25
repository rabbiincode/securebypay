import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface AuthUser { sub: string; email: string }

export const CurrentUser = createParamDecorator((_: unknown, context: ExecutionContext): AuthUser => context.switchToHttp().getRequest<{ user: AuthUser }>().user);
