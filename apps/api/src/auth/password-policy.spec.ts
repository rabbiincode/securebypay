import {
  assertPasswordExcludesPersonalData,
  passwordContainsPersonalData,
} from "./password-policy";

describe("password policy", () => {
  const identity = {
    firstName: "Ada",
    lastName: "Lovelace",
    phoneNumber: "+2348012345678",
  };

  it("detects names and phone numbers case-insensitively", () => {
    expect(passwordContainsPersonalData("LoveLace123!", identity)).toBe(true);
    expect(passwordContainsPersonalData("Safe8012345678!", identity)).toBe(
      true,
    );
    expect(passwordContainsPersonalData("Unrelated123!", identity)).toBe(false);
  });

  it("rejects passwords containing personal data", () => {
    expect(() =>
      assertPasswordExcludesPersonalData("AdaSecure123!", identity),
    ).toThrow("Password must not contain");
  });
});
