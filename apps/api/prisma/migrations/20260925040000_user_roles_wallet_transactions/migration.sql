CREATE TYPE "UserRole" AS ENUM ('USER', 'ADMIN');
CREATE TYPE "WalletTransactionType" AS ENUM ('SIMULATED_TOP_UP');

ALTER TABLE "User" ADD COLUMN "role" "UserRole" NOT NULL DEFAULT 'USER';

CREATE TABLE "WalletTransaction" (
    "id" TEXT NOT NULL,
    "recipientId" TEXT NOT NULL,
    "actorUserId" TEXT NOT NULL,
    "type" "WalletTransactionType" NOT NULL,
    "amount" DECIMAL(18,2) NOT NULL,
    "balanceAfter" DECIMAL(18,2) NOT NULL,
    "idempotencyKey" TEXT NOT NULL,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "WalletTransaction_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "WalletTransaction_idempotencyKey_key" ON "WalletTransaction"("idempotencyKey");
CREATE INDEX "WalletTransaction_recipientId_createdAt_idx" ON "WalletTransaction"("recipientId", "createdAt");
CREATE INDEX "WalletTransaction_actorUserId_createdAt_idx" ON "WalletTransaction"("actorUserId", "createdAt");

ALTER TABLE "WalletTransaction" ADD CONSTRAINT "WalletTransaction_recipientId_fkey"
FOREIGN KEY ("recipientId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "WalletTransaction" ADD CONSTRAINT "WalletTransaction_actorUserId_fkey"
FOREIGN KEY ("actorUserId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
