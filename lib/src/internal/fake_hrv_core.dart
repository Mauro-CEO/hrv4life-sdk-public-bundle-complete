import 'dart:math' as math;
import 'dart:typed_data';

import '../models/frame_data.dart';
import '../models/hrv_config.dart';
import 'hrv_core_backend.dart';

/// Mirrors the native engine's constants (see `hrv_core.h` / `engine.cpp`).
const int _kStatusUninitialized = 0;
const int _kStatusReady = 2;
const int _kStatusWaitingForFinger = 3;
const int _kStatusMeasuring = 4;
const int _kStatusPaused = 5;
const int _kStatusCompleted = 7;
const int _kStatusError = 8;

const int _kChartLimit = 100;
const int _kMillisecondsPerSecond = 1000;

int _clampByte(num v) => v.clamp(0, 255).toInt();

int _round(num v) => v.round();

/// Pure-Dart implementation of the measurement engine used for host tests and
/// as a documented reference of the exact state machine.
///
/// The native [NativeHrvCore] is the production backend; this class must stay
/// observably equivalent to `engine.cpp`.
class FakeHrvCore implements HrvCoreBackend {
  final HrvMonitorConfig _config;

  int _status = _kStatusUninitialized;
  bool _initialized = false;
  bool _measuring = false;
  bool _fingerDetected = false;
  int _progress = 0;
  int _elapsedSeconds = 0;
  int _measuredFps = 0;
  int _errorCode = HrvCoreErrorCode.none;
  double _lastIntensity = 0;
  double _lastLuminance = 0;

  final List<FrameData> _capturedFrames = [];
  final List<FrameData> _calibrationFrames = [];
  final List<double> _chart = [];

  // FPS meter (2s window, warm-up 90).
  final List<int> _fpsTimestamps = [];
  int _ppgFrameCount = 0;
  int _skipInterval = 1;
  bool _fpsCalibrated = false;
  bool _fpsRejected = false;

  // Finger detection.
  int _consecutiveFinger = 0;
  int _consecutiveNoFinger = 0;

  // Measurement timeline.
  int _measurementStartMs = -1;
  int _pausedElapsedMs = 0;
  int _displayElapsedMs = 0;
  int _lastTimestampMs = 0;

  // Calibration.
  bool _calibrating = false;
  bool _calibrationDone = false;
  int _calibrationStartMs = -1;
  bool _calibrationReady = false;

  FakeHrvCore({HrvMonitorConfig? config}) : _config = config ?? const HrvMonitorConfig();

  int get _measurementSeconds => _config.measurementDuration.inSeconds;
  int get _calibrationSeconds => 4;
  int get _calibrationMinFrames => 30;
  int get _framesToConfirm => 5;
  int get _framesToLose => 10;
  int get _targetFps => 30;
  int get _minimumFps => 15;
  int get _warmupFrames => 90;

  @override
  bool get isAvailable => false;

  @override
  String get lastError => '';

  @override
  void initialize() {
    _initialized = true;
    _status = _kStatusReady;
  }

  @override
  void startMeasure() {
    if (!_initialized) {
      _status = _kStatusError;
      _errorCode = HrvCoreErrorCode.notInitialized;
      _measuring = false;
      return;
    }
    if (_measuring) return;

    _capturedFrames.clear();
    _calibrationFrames.clear();
    _chart.clear();
    _resetFps();
    _fingerDetected = false;
    _consecutiveFinger = 0;
    _consecutiveNoFinger = 0;
    _measurementStartMs = -1;
    _pausedElapsedMs = 0;
    _displayElapsedMs = 0;
    _calibrating = false;
    _calibrationDone = false;
    _calibrationStartMs = -1;
    _calibrationReady = false;
    _errorCode = HrvCoreErrorCode.none;
    _lastIntensity = 0;
    _lastLuminance = 0;

    _status = _kStatusWaitingForFinger;
    _measuring = true;
  }

  @override
  void stopMeasure() {
    if (_status == _kStatusWaitingForFinger ||
        _status == _kStatusMeasuring ||
        _status == _kStatusPaused) {
      _status = _kStatusReady;
      _measuring = false;
      _measurementStartMs = -1;
    }
  }

  @override
  void reset() {
    stopMeasure();
    _capturedFrames.clear();
    _calibrationFrames.clear();
    _chart.clear();
    _fingerDetected = false;
    _consecutiveFinger = 0;
    _consecutiveNoFinger = 0;
    _pausedElapsedMs = 0;
    _displayElapsedMs = 0;
    _calibrating = false;
    _calibrationDone = false;
    _calibrationStartMs = -1;
    _calibrationReady = false;
    if (_initialized) _status = _kStatusReady;
  }

