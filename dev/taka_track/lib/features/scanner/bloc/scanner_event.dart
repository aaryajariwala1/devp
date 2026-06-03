abstract class ScannerEvent {
  const ScannerEvent();
}

class InitializeCamera extends ScannerEvent {
  const InitializeCamera();
}

class CapturePhoto extends ScannerEvent {
  const CapturePhoto();
}

class RetryCapture extends ScannerEvent {
  const RetryCapture();
}

class ConfirmScan extends ScannerEvent {
  final String designId;
  final int delta;

  const ConfirmScan({required this.designId, required this.delta});
}

class ResetScanner extends ScannerEvent {
  const ResetScanner();
}
