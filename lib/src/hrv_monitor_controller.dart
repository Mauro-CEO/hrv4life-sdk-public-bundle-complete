import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'hrv_monitor_status.dart';
import 'hrv_monitor_value.dart';
import 'hrv_session.dart';
import 'models/hrv_config.dart';
import 'models/hrv_result.dart';
import 'models/frame_data.dart';
import 'internal/camera_service.dart';
import 'internal/api_service.dart';
import 'internal/hrv_core_backend.dart';

/// Simple i18n map for controller status messages.
const _messages = {
  'initializing': {'pt': 'Inicializando câmera...', 'en': 'Initializing camera...'},
  'ready': {'pt': 'Pronto para iniciar', 'en': 'Ready to start'},
  'cameraError': {'pt': 'Falha ao inicializar câmera', 'en': 'Failed to initialize camera'},
  'notInitialized': {'pt': 'Controller não inicializado', 'en': 'Controller not initialized'},
  'placeFinger': {'pt': 'Coloque o dedo na câmera', 'en': 'Place your finger on the camera'},
  'stopped': {'pt': 'Medição interrompida', 'en': 'Measurement stopped'},
  'paused': {'pt': 'Medição pausada. Coloque o dedo na câmera', 'en': 'Measurement paused. Place your finger on the camera'},
  'processing': {'pt': 'Processando dados...', 'en': 'Processing data...'},
  'noData': {'pt': 'Nenhum dado capturado', 'en': 'No data captured'},
  'completed': {'pt': 'Medição concluída', 'en': 'Measurement completed'},
  'analysisFailed': {'pt': 'Falha na análise', 'en': 'Analysis failed'},
  'processingFailed': {'pt': 'Falha ao processar dados', 'en': 'Failed to process data'},
  'measuring': {'pt': 'Medindo...', 'en': 'Measuring...'},
  'measuringCountdown': {'pt': 'Medindo... faltam %ds', 'en': 'Measuring... %ds remaining'},
  'fpsRejected': {'pt': 'FPS da câmera muito baixo. Tente novamente em melhor iluminação.', 'en': 'Camera FPS too low. Try again in better lighting.'},
};

/// Controller for HRV monitoring.
///
/// Follows the same pattern as [CameraController] and [VideoPlayerController].
/// Use [HrvCameraPreview] to display the camera preview.
///
/// The measurement state machine (finger detection, FPS validation,
/// PPG intensity extraction, invisible calibration and frame capture) runs in
/// the native `hrv4life_core` engine; this controller is the Dart
/// orchestration layer (UI/status, camera transport and API calls).
class HrvMonitorController extends ValueNotifier<HrvMonitorValue> {
  final String _apiKey;
  final String _patientKey;
  final HrvMonitorConfig _config;
  final String _locale;

  late final CameraService _cameraService;
  late final ApiService _apiService;
  late final HrvCoreBackend _core;

  /// Exposes the internal API service for group operations and other SDK features.
  ApiService get apiService => _apiService;

  Timer? _elapsedTimer;
  bool _isDisposed = false;
  bool _flashEnabled = true;

  /// Side-effect guards for engine state transitions.
  bool _completionHandled = false;
  bool _calibrationSignalSent = false;
  int _lastFrameCount = 0;

  /// Callback called when measurement completes with result.
  Function(HrvResult)? onResult;

  /// Callback called when an error occurs.
  Function(String)? onError;

  /// Callback called with signal quality suggestions during calibration.
  ///
  /// The consuming app can use this to provide TTS guidance or
  /// visual hints. The list contains Portuguese suggestions like
  /// "Pressione o dedo com mais firmeza sobre a câmera".
  /// This callback is only fired when signal quality needs improvement.
  Function(List<String> suggestions)? onSignalQualitySuggestion;

  /// Creates an HRV monitor controller.
  ///
  /// [apiKey] is the application token for API authentication (X-API-KEY header).
  /// [patientKey] is the patient token provided by the end user (X-Patient-Key header).
  /// [config] optionally customizes measurement parameters.
  /// [forceFakeCore] forces the pure-Dart engine backend (useful in tests
  /// or when the native library is not bundled).
  String _tr(String key) => _messages[key]?[_locale] ?? _messages[key]?['en'] ?? key;