  @override
  void processFrame({
    required List<Uint8List> planes,
    required List<int> rowStrides,
    required List<int> pixelStrides,
    required int width,
    required int height,
    required int timestampMs,
    int format = HrvCoreFormat.auto,
  }) {
    final canProcess = _status == _kStatusWaitingForFinger ||
        _status == _kStatusMeasuring ||
        _status == _kStatusPaused;
    if (!canProcess) return;

    _lastTimestampMs = timestampMs;
    final luminance = extractLuminance(planes, rowStrides, pixelStrides, width, height);
    _lastLuminance = luminance;
    _fpsTimestamps.add(timestampMs);
    while (_fpsTimestamps.isNotEmpty &&
        timestampMs - _fpsTimestamps.first > 2000) {
      _fpsTimestamps.removeAt(0);
    }
    if (_fpsTimestamps.length >= 2) {
      final elapsed = _fpsTimestamps.last - _fpsTimestamps.first;
      if (elapsed > 0) {
        _measuredFps = ((_fpsTimestamps.length - 1) * _kMillisecondsPerSecond ~/ elapsed);
      }
    }

    final wasDetected = _fingerDetected;
    final inRange = luminance >= _config.minFingerLuminance &&
        luminance <= _config.maxFingerLuminance;
    if (inRange) {
      _consecutiveFinger++;
      _consecutiveNoFinger = 0;
      if (!_fingerDetected && _consecutiveFinger >= _framesToConfirm) {
        _fingerDetected = true;
      }
    } else {
      _consecutiveNoFinger++;
      _consecutiveFinger = 0;
      if (_fingerDetected && _consecutiveNoFinger >= _framesToLose) {
        _fingerDetected = false;
      }
    }
    if (wasDetected != _fingerDetected) {
      if (_fingerDetected) {
        _onFingerDetected(timestampMs);
      } else {
        _onFingerLost();
      }
    }

    if (_status == _kStatusMeasuring && _fingerDetected) {
      _ppgFrameCount++;
      if (!_fpsCalibrated && _ppgFrameCount >= _warmupFrames) {
        _fpsCalibrated = true;
        if (_measuredFps > 0 && _measuredFps < _minimumFps) {
          _fpsRejected = true;
        } else if (_measuredFps >= _targetFps + 15) {
          _skipInterval = 2;
        }
      }
      final accepted = _ppgFrameCount % _skipInterval == 0;
      if (!accepted) return;

      if (_fpsRejected) {
        _status = _kStatusError;
        _errorCode = HrvCoreErrorCode.fpsRejected;
        _measuring = false;
        return;
      }

      final intensity = extractIntensity(
          planes, rowStrides, pixelStrides, width, height, format);
      _lastIntensity = intensity;

      if (_calibrating) {
        _calibrationFrames.add(FrameData(
          intensity: intensity,
          timestamp: timestampMs,
        ));
        _checkCalibrationComplete(timestampMs);
      }

      if (_measurementStartMs >= 0) {
        _capturedFrames.add(FrameData(
          intensity: intensity,
          timestamp: timestampMs,
        ));
        _chart.add(intensity);
        if (_chart.length > _kChartLimit) {
          _chart.removeAt(0);
        }
        _displayElapsedMs = timestampMs - _measurementStartMs;
        _elapsedSeconds = _displayElapsedMs ~/ _kMillisecondsPerSecond;
        _progress = (_measurementSeconds <= 0)
            ? 0
            : (_displayElapsedMs * 100 ~/ (_measurementSeconds * _kMillisecondsPerSecond))
                .clamp(0, 100);
      }

      if (_measurementStartMs >= 0 &&
          timestampMs - _measurementStartMs >=
              _measurementSeconds * _kMillisecondsPerSecond) {
        _displayElapsedMs = _measurementSeconds * _kMillisecondsPerSecond;
        _elapsedSeconds = _measurementSeconds;
        _progress = 100;
        _status = _kStatusCompleted;
        _measuring = false;
      }
    }
  }

  void _onFingerDetected(int timestampMs) {
    if (_measurementStartMs < 0) {
      _measurementStartMs = timestampMs;
      _pausedElapsedMs = 0;
      if (!_calibrationDone) {
        _calibrating = true;
        _calibrationStartMs = timestampMs;
        _calibrationFrames.clear();
      }
    } else {
      _measurementStartMs = timestampMs - _pausedElapsedMs;
    }
    _status = _kStatusMeasuring;
    _measuring = true;
  }

  void _onFingerLost() {
    if (_measurementStartMs >= 0) {
      _pausedElapsedMs = _lastTimestampMs - _measurementStartMs;
      _displayElapsedMs = _pausedElapsedMs;
      _elapsedSeconds = _displayElapsedMs ~/ _kMillisecondsPerSecond;
    }
    _status = _kStatusPaused;
    _measuring = false;
  }

  void _checkCalibrationComplete(int timestampMs) {
    if (!_calibrating || _calibrationStartMs < 0) return;
    if (timestampMs - _calibrationStartMs < _calibrationSeconds * _kMillisecondsPerSecond) {
      return;
    }
    _calibrating = false;
    _calibrationDone = true;
    _calibrationReady = _calibrationFrames.length >= _calibrationMinFrames;
  }

