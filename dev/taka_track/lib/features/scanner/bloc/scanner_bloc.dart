import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/remote/inventory_repository.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final InventoryRepository _repository;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  CameraController? get cameraController => _cameraController;

  ScannerBloc({required InventoryRepository repository})
      : _repository = repository,
        super(const ScannerInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<CapturePhoto>(_onCapturePhoto);
    on<RetryCapture>(_onRetryCapture);
    on<ConfirmScan>(_onConfirmScan);
    on<ResetScanner>(_onResetScanner);
  }

  Future<void> _onInitializeCamera(
      InitializeCamera event, Emitter<ScannerState> emit) async {
    emit(const CameraInitializing());
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        emit(const CameraError('No cameras found on device.'));
        return;
      }

      // Dispose previous controller if any
      await _disposeCameraController();

      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!_cameraController!.value.isInitialized) {
        emit(const CameraError('Camera failed to initialize.'));
        return;
      }

      emit(const CameraReady());
    } on CameraException catch (e) {
      emit(CameraError(e.description ?? 'Camera permission denied.'));
    } catch (e) {
      emit(CameraError('Camera error: ${e.toString()}'));
    }
  }

  Future<void> _onCapturePhoto(
      CapturePhoto event, Emitter<ScannerState> emit) async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      emit(const ScanError('Camera is not ready.'));
      return;
    }

    try {
      final XFile xFile = await _cameraController!.takePicture();
      final rawBytes = await xFile.readAsBytes();

      // Compress image
      final Uint8List? compressed = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth: AppConstants.maxImageDimension,
        minHeight: AppConstants.maxImageDimension,
        quality: AppConstants.imageQuality,
        format: CompressFormat.jpeg,
      );

      final imageBytes = compressed ?? rawBytes;

      emit(PhotoCaptured(imageBytes));

      // Automatically trigger scan
      emit(ScanProcessing(imageBytes));
      try {
        final result = await _repository.scanDesign(imageBytes);
        emit(ScanResultState(
          matched: result.matched,
          designId: result.designId,
          designName: result.designName,
          confidence: result.confidence,
          takaCount: result.takaCount,
          isNewDesign: result.isNewDesign,
          imageBytes: imageBytes,
        ));
      } catch (e) {
        // On scan failure, still show a no-match result
        emit(ScanResultState(
          matched: false,
          confidence: 0.0,
          isNewDesign: true,
          imageBytes: imageBytes,
        ));
      }
    } on CameraException catch (e) {
      emit(ScanError('Capture failed: ${e.description ?? e.toString()}'));
    } catch (e) {
      emit(ScanError('Capture error: ${e.toString()}'));
    }
  }

  Future<void> _onRetryCapture(
      RetryCapture event, Emitter<ScannerState> emit) async {
    emit(const CameraReady());
  }

  Future<void> _onConfirmScan(
      ConfirmScan event, Emitter<ScannerState> emit) async {
    try {
      await _repository.adjustInventory(event.designId, event.delta, null);
      final design = _repository.getCachedDesigns()
          .where((d) => d.id == event.designId)
          .firstOrNull;
      final newCount = (design?.currentTakaCount ?? 0);
      emit(InventoryAdjusted(designId: event.designId, newCount: newCount));
    } catch (e) {
      emit(ScanError('Failed to adjust inventory: ${e.toString()}'));
    }
  }

  Future<void> _onResetScanner(
      ResetScanner event, Emitter<ScannerState> emit) async {
    emit(const ScannerInitial());
  }

  Future<void> _disposeCameraController() async {
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isInitialized) {
          await _cameraController!.dispose();
        }
      } catch (_) {}
      _cameraController = null;
    }
  }

  @override
  Future<void> close() async {
    await _disposeCameraController();
    return super.close();
  }
}
