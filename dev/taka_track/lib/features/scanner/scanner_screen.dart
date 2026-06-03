import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/remote/inventory_repository.dart';
import '../bloc/scanner_bloc.dart';
import '../bloc/scanner_event.dart';
import '../bloc/scanner_state.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/scan_overlay.dart';

class ScannerScreen extends StatefulWidget {
  final InventoryRepository repository;

  const ScannerScreen({super.key, required this.repository});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late ScannerBloc _bloc;
  bool _isDisposed = false;
  bool _resultSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc = ScannerBloc(repository: widget.repository);
    _bloc.add(const InitializeCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _releaseCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (!_resultSheetOpen) {
        _bloc.add(const InitializeCamera());
      }
    }
  }

  void _releaseCamera() {
    final controller = _bloc.cameraController;
    if (controller != null && controller.value.isInitialized) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScannerBloc>.value(
      value: _bloc,
      child: BlocConsumer<ScannerBloc, ScannerState>(
        listener: (context, state) {
          if (state is ScanResultState && !_resultSheetOpen) {
            _resultSheetOpen = true;
            _showResultSheet(context, state);
          }
          if (state is InventoryAdjusted) {
            if (_resultSheetOpen) {
              Navigator.of(context).pop();
              _resultSheetOpen = false;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Inventory updated! New count: ${state.newCount}'),
                backgroundColor: AppColors.mint.withOpacity(0.9),
              ),
            );
            Navigator.of(context).pop(); // Pop scanner
          }
          if (state is ScanError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.coral.withOpacity(0.9),
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview
                CameraPreviewWidget(
                    controller: _bloc.cameraController),
                // Overlay
                ScanOverlay(
                  isProcessing:
                      state is ScanProcessing || state is PhotoCaptured,
                  onCapture: state is CameraReady
                      ? () => _bloc.add(const CapturePhoto())
                      : null,
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.white, size: 18),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // Camera error state
                if (state is CameraError)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.no_photography_rounded,
                              size: 64, color: AppColors.coral),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () =>
                                _bloc.add(const InitializeCamera()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showResultSheet(BuildContext context, ScanResultState result) {
    int _delta = 1;
    String _type = 'INWARD';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.muted.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Match result
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: result.matched
                                  ? AppColors.mint.withOpacity(0.15)
                                  : AppColors.coral.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: result.matched
                                    ? AppColors.mint.withOpacity(0.5)
                                    : AppColors.coral.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              result.matched ? 'MATCHED' : 'NO MATCH',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: result.matched
                                    ? AppColors.mint
                                    : AppColors.coral,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (result.matched)
                            Text(
                              '${(result.confidence * 100).toStringAsFixed(0)}% confidence',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.designName ?? 'Unknown Design',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      if (result.matched) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Current stock: ${result.takaCount ?? '—'} takas',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.muted),
                        ),
                      ],
                      const SizedBox(height: 20),
                      // Confidence bar
                      if (result.matched) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: result.confidence,
                            backgroundColor:
                                AppColors.muted.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              result.confidence > 0.7
                                  ? AppColors.mint
                                  : AppColors.amber,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // INWARD / OUTWARD toggle
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => _type = 'INWARD'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _type == 'INWARD'
                                      ? AppColors.mint.withOpacity(0.15)
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _type == 'INWARD'
                                        ? AppColors.mint
                                        : AppColors.divider,
                                  ),
                                ),
                                child: const Text(
                                  'INWARD',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mint,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => _type = 'OUTWARD'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _type == 'OUTWARD'
                                      ? AppColors.coral.withOpacity(0.15)
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _type == 'OUTWARD'
                                        ? AppColors.coral
                                        : AppColors.divider,
                                  ),
                                ),
                                child: const Text(
                                  'OUTWARD',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.coral,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Quantity adjuster
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StepButton(
                            icon: Icons.remove,
                            onTap: () => setSheetState(
                                () => _delta = (_delta - 1).clamp(1, 9999)),
                          ),
                          const SizedBox(width: 24),
                          Column(
                            children: [
                              Text(
                                '$_delta',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                              const Text(
                                'TAKAS',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          _StepButton(
                            icon: Icons.add,
                            onTap: () => setSheetState(
                                () => _delta = (_delta + 1).clamp(1, 9999)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Confirm button
                      if (result.matched && result.designId != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final actualDelta = _type == 'INWARD'
                                  ? _delta
                                  : -_delta;
                              _bloc.add(ConfirmScan(
                                designId: result.designId!,
                                delta: actualDelta,
                              ));
                            },
                            child: const Text('Confirm & Log'),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.muted),
                              foregroundColor: AppColors.white,
                            ),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _resultSheetOpen = false;
                              _bloc.add(const ResetScanner());
                              _bloc.add(const InitializeCamera());
                            },
                            child: const Text('Scan Again'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _resultSheetOpen = false;
                            _bloc.add(const RetryCapture());
                          },
                          child: const Text(
                            'Try Again',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (!_isDisposed) {
        _resultSheetOpen = false;
      }
    });
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceLight,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, color: AppColors.white, size: 22),
      ),
    );
  }
}
