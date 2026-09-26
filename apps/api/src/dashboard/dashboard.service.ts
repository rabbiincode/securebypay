import { Injectable } from "@nestjs/common";
import { PrismaService } from "../database/prisma.service";

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async getDashboard(userId: string) {
    const [user, shipments] = await Promise.all([
      this.prisma.user.findUniqueOrThrow({
        where: { id: userId },
        select: {
          firstName: true,
          lastName: true,
          email: true,
          profileImageUrl: true,
          role: true,
          walletBalance: true,
        },
      }),
      this.prisma.shipment.findMany({
        where: {
          userId,
          pickupLocation: { endsWith: ", Nigeria", mode: "insensitive" },
          deliveryLocation: { endsWith: ", Nigeria", mode: "insensitive" },
        },
        orderBy: { createdAt: "desc" },
        take: 20,
      }),
    ]);
    const monthlyGrowth = Array<number>(12).fill(0);
    for (const shipment of shipments)
      monthlyGrowth[shipment.createdAt.getMonth()] += 1;
    return {
      user: {
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        profileImageUrl: user.profileImageUrl,
        role: user.role,
      },
      balance: user.walletBalance.toFixed(2),
      metrics: {
        totalShipments: shipments.length,
        totalExports: shipments.filter((item) => item.isExport).length,
        totalImports: shipments.filter((item) => !item.isExport).length,
      },
      monthlyGrowth,
      recentShipments: shipments.map((item) => ({
        ...item,
        amount: item.amount.toFixed(2),
      })),
    };
  }
}
