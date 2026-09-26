import { createParamDecorator, ExecutionContext } from "@nestjs/common";
import { UserRole } from "@prisma/client";

export interface AuthUser {
  sub: string;
  email: string;
  role: UserRole;
}

export const CurrentUser = createParamDecorator(
  (_: unknown, context: ExecutionContext): AuthUser =>
    context.switchToHttp().getRequest<{ user: AuthUser }>().user,
);
