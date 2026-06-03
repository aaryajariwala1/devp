import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/taka_design.dart';

class DesignCard extends StatelessWidget {
  final TakaDesign design;
  final VoidCallback? onTap;
  final VoidCallback? onQuickAdd;
  final VoidCallback? onQuickRemove;

  const DesignCard({
    super.key,
    required this.design,
    this.onTap,
    this.onQuickAdd,
    this.onQuickRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: design.isLowStock
              ? Border.all(color: AppColors.amber.withOpacity(0.5), width: 1)
              : Border.all(color: AppColors.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: _buildThumbnail(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          design.designName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (design.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.amber.withOpacity(0.5)),
                          ),
                          child: const Text(
                            'LOW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.amber,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${design.currentTakaCount}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: design.isLowStock
                              ? AppColors.amber
                              : AppColors.mint,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Text(
                          'takas',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Quick action buttons
                      _QuickActionButton(
                        icon: Icons.remove,
                        color: AppColors.coral,
                        onTap: onQuickRemove,
                      ),
                      const SizedBox(width: 6),
                      _QuickActionButton(
                        icon: Icons.add,
                        color: AppColors.mint,
                        onTap: onQuickAdd,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (design.thumbnailUrl != null && design.thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: design.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _colorAvatar(),
        errorWidget: (context, url, error) => _colorAvatar(),
      );
    }
    return _colorAvatar();
  }

  Widget _colorAvatar() {
    final hue = design.designName.codeUnits.fold(0, (s, c) => s + c) % 360;
    final initial =
        design.designName.isNotEmpty ? design.designName[0].toUpperCase() : '?';
    return Container(
      color: HSLColor.fromAHSL(1, hue.toDouble(), 0.5, 0.25).toColor(),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
