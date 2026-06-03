import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/remote/inventory_repository.dart';
import 'metric_card.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const StatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        MetricCard(
          label: 'TOTAL TAKAS',
          value: '${stats.totalTakas}',
          icon: Icons.layers_rounded,
          accentColor: AppColors.white,
        ),
        MetricCard(
          label: 'INWARD TODAY',
          value: '+${stats.inwardToday}',
          icon: Icons.arrow_circle_down_rounded,
          accentColor: AppColors.mint,
        ),
        MetricCard(
          label: 'OUTWARD TODAY',
          value: '-${stats.outwardToday}',
          icon: Icons.arrow_circle_up_rounded,
          accentColor: AppColors.coral,
        ),
        MetricCard(
          label: 'LOW STOCK',
          value: '${stats.lowStockCount}',
          icon: Icons.warning_amber_rounded,
          accentColor: AppColors.amber,
          showBadge: stats.lowStockCount > 0,
          badgeCount: stats.lowStockCount,
        ),
      ],
    );
  }
}
