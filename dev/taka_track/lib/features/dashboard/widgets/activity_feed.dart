import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/taka_activity.dart';
import 'activity_row.dart';

class ActivityFeed extends StatelessWidget {
  final List<TakaActivity> activities;

  const ActivityFeed({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: AppColors.muted),
              SizedBox(height: 12),
              Text(
                'No recent activity',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Use the scanner to log inventory movement',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: const [
                  Text(
                    'RECENT ACTIVITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            );
          }
          final activity = activities[index - 1];
          return Column(
            children: [
              _AnimatedActivityRow(activity: activity, index: index),
              if (index < activities.length)
                const Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 16,
                ),
            ],
          );
        },
        childCount: activities.length + 1,
      ),
    );
  }
}

class _AnimatedActivityRow extends StatefulWidget {
  final TakaActivity activity;
  final int index;

  const _AnimatedActivityRow({required this.activity, required this.index});

  @override
  State<_AnimatedActivityRow> createState() => _AnimatedActivityRowState();
}

class _AnimatedActivityRowState extends State<_AnimatedActivityRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 30).clamp(0, 300)),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ActivityRow(activity: widget.activity),
      ),
    );
  }
}
