import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from "@nestjs/common";
import { UserRole } from "@prisma/client";
import { PrismaService } from "../database/prisma.service";
import { AuthUser } from "../auth/auth-user.decorator";

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<{ user: AuthUser }>();
    const user = await this.prisma.user.findUnique({
      where: { id: request.user.sub },
      select: { role: true },
    });
    if (user?.role !== UserRole.ADMIN) {
      throw new ForbiddenException("Administrator access is required");
    }
    return true;
  }
}
