import { BadRequestException } from "@nestjs/common";

export const PASSWORD_PATTERN =
  /^(?=.{12,128}$)(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9\s]).*$/;

type PasswordIdentity = {
  firstName?: string | null;
  lastName?: string | null;
  phoneNumber?: string | null;
};

export function passwordContainsPersonalData(
  password: string,
  identity: PasswordIdentity,
): boolean {
  const normalizedPassword = password.toLowerCase();
  const names = [identity.firstName, identity.lastName]
    .map((name) => name?.trim().toLowerCase() ?? "")
    .filter(Boolean);
  if (names.some((name) => normalizedPassword.includes(name))) return true;

  const phoneDigits = (identity.phoneNumber ?? "").replace(/\D/g, "");
  if (!phoneDigits) return false;
  return (
    password.includes(phoneDigits) ||
    (phoneDigits.length >= 7 && password.includes(phoneDigits.slice(-7)))
  );
}

export function assertPasswordExcludesPersonalData(
  password: string,
  identity: PasswordIdentity,
): void {
  if (passwordContainsPersonalData(password, identity)) {
    throw new BadRequestException(
      "Password must not contain your first name, last name, or phone number",
    );
  }
}
