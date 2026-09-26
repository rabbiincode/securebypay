import { PrismaClient, ShipmentStatus } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  const user = await prisma.user.findFirst({ orderBy: { createdAt: "desc" } });
  if (!user)
    throw new Error("Register a user before running the dashboard seed.");

  const existing = await prisma.shipment.count({ where: { userId: user.id } });
  if (existing === 0) {
    await prisma.user.update({
      where: { id: user.id },
      data: { walletBalance: 3000000.28 },
    });
  }
  const statuses = [
    ShipmentStatus.IN_TRANSIT,
    ShipmentStatus.DELAYED,
    ShipmentStatus.DELIVERED,
    ShipmentStatus.PAID,
  ];
  const pickupLocations = [
    "Lagos, Nigeria",
    "Abuja, Nigeria",
    "Port Harcourt, Nigeria",
    "Kano, Nigeria",
  ];
  const destinations = [
    "Oyo, Nigeria",
    "Kaduna, Nigeria",
    "Enugu, Nigeria",
    "Ibadan, Nigeria",
  ];

  if (existing > 0) {
    const shipments = await prisma.shipment.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: "asc" },
      select: { id: true },
    });
    await prisma.$transaction(
      shipments.map((shipment, index) =>
        prisma.shipment.update({
          where: { id: shipment.id },
          data: {
            pickupLocation: pickupLocations[index % pickupLocations.length],
            deliveryLocation: destinations[index % destinations.length],
            isExport: false,
          },
        }),
      ),
    );
    console.log(
      `Restricted existing dashboard data to Nigeria for ${user.email}.`,
    );
    return;
  }

  await prisma.shipment.createMany({
    data: Array.from({ length: 12 }, (_, index) => ({
      userId: user.id,
      trackingId: `MAF-100-234-${String(291 + index).padStart(3, "0")}`,
      sender: `${user.firstName} ${user.lastName}`,
      receiver: ["Mercy James", "Bunmi Tanny", "Amina Yusuf"][index % 3],
      pickupLocation: pickupLocations[index % pickupLocations.length],
      deliveryLocation: destinations[index % destinations.length],
      amount: 3000 + index * 750,
      status: statuses[index % statuses.length],
      isExport: false,
      processingHours: 8 + index,
      createdAt: new Date(Date.now() - index * 7 * 24 * 60 * 60 * 1000),
    })),
  });
  console.log(`Seeded dashboard data for ${user.email}.`);
}

main().finally(() => prisma.$disconnect());
