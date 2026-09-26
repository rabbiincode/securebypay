import { Body, Controller, Get, Post, Query, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { Throttle } from "@nestjs/throttler";
import { AccessTokenGuard } from "../auth/access-token.guard";
import { AuthUser, CurrentUser } from "../auth/auth-user.decorator";
import { AdminGuard } from "./admin.guard";
import { AdminService } from "./admin.service";
import { SimulatedTopUpDto } from "./dto/simulated-top-up.dto";

@ApiTags("Admin")
@ApiBearerAuth()
@UseGuards(AccessTokenGuard, AdminGuard)
@Controller("admin")
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get("users/lookup")
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @ApiOperation({ summary: "Look up a wallet recipient by email" })
  findUser(@Query("email") email: string) {
    return this.admin.findUserByEmail(email ?? "");
  }

  @Post("wallet/simulated-top-ups")
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @ApiOperation({ summary: "Credit a user's wallet in assessment demo mode" })
  simulateTopUp(
    @CurrentUser() actor: AuthUser,
    @Body() input: SimulatedTopUpDto,
  ) {
    return this.admin.simulateTopUp(actor.sub, input);
  }
}
