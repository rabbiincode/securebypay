process.env.NODE_ENV = "test";
process.env.JWT_ACCESS_SECRET ??=
  "integration-access-secret-at-least-32-characters";
process.env.JWT_REFRESH_SECRET ??=
  "integration-refresh-secret-at-least-32-characters";
process.env.OTP_HASH_SECRET ??= "integration-otp-secret-at-least-32-characters";
process.env.ACCESS_TOKEN_TTL ??= "15m";
process.env.WEB_URL ??= "http://localhost:3000";
process.env.EMAIL_DELIVERY_ENABLED = "false";
process.env.PAYMENT_SIMULATION_ENABLED = "true";
