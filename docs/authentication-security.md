# Authentication security

SecureByPay applies validation at two layers: Flutter provides immediate form feedback, while NestJS independently validates every authentication request before business logic runs.

## Identity fields

| Field | Requirement |
| --- | --- |
| First name | Required and between 2 and 20 characters |
| Last name | Required and between 2 and 20 characters |
| Email | Must be a syntactically valid email address |
| Phone | The local number field accepts digits only. Flutter combines it with the selected country calling code, and the API accepts an E.164 value containing `+` followed by 7 to 15 digits |

## Password policy

Passwords must contain 12 to 128 characters, including at least one uppercase letter, one lowercase letter, one number, and one symbol. A password cannot contain the user's first name, last name, full phone number, or final seven phone digits.

The composition policy applies to registration, sign in, and password reset. Personal data checks use the submitted registration data or the persisted user record. Login failures return a generic response so validation does not reveal account details.

## Related controls

1. Email verification is required after registration.
2. Verifying a new email address does not create a session. The user must complete the normal password and login code flow.
3. Every password authenticated login requires a single use email code.
4. Verification codes expire after five minutes and allow only a limited number of attempts.
5. Password reset revokes active sessions.
6. Refresh tokens are rotated and stored only as hashes.
7. Authentication routes are rate limited.
8. Notification records use unique idempotency keys and retry transient delivery failures.
