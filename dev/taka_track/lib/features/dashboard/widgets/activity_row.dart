import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../data/models/taka_activity.dart';

class ActivityRow extends StatelessWidget {
  final TakaActivity activity;

  const ActivityRow({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final isInward = activity.isInward;
    final accent = isInward ? AppColors.mint : AppColors.coral;
    final arrow = isInward
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final actionText = isInward
        ? '+${activity.delta.abs()} Takas Added'
        : '-${activity.delta.abs()} Takas Sold';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Direction indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.15),
            ),
            child: Icon(arrow, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          // Thumbnail or avatar
          _buildThumbnail(activity),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.designName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Timestamp
          Text(
            TimeUtils.timeAgo(activity.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(TakaActivity activity) {
    if (activity.thumbnailUrl != null && activity.thumbnailUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: activity.thumbnailUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => _letterAvatar(activity.designName),
          errorWidget: (context, url, error) =>
              _letterAvatar(activity.designName),
        ),
      );
    }
    return _letterAvatar(activity.designName);
  }

  Widget _letterAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hue = name.codeUnits.fold(0, (sum, c) => sum + c) % 360;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.3).toColor(),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
        ),
      ),
    );
  }
}
