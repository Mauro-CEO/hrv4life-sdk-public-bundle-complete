import 'dart:async';
import 'package:camera/camera.dart';

/// Internal service for camera management.
/// NOT EXPORTED - internal use only.
///
/// Transport only: initialization, image streaming and flash control.
/// Every measurement concern (finger detection, FPS validation, PPG
/// intensity extraction, calibration and capture) runs inside the
/// `hrv4life_core` engine (native FFI or the pure-Dart fake backend).
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isDisposed = false;

  /// Returns the camera controller.
  CameraController? get controller => _controller;

  /// Returns true if camera is initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the camera service with the back camera.
  ///
  /// Uses low resolution for PPG (we only need intensity, not image quality).
  Future<void> initialize() async {
    if (_isDisposed) return;

    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw CameraException('No cameras available', 'No cameras found on device');
    }

    // Find back camera
    final backCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    _isInitialized = true;
  }

  /// Starts image streaming with the provided callback.
  Future<void> startImageStream(void Function(CameraImage image) onImage) async {
    if (!_isInitialized || _controller == null || _isDisposed) return;

    await _controller!.startImageStream(onImage);
  }

  /// Stops image streaming.
  Future<void> stopImageStream() async {
    if (!_isInitialized || _controller == null || _isDisposed) return;

    try {
      await _controller!.stopImageStream();
    } catch (_) {
      // Ignore errors when stopping stream
    }
  }

  /// Turns on the flash (torch mode).
  Future<void> enableFlash() async {
    if (!_isInitialized || _controller == null || _isDisposed) return;

    try {
      await _controller!.setFlashMode(FlashMode.torch);
    } catch (_) {
      // Ignore flash errors on devices without flash
    }
  }

  /// Turns off the flash.
  Future<void> disableFlash() async {
    if (!_isInitialized || _controller == null || _isDisposed) return;

    try {
      await _controller!.setFlashMode(FlashMode.off);
    } catch (_) {
      // Ignore flash errors
    }
  }

  /// Disposes of camera resources.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    try {
      // Call directly on _controller to bypass _isDisposed guard in helper methods
      await _controller?.stopImageStream();
      await _controller?.setFlashMode(FlashMode.off);
      await _controller?.dispose();
    } catch (_) {
      // Ignore disposal errors
    }

    _controller = null;
    _isInitialized = false;
  }
}