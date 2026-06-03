import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/theme/app_colors.dart';

class CameraPreviewWidget extends StatefulWidget {
  final CameraController? controller;

  const CameraPreviewWidget({super.key, required this.controller});

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (controller == null) {
      return _buildPlaceholder(
        icon: Icons.camera_alt_rounded,
        message: 'Camera not initialized',
      );
    }

    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.mint),
      );
    }

    if (controller.value.hasError) {
      return _buildPlaceholder(
        icon: Icons.error_outline_rounded,
        message: controller.value.errorDescription ?? 'Camera error',
        isError: true,
      );
    }

    return AspectRatio(
      aspectRatio: 1 / controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String message,
    bool isError = false,
  }) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: isError ? AppColors.coral : AppColors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? AppColors.coral : AppColors.muted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