  HrvMonitorController({
    required String apiKey,
    required String patientKey,
    HrvMonitorConfig? config,
    String locale = 'pt',
    bool forceFakeCore = false,
  })  : _apiKey = apiKey,
        _patientKey = patientKey,
        _config = config ?? const HrvMonitorConfig(),
        _locale = locale,
        super(const HrvMonitorValue()) {
    _cameraService = CameraService();
    _apiService = ApiService(
      apiKey: _apiKey,
      patientKey: _patientKey,
      baseUrl: _config.baseUrl,
      locale: locale,
    );
    _core = createHrvCoreBackend(config: _config, forceFake: forceFakeCore);

    // Make this controller the automatic data source for the SDK widgets.
    HrvSession.instance.activeController = this;
  }

  /// Whether the measurement engine runs natively (DLL/.so/.dylib).
  bool get usesNativeCore => _core.isAvailable;

  /// Returns the camera controller for preview widget.
  CameraController? get cameraController => _cameraService.controller;

  /// Initializes the controller.
  ///
  /// Automatically detects and configures the back camera.
  /// Must be called before [startMeasurement].
  Future<void> initialize() async {
    if (_isDisposed) return;

    _updateValue(
      status: HrvMonitorStatus.initializing,
      statusMessage: _tr('initializing'),
    );

    try {
      await _cameraService.initialize();
      _core.initialize();

      _updateValue(
        status: HrvMonitorStatus.ready,
        isInitialized: true,
        statusMessage: _tr('ready'),
      );
    } catch (e) {
      _handleError('${_tr('cameraError')}: $e');
    }
  }

  /// Starts HRV measurement.
  ///
  /// The controller must be initialized before calling this method.
  /// Set [enableFlash] to `false` to start without the camera flash.
  /// Defaults to `true`.
  void startMeasurement({bool enableFlash = true}) {
    if (_isDisposed) return;

    if (!value.isInitialized) {
      _handleError(_tr('notInitialized'));
      return;
    }

    if (value.isMeasuring) {
      return;
    }

    _flashEnabled = enableFlash;
    _completionHandled = false;
    _calibrationSignalSent = false;
    _lastFrameCount = 0;
    _core.startMeasure();

    _updateValue(
      status: HrvMonitorStatus.waitingForFinger,
      isMeasuring: true,
      isFingerDetected: false,
      progress: 0,
      elapsedSeconds: 0,
      statusMessage: _tr('placeFinger'),
      chartData: [],
      result: null,
      error: null,
    );

    _startCapture();
  }

  /// Stops the current measurement.
  ///
  /// Stops capture and turns off flash.
  /// Does NOT clear captured data (allows manual restart or analysis).
  void stopMeasurement() {
    if (_isDisposed) return;

    _cancelElapsedTimer();
    _core.stopMeasure();
    _stopCapture();

    if (value.isMeasuring ||
        value.status == HrvMonitorStatus.paused ||
        value.status == HrvMonitorStatus.waitingForFinger) {
      _updateValue(
        status: HrvMonitorStatus.ready,
        isMeasuring: false,
        isFingerDetected: false,
        statusMessage: _tr('stopped'),
      );
    }
  }

  /// Resets the controller to ready state.
  void reset() {
    if (_isDisposed) return;

    _cancelElapsedTimer();
    stopMeasurement();
    _core.reset();
    _completionHandled = false;
    _calibrationSignalSent = false;
    _lastFrameCount = 0;

    if (value.isInitialized) {
      _updateValue(
        status: HrvMonitorStatus.ready,
        isMeasuring: false,
        isFingerDetected: false,
        progress: 0,
        elapsedSeconds: 0,
        statusMessage: _tr('ready'),
        chartData: [],
        result: null,
        error: null,
      );
    }
  }

