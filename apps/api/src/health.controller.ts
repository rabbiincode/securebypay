import { Controller, Get } from '@nestjs/common';
import { ApiExcludeEndpoint } from '@nestjs/swagger';

@Controller('health')
export class HealthController {
  @Get() @ApiExcludeEndpoint() health() { return { status: 'ok', timestamp: new Date().toISOString() }; }
}