  @override
  HrvCoreState getState() {
    return HrvCoreState(
      status: _status,
      isInitialized: _initialized,
      isMeasuring: _measuring,
      isFingerDetected: _fingerDetected,
      progress: _progress,
      elapsedSeconds: _elapsedSeconds,
      measuredFps: _measuredFps,
      frameCount: _capturedFrames.length,
      calibrationReady: _calibrationReady,
      errorCode: _errorCode,
      lastIntensity: _lastIntensity,
      lastLuminance: _lastLuminance,
    );
  }

  @override
  List<FrameData> takeCapturedFrames() {
    final frames = List<FrameData>.from(_capturedFrames);
    _capturedFrames.clear();
    return frames;
  }

  @override
  List<FrameData> takeCalibrationFrames() {
    final frames = List<FrameData>.from(_calibrationFrames);
    _calibrationFrames.clear();
    _calibrationReady = false;
    return frames;
  }

  @override
  List<double> takeChart() {
    final chart = List<double>.from(_chart);
    _chart.clear();
    return chart;
  }

  @override
  void dispose() {}

  void _resetFps() {
    _fpsTimestamps.clear();
    _ppgFrameCount = 0;
    _skipInterval = 1;
    _fpsCalibrated = false;
    _fpsRejected = false;
    _measuredFps = 0;
  }

  /// Y-plane mean luminance over a ROI (10% borders, step 10).
  double extractLuminance(
    List<Uint8List> planes,
    List<int> rowStrides,
    List<int> pixelStrides,
    int width,
    int height,
  ) {
    if (planes.isEmpty) return 0;
    final bytes = planes[0];
    if (bytes.isEmpty) return 0;
    final rowStride = rowStrides.isNotEmpty ? rowStrides[0] : width;
    final pixelStride = pixelStrides.isNotEmpty ? pixelStrides[0] : 1;
    final mx = _round(width * 0.1);
    final my = _round(height * 0.1);

    var sum = 0.0;
    var count = 0;
    for (var row = my; row < height - my; row += 10) {
      final base = row * rowStride;
      for (var col = mx; col < width - mx; col += 10) {
        final idx = base + col * pixelStride;
        if (idx < 0 || idx >= bytes.length) continue;
        sum += bytes[idx];
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  /// Weighted-luminance intensity over a ROI (10% borders, step 5).
  double extractIntensity(
    List<Uint8List> planes,
    List<int> rowStrides,
    List<int> pixelStrides,
    int width,
    int height,
    int format,
  ) {
    if (planes.length < 2) return 0;
    if (format == HrvCoreFormat.auto) {
      format = planes.length >= 3 ? HrvCoreFormat.yuv420 : HrvCoreFormat.nv21;
    }
    if (format != HrvCoreFormat.yuv420 &&
        format != HrvCoreFormat.nv12 &&
        format != HrvCoreFormat.nv21) {
      return 0;
    }

    final y = planes[0];
    final yRow = rowStrides.isNotEmpty ? rowStrides[0] : width;
    final yPx = pixelStrides.isNotEmpty ? pixelStrides[0] : 1;
    final uvRow = rowStrides.length > 1 ? rowStrides[1] : width ~/ 2;
    final uvPx = pixelStrides.length > 1 ? pixelStrides[1] : 1;
    final uvPlane = planes[1];

    final interleaved = format != HrvCoreFormat.yuv420;
    final uvFirst = format == HrvCoreFormat.nv12;

    final mx = _round(width * 0.1);
    final my = _round(height * 0.1);

    var sum = 0.0;
    var count = 0;
    for (var row = my; row < height - my; row += 5) {
      final yBase = row * yRow;
      final uvBase = (row ~/ 2) * uvRow;
      for (var col = mx; col < width - mx; col += 5) {
        final yIdx = yBase + col * yPx;
        if (yIdx >= y.length) continue;
        final yv = y[yIdx];
        final uIdx = uvBase + (col ~/ 2) * uvPx;

        int r = yv;
        int g = yv;
        int b = yv;
        if (interleaved) {
          if (uIdx + 1 < uvPlane.length) {
            final first = uvPlane[uIdx];
            final second = uvPlane[uIdx + 1];
            final u = uvFirst ? first : second;
            final v = uvFirst ? second : first;
            r = _clampByte(yv + 1.370705 * (v - 128));
            g = _clampByte(yv - 0.698001 * (v - 128) - 0.337633 * (u - 128));
            b = _clampByte(yv + 1.732446 * (u - 128));
          }
        } else if (planes.length >= 3 && uIdx < planes[2].length) {
          final u = uvPlane[uIdx];
          final v = planes[2][uIdx];
          r = _clampByte(yv + 1.370705 * (v - 128));
          g = _clampByte(yv - 0.698001 * (v - 128) - 0.337633 * (u - 128));
          b = _clampByte(yv + 1.732446 * (u - 128));
        }

        sum += 0.299 * r + 0.587 * g + 0.114 * b;
        count++;
      }
    }
    if (count == 0) return 0;
    final mean = sum / count;
    if (mean <= 0) return 0;
    return -math.sqrt(mean);
  }
}