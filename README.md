# SecureByPay

A responsive Flutter Web shipping dashboard backed by a NestJS and PostgreSQL API.

## Repository layout

| Path | Purpose |
| --- | --- |
| `apps/web` | Flutter Web client |
| `apps/api` | NestJS REST API |
| `assets` | Original design exports supplied for the assessment |
| `render.yaml` | Render API and PostgreSQL blueprint |
| `vercel.json` | Vercel frontend build and SPA routing |

## Local development

Requirements: Flutter stable, Node.js 20+, npm, and Docker.

```bash
cp .env.example .env
docker compose up -d
cd apps/api
npm install
npm run db:migrate
npm run start:dev
```

In another terminal:

```bash
cd apps/web
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000/api
```

API documentation is available at `http://localhost:4000/api/docs`.

The API loads `.env` from the repository root during local startup. The committed `.env.example` documents every required setting, while `.env` remains ignored by Git.

## Dashboard data

After registering at least one local user, seed the newest account with a wallet balance and twelve realistic shipments:

```bash
cd apps/api
npm run db:seed
```

The dashboard reads the user's name, optional profile image URL, wallet balance, metrics, chart series, and shipment records from PostgreSQL. “See All” and “View More” open protected shipment list and detail routes. A newly verified account receives twelve duplicate-safe showcase shipments automatically so the hosted assessment demonstrates the complete dashboard immediately. Running the seed repeatedly is also safe because it does not duplicate an account's shipment fixtures.

For profile images, Cloudinary or Supabase Storage is simpler than maintaining AWS S3 directly. Store only the returned HTTPS asset URL in `User.profileImageUrl`; keep the image binary in the selected managed storage service.

## Authentication lifecycle

1. Registration creates an unverified account and emails a code that expires after five minutes.
2. Email verification consumes that single use code, activates the account, creates the first session, and continues to the dashboard.
3. Sign in validates the password, emails a new code, and creates no session until the login code is verified.
4. Access tokens are short lived. Refresh tokens are rotated, stored only as hashes in PostgreSQL, and delivered in `HttpOnly` cookies.
5. Logout revokes the current session. The logout all endpoint revokes every active session for the account.
6. Password reset uses a single use email code and revokes existing sessions after the password changes.

### Input and password policy

| Input | Policy |
| --- | --- |
| First and last name | Required and limited to 20 characters each |
| Email | Validated by both Flutter and NestJS |
| Phone number | Accepts digits in the local number field and is stored with the selected country code in E.164 format |
| Password | Must contain 12 to 128 characters, including an uppercase letter, lowercase letter, number, and symbol |
| Personal information | Passwords containing the user's name, full phone number, or final seven phone digits are rejected by the API |

The same email, verification code, and password rules apply to registration, sign in, and password reset. Flutter provides immediate feedback, but the API remains the source of truth, so client validation cannot be bypassed. See [Authentication security](docs/authentication-security.md) for implementation details.

Emails are first committed to `NotificationOutbox` in the same database transaction as their verification challenge. The worker claims each record atomically, retries transient failures with exponential backoff and jitter, and relies on a unique idempotency key to prevent duplicate scheduling. Stale worker leases are recovered automatically.

Set `EMAIL_DELIVERY_ENABLED=true`, `SENDGRID_API_KEY`, and `SENDGRID_FROM_EMAIL` to enable real delivery. No provider secret belongs in source control.

## Useful API routes

| Method | Route | Authentication |
| --- | --- | --- |
| `POST` | `/api/auth/register` | Public |
| `POST` | `/api/auth/verify-email` | Public |
| `POST` | `/api/auth/login` | Public |
| `POST` | `/api/auth/verify-login` | Public |
| `POST` | `/api/auth/refresh` | Refresh cookie |
| `POST` | `/api/auth/logout` | Refresh cookie |
| `POST` | `/api/auth/logout-all` | Bearer token |
| `POST` | `/api/auth/forgot-password` | Public |
| `POST` | `/api/auth/reset-password` | Public |
| `GET` | `/api/dashboard` | Bearer token |

## Verification

```bash
cd apps/api
npm test
npm run lint
npm run test:integration
npm run build
npm audit --omit=dev
```

The integration suite uses a disposable PostgreSQL service on port `55432`:

```bash
docker compose --profile test up -d postgres_test
cd apps/api
npm run test:integration
```

It applies the real migrations and exercises registration, email verification, two step login, protected dashboard access, refresh token rotation, logout, and password reset over HTTP.

Verify the Flutter application separately:

```bash
cd apps/web
flutter analyze
flutter test
flutter build web --release
```
