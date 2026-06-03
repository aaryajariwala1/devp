import 'dart:typed_data';
import 'package:equatable/equatable.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();

  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {
  const ScannerInitial();
}

class CameraInitializing extends ScannerState {
  const CameraInitializing();
}

class CameraReady extends ScannerState {
  const CameraReady();
}

class CameraError extends ScannerState {
  final String message;
  const CameraError(this.message);

  @override
  List<Object?> get props => [message];
}

class PhotoCaptured extends ScannerState {
  final Uint8List compressedBytes;
  const PhotoCaptured(this.compressedBytes);

  @override
  List<Object?> get props => [compressedBytes];
}

class ScanProcessing extends ScannerState {
  final Uint8List imageBytes;
  const ScanProcessing(this.imageBytes);

  @override
  List<Object?> get props => [imageBytes];
}

class ScanResultState extends ScannerState {
  final bool matched;
  final String? designId;
  final String? designName;
  final double confidence;
  final int? takaCount;
  final bool isNewDesign;
  final Uint8List imageBytes;

  const ScanResultState({
    required this.matched,
    this.designId,
    this.designName,
    required this.confidence,
    this.takaCount,
    this.isNewDesign = false,
    required this.imageBytes,
  });

  @override
  List<Object?> get props => [
        matched,
        designId,
        designName,
        confidence,
        takaCount,
        isNewDesign,
      ];
}

class ScanError extends ScannerState {
  final String message;
  const ScanError(this.message);

  @override
  List<Object?> get props => [message];
}

class InventoryAdjusted extends ScannerState {
  final String designId;
  final int newCount;

  const InventoryAdjusted({required this.designId, required this.newCount});

  @override
  List<Object?> get props => [designId, newCount];
}