  void _startCapture() {
    if (_flashEnabled) {
      _cameraService.enableFlash();
    }
    _cameraService.startImageStream(_onImageAvailable);
  }

  Future<void> _stopCapture() async {
    // Disable flash FIRST (before stopping stream) to avoid race condition
    // where stopImageStream interferes with setFlashMode on some devices
    await _cameraService.disableFlash();
    await _cameraService.stopImageStream();
  }

  void _onImageAvailable(CameraImage image) {
    if (_isDisposed) return;

    if (!(value.isMeasuring ||
        value.status == HrvMonitorStatus.paused ||
        value.status == HrvMonitorStatus.waitingForFinger)) {
      return;
    }

    final planes = <Uint8List>[];
    final rowStrides = <int>[];
    final pixelStrides = <int>[];
    for (final plane in image.planes) {
      planes.add(plane.bytes);
      rowStrides.add(plane.bytesPerRow);
      pixelStrides.add(plane.bytesPerPixel ?? 1);
    }

    // iOS delivers NV12 (Y + interleaved UV); Android YUV420_888 gives 3 planes.
    final format = defaultTargetPlatform == TargetPlatform.iOS
        ? HrvCoreFormat.nv12
        : HrvCoreFormat.auto;

    _core.processFrame(
      planes: planes,
      rowStrides: rowStrides,
      pixelStrides: pixelStrides,
      width: image.width,
      height: image.height,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      format: format,
    );

    _syncFromCoreState(fromFrame: true);
  }

  /// Reads the engine state and drives the Dart UI / API side effects.
  void _syncFromCoreState({bool fromFrame = false}) {
    if (_isDisposed) return;

    final s = _core.getState();
    final status = s.status >= 0 && s.status < HrvMonitorStatus.values.length
        ? HrvMonitorStatus.values[s.status]
        : HrvMonitorStatus.ready;

    // Chart keeps the last 100 intensity points (engine captures one point
    // per accepted PPG frame; track via frame count).
    if (fromFrame && s.frameCount > _lastFrameCount) {
      _lastFrameCount = s.frameCount;
      final newChartData = List<double>.from(value.chartData);
      newChartData.add(s.lastIntensity);
      if (newChartData.length > 100) {
        newChartData.removeAt(0);
      }
      _updateValue(chartData: newChartData);
    }

    // Elapsed timer drives live UI updates while measuring.
    if (status == HrvMonitorStatus.measuring) {
      _ensureElapsedTimer();
    } else {
      _cancelElapsedTimer();
    }

    // Invisible calibration completed -> fire-and-forget signal check.
    if (s.calibrationReady && !_calibrationSignalSent) {
      _calibrationSignalSent = true;
      final frames = _core.takeCalibrationFrames();
      if (frames.isNotEmpty) {
        _performSignalCheck(frames);
      }
    }

    // Engine decided the measurement is over.
    if (status == HrvMonitorStatus.completed) {
      if (!_completionHandled) {
        _completionHandled = true;
        _completeMeasurement();
      }
      return;
    }

    // Engine rejected the stream quality (only surfaced for FPS errors).
    if (status == HrvMonitorStatus.error) {
      if (s.errorCode == HrvCoreErrorCode.fpsRejected) {
        _handleError(_tr('fpsRejected'));
      }
      return;
    }

    _updateValue(
      status: status,
      isInitialized: s.isInitialized || value.isInitialized,
      isMeasuring: s.isMeasuring,
      isFingerDetected: s.isFingerDetected,
      progress: s.progress,
      elapsedSeconds: s.elapsedSeconds,
      statusMessage: _statusMessageFor(status, s.elapsedSeconds),
      error: null,
    );
  }

  String _statusMessageFor(HrvMonitorStatus status, int elapsedSeconds) {
    switch (status) {
      case HrvMonitorStatus.ready:
        return _tr('ready');
      case HrvMonitorStatus.waitingForFinger:
        return _tr('placeFinger');
      case HrvMonitorStatus.measuring:
        final total = _config.measurementDuration.inSeconds;
        return _tr('measuringCountdown')
            .replaceAll('%d', '${(total - elapsedSeconds).clamp(0, total)}');
      case HrvMonitorStatus.paused:
        return _tr('paused');
      default:
        return value.statusMessage;
    }
  }

