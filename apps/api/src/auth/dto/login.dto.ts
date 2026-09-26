import { ApiProperty } from "@nestjs/swagger";
import {
  IsEmail,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from "class-validator";
import { PASSWORD_PATTERN } from "../password-policy";

export class LoginDto {
  @ApiProperty() @IsEmail() email: string;
  @ApiProperty({
    minLength: 12,
    maxLength: 128,
    description: "Must include uppercase, lowercase, number, and symbol.",
  })
  @IsString()
  @MinLength(12)
  @MaxLength(128)
  @Matches(PASSWORD_PATTERN)
  password: string;
}
