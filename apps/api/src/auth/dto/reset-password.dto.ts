import { ApiProperty } from "@nestjs/swagger";
import {
  IsString,
  Length,
  Matches,
  MaxLength,
  MinLength,
} from "class-validator";
import { PASSWORD_PATTERN } from "../password-policy";

export class ResetPasswordDto {
  @ApiProperty() @IsString() challengeId: string;
  @ApiProperty() @IsString() @Length(6, 6) code: string;
  @ApiProperty({
    minLength: 12,
    maxLength: 128,
    description:
      "Must include uppercase, lowercase, number, and symbol; must not contain the user name or phone number.",
  })
  @IsString()
  @MinLength(12)
  @MaxLength(128)
  @Matches(PASSWORD_PATTERN)
  newPassword: string;
}