  void _ensureElapsedTimer() {
    if (_elapsedTimer != null) return;
    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_isDisposed) return;
        final s = _core.getState();
        if (HrvMonitorStatus.values[s.status] != HrvMonitorStatus.measuring) {
          _cancelElapsedTimer();
          return;
        }
        _updateValue(
          elapsedSeconds: s.elapsedSeconds,
          progress: s.progress,
          statusMessage:
              _statusMessageFor(HrvMonitorStatus.measuring, s.elapsedSeconds),
        );
      },
    );
  }

  void _cancelElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  /// Sends calibration frames to signal-check API.
  /// If quality needs improvement, fires [onSignalQualitySuggestion].
  /// Never blocks or interrupts measurement.
  Future<void> _performSignalCheck(List<FrameData> frames) async {
    try {
      final result = await _apiService.signalCheck(frames: frames);

      if (_isDisposed) return;

      // Only fire suggestion callback if quality needs improvement
      if (!result.acceptable && result.suggestions.isNotEmpty) {
        onSignalQualitySuggestion?.call(result.suggestions);
      } else if (result.quality == 'fair' && result.suggestions.isNotEmpty) {
        // Fair quality — still suggest improvements but don't alarm
        onSignalQualitySuggestion?.call(result.suggestions);
      }
    } catch (_) {
      // Silently ignore — never interrupt measurement
    }
  }

  Future<void> _completeMeasurement() async {
    _cancelElapsedTimer();
    await _stopCapture();

    _updateValue(
      status: HrvMonitorStatus.processing,
      isMeasuring: false,
      progress: 100,
      statusMessage: _tr('processing'),
    );

    final frames = _core.takeCapturedFrames();
    final measuredFps = _core.getState().measuredFps;

    if (frames.isEmpty) {
      _handleError(_tr('noData'));
      return;
    }

    try {
      final result = await _apiService.analyze(
        frames: frames,
        metadata: {
          'duration': _config.measurementDuration.inSeconds,
          'frameCount': frames.length,
          'measuredFps': measuredFps,
        },
      );

      if (_isDisposed) return;

      if (result.success) {
        _updateValue(
          status: HrvMonitorStatus.completed,
          result: result,
          statusMessage: _tr('completed'),
        );
        // Automatically publish the result so parameter-less widgets
        // (HrvHealthGauge, HrvPpgChart, trend charts, ...) can render it.
        HrvSession.instance.addResult(result);
        onResult?.call(result);
      } else {
        _handleError(_tr('analysisFailed'));
      }
    } catch (e) {
      _handleError('${_tr('processingFailed')}: $e');
    }
  }

  void _handleError(String message) {
    if (_isDisposed) return;

    _cancelElapsedTimer();
    _core.stopMeasure();
    _stopCapture();

    _updateValue(
      status: HrvMonitorStatus.error,
      isMeasuring: false,
      error: message,
      statusMessage: message,
    );

    onError?.call(message);
  }

  void _updateValue({
    HrvMonitorStatus? status,
    bool? isInitialized,
    bool? isMeasuring,
    bool? isFingerDetected,
    int? progress,
    int? elapsedSeconds,
    String? statusMessage,
    List<double>? chartData,
    HrvResult? result,
    String? error,
  }) {
    if (_isDisposed) return;

    value = value.copyWith(
      status: status,
      isInitialized: isInitialized,
      isMeasuring: isMeasuring,
      isFingerDetected: isFingerDetected,
      progress: progress,
      elapsedSeconds: elapsedSeconds,
      statusMessage: statusMessage,
      chartData: chartData,
      result: result,
      error: error,
    );
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _cancelElapsedTimer();
    _stopCapture();
    _core.dispose();
    _cameraService.dispose();
    _apiService.dispose();

    if (identical(HrvSession.instance.activeController, this)) {
      HrvSession.instance.activeController = null;
    }

    super.dispose();
  }
}