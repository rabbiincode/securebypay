import { ApiProperty } from "@nestjs/swagger";
import {
  IsEmail,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from "class-validator";
import { PASSWORD_PATTERN } from "../password-policy";

export class RegisterDto {
  @ApiProperty({ minLength: 2, maxLength: 20 })
  @IsString()
  @MinLength(2)
  @MaxLength(20)
  firstName: string;
  @ApiProperty({ minLength: 2, maxLength: 20 })
  @IsString()
  @MinLength(2)
  @MaxLength(20)
  lastName: string;
  @ApiProperty() @IsEmail() email: string;
  @ApiProperty({ required: false, example: "+2348012345678" })
  @IsOptional()
  @IsString()
  @Matches(/^\+\d{7,15}$/)
  phoneNumber?: string;
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
  password: string;
}
