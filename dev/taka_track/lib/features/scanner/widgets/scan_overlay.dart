import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ScanOverlay extends StatefulWidget {
  final VoidCallback? onCapture;
  final bool isProcessing;

  const ScanOverlay({
    super.key,
    this.onCapture,
    this.isProcessing = false,
  });

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  late Animation<double> _pulseAnim;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _scanLineAnim =
        Tween<double>(begin: 0.0, end: 1.0).animate(_scanLineController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = size.width * 0.72;

    return Stack(
      children: [
        // Darkened overlay with cutout
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _OverlayPainter(scanSize: scanSize),
        ),
        // Corner brackets
        Center(
          child: SizedBox(
            width: scanSize,
            height: scanSize,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => CustomPaint(
                painter: _BracketPainter(opacity: _pulseAnim.value),
              ),
            ),
          ),
        ),
        // Scan line
        if (!widget.isProcessing)
          AnimatedBuilder(
            animation: _scanLineAnim,
            builder: (context, _) {
              return Align(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    (scanSize / 2) *
                        (2 * _scanLineAnim.value - 1) *
                        0.9,
                  ),
                  child: Container(
                    width: scanSize * 0.9,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.mint.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        // Processing indicator
        if (widget.isProcessing)
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.mint,
              strokeWidth: 3,
            ),
          ),
        // Top instruction
        Positioned(
          top: size.height * 0.5 - scanSize / 2 - 52,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                'FABRIC SCANNER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isProcessing
                    ? 'Analyzing fabric pattern...'
                    : 'Point camera at fabric',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        // Capture button
        if (!widget.isProcessing)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Tap to scan',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: widget.onCapture,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background.withOpacity(0.3),
                        border: Border.all(
                          color: AppColors.mint.withOpacity(_pulseAnim.value),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mint
                                .withOpacity(_pulseAnim.value * 0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_rounded,
                        color: AppColors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double scanSize;

  const _OverlayPainter({required this.scanSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
        center: center, width: scanSize, height: scanSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BracketPainter extends CustomPainter {
  final double opacity;

  const _BracketPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    const bracketLength = 24.0;
    const strokeWidth = 3.0;
    const radius = 16.0;

    final paint = Paint()
      ..color = AppColors.mint.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final corners = [
      // Top-left
      [
        Offset(radius, 0),
        Offset(0, 0),
        Offset(0, bracketLength),
      ],
      // Top-right
      [
        Offset(size.width - radius, 0),
        Offset(size.width, 0),
        Offset(size.width, bracketLength),
      ],
      // Bottom-left
      [
        Offset(0, size.height - bracketLength),
        Offset(0, size.height),
        Offset(radius, size.height),
      ],
      // Bottom-right
      [
        Offset(size.width, size.height - bracketLength),
        Offset(size.width, size.height),
        Offset(size.width - radius, size.height),
      ],
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.opacity != opacity;
}
