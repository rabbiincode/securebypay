# SecureByPay

A responsive Flutter Web shipping dashboard backed by a NestJS and PostgreSQL API.

## Repository layout

- `apps/web` — Flutter Web client
- `apps/api` — NestJS REST API
- `assets` — original design exports supplied for the assessment
- `render.yaml` — Render API and PostgreSQL blueprint
- `vercel.json` — Vercel frontend build and SPA routing

## Local development

Requirements: Flutter stable, Node.js 20+, npm, and Docker.

```bash
cp .env.example apps/api/.env
docker compose up -d
cd apps/api && npm install && npx prisma migrate dev
npm run start:dev
```

In another terminal:

```bash
cd apps/web
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000/api
```

API documentation is available at `http://localhost:4000/api/docs`.

## Authentication lifecycle

1. Registration creates an unverified account and emails a five-minute code.
2. Email verification consumes that single-use code and creates a session.
3. Later sign-ins validate the password, email a new code, and create no session until the code is verified.
4. Access tokens are short lived. Refresh tokens are rotated, stored only as hashes in PostgreSQL, and delivered in `HttpOnly` cookies.
5. Logout revokes the current session; logout-all revokes every active session for the account.
6. Password reset uses a single-use email code and revokes existing sessions after the password changes.

Emails are first committed to `NotificationOutbox` in the same database transaction as their verification challenge. The worker claims each record atomically, retries transient failures with exponential backoff and jitter, and relies on a unique idempotency key to prevent duplicate scheduling. Stale worker leases are recovered automatically.

Set `EMAIL_DELIVERY_ENABLED=true`, `SENDGRID_API_KEY`, and `SENDGRID_FROM_EMAIL` to enable real delivery. No provider secret belongs in source control.

## Useful API routes

- `POST /api/auth/register`
- `POST /api/auth/verify-email`
- `POST /api/auth/login`
- `POST /api/auth/verify-login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `POST /api/auth/logout-all`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`
- `GET /api/dashboard` (Bearer token required)

## Verification

```bash
cd apps/api
npm test
npm run build
npm audit --omit=dev
```
