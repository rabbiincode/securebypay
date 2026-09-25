CREATE TYPE "ShipmentStatus" AS ENUM ('IN_TRANSIT', 'DELAYED', 'DELIVERED', 'PAID');
ALTER TABLE "User" ADD COLUMN "walletBalance" DECIMAL(18,2) NOT NULL DEFAULT 0;
CREATE TABLE "Shipment" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "trackingId" TEXT NOT NULL,
  "sender" TEXT NOT NULL,
  "receiver" TEXT NOT NULL,
  "pickupLocation" TEXT NOT NULL,
  "deliveryLocation" TEXT NOT NULL,
  "amount" DECIMAL(18,2) NOT NULL,
  "status" "ShipmentStatus" NOT NULL,
  "isExport" BOOLEAN NOT NULL DEFAULT false,
  "processingHours" INTEGER NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Shipment_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Shipment_trackingId_key" ON "Shipment"("trackingId");
CREATE INDEX "Shipment_userId_createdAt_idx" ON "Shipment"("userId", "createdAt");
ALTER TABLE "Shipment" ADD CONSTRAINT "Shipment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
