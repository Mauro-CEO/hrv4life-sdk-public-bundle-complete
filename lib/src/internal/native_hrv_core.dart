import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../models/frame_data.dart';
import '../models/hrv_config.dart';
import 'hrv_core_backend.dart';

typedef _HrvCoreHandle = Opaque;

final class _HrvCoreNativeConfig extends Struct {
  @Int32()
  external int minLuminance;

  @Int32()
  external int maxLuminance;

  @Int32()
  external int calibrationSeconds;

  @Int32()
  external int calibrationMinFrames;

  @Int32()
  external int measurementSeconds;

  @Int32()
  external int targetFps;

  @Int32()
  external int minFps;

  @Int32()
  external int fpsWarmupFrames;

  @Int32()
  external int framesToConfirm;

  @Int32()
  external int framesToLose;
}

final class _HrvPlane extends Struct {
  external Pointer<Uint8> data;

  @IntPtr()
  external int len;

  @IntPtr()
  external int rowStride;

  @IntPtr()
  external int pixelStride;
}

final class _HrvFrame extends Struct {
  @Double()
  external double intensity;

  @Int64()
  external int timestampMs;
}

final class _HrvCoreState extends Struct {
  @Int32()
  external int status;

  @Int32()
  external int isInitialized;

  @Int32()
  external int isMeasuring;

  @Int32()
  external int isFingerDetected;

  @Int32()
  external int progress;

  @Int32()
  external int elapsedSeconds;

  @Int32()
  external int measuredFps;

  @Int32()
  external int frameCount;

  @Int32()
  external int calibrationReady;

  @Int32()
  external int errorCode;

  @Double()
  external double lastIntensity;

  @Double()
  external double lastLuminance;
}

typedef _CreateNative = Pointer<_HrvCoreHandle> Function(Pointer<_HrvCoreNativeConfig>);
typedef _CreateDart = Pointer<_HrvCoreHandle> Function(Pointer<_HrvCoreNativeConfig>);

typedef _VoidNative = Void Function(Pointer<_HrvCoreHandle>);
typedef _VoidDart = void Function(Pointer<_HrvCoreHandle>);

typedef _DestroyNative = Void Function(Pointer<_HrvCoreHandle>);
typedef _DestroyDart = void Function(Pointer<_HrvCoreHandle>);

typedef _ProcessFrameNative = Int32 Function(
    Pointer<_HrvCoreHandle>, Pointer<_HrvPlane>, IntPtr, Uint32, Uint32, Int32, Int64);
typedef _ProcessFrameDart = int Function(
    Pointer<_HrvCoreHandle>, Pointer<_HrvPlane>, int, int, int, int, int);

typedef _GetStateNative = Void Function(Pointer<_HrvCoreHandle>, Pointer<_HrvCoreState>);
typedef _GetStateDart = void Function(Pointer<_HrvCoreHandle>, Pointer<_HrvCoreState>);

typedef _TakeFramesNative = Pointer<_HrvFrame> Function(Pointer<_HrvCoreHandle>, Pointer<IntPtr>);
typedef _TakeFramesDart = Pointer<_HrvFrame> Function(Pointer<_HrvCoreHandle>, Pointer<IntPtr>);

typedef _TakeChartNative = Pointer<Double> Function(Pointer<_HrvCoreHandle>, Pointer<IntPtr>);
typedef _TakeChartDart = Pointer<Double> Function(Pointer<_HrvCoreHandle>, Pointer<IntPtr>);

typedef _FreeNative = Void Function(Pointer<Void>);
typedef _FreeDart = void Function(Pointer<Void>);

typedef _LastErrorNative = Pointer<Utf8> Function(Pointer<_HrvCoreHandle>);
typedef _LastErrorDart = Pointer<Utf8> Function(Pointer<_HrvCoreHandle>);

/// FFI bindings to `libhrv4life_core` (C ABI in `hrv_core.h`).
///
/// Constructing this class loads the platform library and throws when it is
/// not available, so callers can fall back to [FakeHrvCore].
class NativeHrvCore implements HrvCoreBackend {
  final DynamicLibrary _lib;
  late final Pointer<_HrvCoreHandle> _core;
  late final _CreateDart _create;
  late final _DestroyDart _destroy;
  late final _VoidDart _initialize;
  late final _VoidDart _startMeasure;
  late final _VoidDart _stopMeasure;
  late final _VoidDart _reset;
  late final _ProcessFrameDart _processFrame;
  late final _GetStateDart _getState;
  late final _TakeFramesDart _takeCaptured;
  late final _TakeFramesDart _takeCalibration;
  late final _TakeChartDart _takeChart;
  late final _FreeDart _free;
  late final _LastErrorDart _lastError;

