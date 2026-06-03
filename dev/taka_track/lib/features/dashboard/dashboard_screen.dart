import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/stats_grid.dart';
import '../widgets/activity_feed.dart';
import '../widgets/skeleton_loader.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return RefreshIndicator(
          color: AppColors.mint,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            context.read<DashboardBloc>().add(const RefreshDashboard());
            // Wait briefly for the event to process
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    if (state is DashboardLoading) {
      return const SkeletonLoader();
    }

    if (state is DashboardError) {
      return CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 64, color: AppColors.muted),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<DashboardBloc>()
                            .add(const LoadDashboard());
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (state is DashboardLoaded) {
      return CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: StatsGrid(stats: state.stats),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ActivityFeed(activities: state.recentActivities),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    }

    // DashboardInitial
    return const SkeletonLoader();
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: AppColors.background,
      expandedHeight: 70,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.mint, Color(0xFF00C9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.layers_rounded,
                  size: 16, color: AppColors.background),
            ),
            const SizedBox(width: 10),
            const Text(
              'TakaTrack',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: AppColors.muted),
          onPressed: () {
            // Settings navigation placeholder
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings coming soon')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
