import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEmail,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Max,
  MaxLength,
  Min,
} from "class-validator";

export class SimulatedTopUpDto {
  @ApiProperty({ example: "customer@example.com" })
  @IsEmail()
  recipientEmail: string;

  @ApiProperty({ example: 25000, minimum: 100, maximum: 1000000 })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(100)
  @Max(1_000_000)
  amount: number;

  @ApiProperty({ description: "Stable unique key for safe retries" })
  @IsString()
  @Length(16, 100)
  idempotencyKey: string;

  @ApiPropertyOptional({ example: "Assessment demonstration credit" })
  @IsOptional()
  @IsString()
  @MaxLength(140)
  description?: string;
}