  NativeHrvCore({HrvMonitorConfig? config}) : _lib = _openLibrary() {
    _create = _lib
        .lookupFunction<_CreateNative, _CreateDart>('hrv_core_create');
    _destroy = _lib
        .lookupFunction<_DestroyNative, _DestroyDart>('hrv_core_destroy');
    _initialize = _lib
        .lookupFunction<_VoidNative, _VoidDart>('hrv_core_initialize');
    _startMeasure = _lib
        .lookupFunction<_VoidNative, _VoidDart>('hrv_core_start_measure');
    _stopMeasure = _lib
        .lookupFunction<_VoidNative, _VoidDart>('hrv_core_stop_measure');
    _reset = _lib.lookupFunction<_VoidNative, _VoidDart>('hrv_core_reset');
    _processFrame = _lib.lookupFunction<_ProcessFrameNative, _ProcessFrameDart>(
        'hrv_core_process_frame');
    _getState =
        _lib.lookupFunction<_GetStateNative, _GetStateDart>('hrv_core_get_state');
    _takeCaptured = _lib.lookupFunction<_TakeFramesNative, _TakeFramesDart>(
        'hrv_core_take_captured_frames');
    _takeCalibration = _lib.lookupFunction<_TakeFramesNative, _TakeFramesDart>(
        'hrv_core_take_calibration_frames');
    _takeChart =
        _lib.lookupFunction<_TakeChartNative, _TakeChartDart>('hrv_core_take_chart');
    _free = _lib.lookupFunction<_FreeNative, _FreeDart>('hrv_core_free');
    _lastError =
        _lib.lookupFunction<_LastErrorNative, _LastErrorDart>('hrv_core_last_error');

    final cfg = calloc<_HrvCoreNativeConfig>();
    try {
      cfg.ref
        ..minLuminance = config?.minFingerLuminance ?? 50
        ..maxLuminance = config?.maxFingerLuminance ?? 95
        ..calibrationSeconds = 4
        ..calibrationMinFrames = 30
        ..measurementSeconds = (config?.measurementDuration ?? const Duration(minutes: 3)).inSeconds
        ..targetFps = 30
        ..minFps = 15
        ..fpsWarmupFrames = 90
        ..framesToConfirm = 5
        ..framesToLose = 10;
      _core = _create(cfg);
    } finally {
      calloc.free(cfg);
    }

    if (_core == nullptr) {
      throw StateError('hrv_core_create() failed');
    }
  }

  @override
  bool get isAvailable => true;

  @override
  void initialize() => _initialize(_core);

  @override
  void startMeasure() => _startMeasure(_core);

  @override
  void stopMeasure() => _stopMeasure(_core);

  @override
  void reset() => _reset(_core);

  @override
  HrvCoreState getState() {
    final state = calloc<_HrvCoreState>();
    try {
      _getState(_core, state);
      return HrvCoreState(
        status: state.ref.status,
        isInitialized: state.ref.isInitialized != 0,
        isMeasuring: state.ref.isMeasuring != 0,
        isFingerDetected: state.ref.isFingerDetected != 0,
        progress: state.ref.progress,
        elapsedSeconds: state.ref.elapsedSeconds,
        measuredFps: state.ref.measuredFps,
        frameCount: state.ref.frameCount,
        calibrationReady: state.ref.calibrationReady != 0,
        errorCode: state.ref.errorCode,
        lastIntensity: state.ref.lastIntensity,
        lastLuminance: state.ref.lastLuminance,
      );
    } finally {
      calloc.free(state);
    }
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
    if (planes.isEmpty) return;

    final planePtrs = <Pointer<Uint8>>[];
    final planesArr = calloc<_HrvPlane>(planes.length);
    try {
      for (var i = 0; i < planes.length; i++) {
        final bytes = planes[i];
        final buf = calloc<Uint8>(bytes.length);
        planePtrs.add(buf);
        buf.asTypedList(bytes.length).setAll(0, bytes);

        planesArr[i]
          ..data = buf
          ..len = bytes.length
          ..rowStride = i < rowStrides.length ? rowStrides[i] : (i == 0 ? width : width ~/ 2)
          ..pixelStride =
              i < pixelStrides.length ? pixelStrides[i] : (i == 0 ? 1 : 2);
      }
      _processFrame(
        _core,
        planesArr,
        planes.length,
        width,
        height,
        format,
        timestampMs,
      );
    } finally {
      for (final p in planePtrs) {
        calloc.free(p);
      }
      calloc.free(planesArr);
    }
  }

  @override
  List<FrameData> takeCapturedFrames() {
    return _readFrames(_takeCaptured);
  }

  @override
  List<FrameData> takeCalibrationFrames() {
    return _readFrames(_takeCalibration);
  }

  List<FrameData> _readFrames(_TakeFramesDart take) {
    final countPtr = calloc<IntPtr>();
    final ptr = take(_core, countPtr);
    final count = countPtr.value;
    calloc.free(countPtr);
    if (ptr == nullptr || count == 0) return const [];

    final frames = <FrameData>[];
    try {
      for (var i = 0; i < count; i++) {
        final f = ptr[i];
        frames.add(FrameData(intensity: f.intensity, timestamp: f.timestampMs));
      }
    } finally {
      _free(ptr.cast<Void>());
    }
    return frames;
  }

  @override
  List<double> takeChart() {
    final countPtr = calloc<IntPtr>();
    final ptr = _takeChart(_core, countPtr);
    final count = countPtr.value;
    calloc.free(countPtr);
    if (ptr == nullptr || count == 0) return const [];

    final values = <double>[];
    try {
      for (var i = 0; i < count; i++) {
        values.add(ptr[i]);
      }
    } finally {
      _free(ptr.cast<Void>());
    }
    return values;
  }

  @override
  String get lastError => _lastError(_core).toDartString();

  @override
  void dispose() => _destroy(_core);
}

/// Locates the bundled native library across platforms.
DynamicLibrary _openLibrary() {
  const candidates = <String>[
    'libhrv4life_core.so',
    'hrv4life_core.dll',
    'libhrv4life_core.dylib',
    'libhrv4life_core.framework/libhrv4life_core',
    'hrv4life_core',
  ];

  for (final name in candidates) {
    try {
      return DynamicLibrary.open(name);
    } on ArgumentError {
      continue;
    }
  }

  // iOS static-lib case: symbols linked directly into the app binary.
  return DynamicLibrary.process();
}