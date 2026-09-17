import 'package:flutter/foundation.dart';

import '../models/frame_data.dart';
import '../models/hrv_config.dart';
import 'fake_hrv_core.dart';
import 'native_hrv_core.dart';

/// Frame format hints mirroring `hrv_core.h` (`HRV_FORMAT_*`).
class HrvCoreFormat {
  static const int auto = 0;
  static const int yuv420 = 1;
  static const int nv12 = 2;
  static const int nv21 = 3;

  const HrvCoreFormat._();
}

/// Stable error codes mirroring `hrv_core.h` (`HRV_ERRCODE_*`).
class HrvCoreErrorCode {
  static const int none = 0;
  static const int notInitialized = 1;
  static const int fpsRejected = 2;

  const HrvCoreErrorCode._();
}

/// Immutable snapshot of the native measurement engine state.
@immutable
class HrvCoreState {
  /// Status, 1:1 mapping to [HrvMonitorStatus.index].
  final int status;

  final bool isInitialized;
  final bool isMeasuring;
  final bool isFingerDetected;

  final int progress;
  final int elapsedSeconds;
  final int measuredFps;
  final int frameCount;

  /// True once the invisible calibration window has produced enough frames.
  final bool calibrationReady;

  final int errorCode;
  final double lastIntensity;
  final double lastLuminance;

  const HrvCoreState({
    required this.status,
    required this.isInitialized,
    required this.isMeasuring,
    required this.isFingerDetected,
    required this.progress,
    required this.elapsedSeconds,
    required this.measuredFps,
    required this.frameCount,
    required this.calibrationReady,
    required this.errorCode,
    required this.lastIntensity,
    required this.lastLuminance,
  });
}

/// Abstraction over the measurement engine.
///
/// On device the engine runs natively ([NativeHrvCore]); in host tests
/// (or when the native library is unavailable) [FakeHrvCore] mirrors the
/// exact same state machine in pure Dart.
abstract class HrvCoreBackend {
  /// Whether this backend is backed by the real native library.
  bool get isAvailable;

  void initialize();
  void startMeasure();
  void stopMeasure();
  void reset();

  HrvCoreState getState();

  /// Feeds one camera frame to the engine.
  ///
  /// [planes] are the Y/UV plane byte buffers, [rowStrides]/[pixelStrides]
  /// their stride descriptors and [timestampMs] the capture timestamp.
  void processFrame({
    required List<Uint8List> planes,
    required List<int> rowStrides,
    required List<int> pixelStrides,
    required int width,
    required int height,
    required int timestampMs,
    int format = HrvCoreFormat.auto,
  });

  /// Take-and-forget buffers (native alloc owns them afterward).
  List<FrameData> takeCapturedFrames();
  List<FrameData> takeCalibrationFrames();
  List<double> takeChart();

  String get lastError;

  void dispose();
}

/// Resolves the platform backend:
/// native FFI when bundled, otherwise the pure-Dart fake.
///
/// [forceFake] forces the fake backend (used by host unit tests).
HrvCoreBackend createHrvCoreBackend({
  HrvMonitorConfig? config,
  bool forceFake = false,
}) {
  if (!forceFake) {
    try {
      return NativeHrvCore(config: config);
    } catch (e) {
      print('Native HRV core unavailable, falling back to fake implementation');
      print('Error: $e');    }
  }
  return FakeHrvCore(config: config);
}