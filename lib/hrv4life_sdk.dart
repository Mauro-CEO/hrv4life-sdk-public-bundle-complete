/// HRV4Life SDK - Flutter package for HRV monitoring using camera PPG.
///
/// This package provides a simple API for measuring Heart Rate Variability (HRV)
/// using the device's camera and flash as a PPG sensor.
///
/// ## Usage
///
/// ```dart
/// import 'package:hrv4life_sdk/hrv4life_sdk.dart';
///
/// // Create controller
/// final controller = HrvMonitorController(
///   apiKey: 'your-api-key',
///   patientKey: 'patient-key',
/// );
///
/// // Initialize
/// await controller.initialize();
///
/// // Start measurement
/// controller.startMeasurement();
///
/// // Listen to state changes
/// ValueListenableBuilder<HrvMonitorValue>(
///   valueListenable: controller,
///   builder: (context, value, _) {
///     return Text(value.statusMessage);
///   },
/// );
///
/// // Display camera preview
/// HrvCameraPreview(controller: controller);
/// ```
library;

// Public API exports
export 'src/hrv_monitor_controller.dart';
export 'src/hrv_monitor_value.dart';
export 'src/hrv_monitor_status.dart';
export 'src/hrv_camera_preview.dart';
export 'src/hrv_session.dart';
export 'src/models/hrv_result.dart';
export 'src/models/hrv_config.dart';
export 'src/models/hrv_metrics.dart';
export 'src/models/hrv_summary.dart';
export 'src/models/hrv_quality.dart';
export 'src/models/hrv_visualization.dart';
export 'src/models/hrv_group.dart';
export 'src/models/hrv_interpretations.dart';
export 'src/internal/api_service.dart';

// Chart widgets (auto-populate from HrvSession when created with no params).
export 'src/widgets/hrv_chart_common.dart';
export 'src/widgets/hrv_ppg_chart.dart';
export 'src/widgets/hrv_rr_chart.dart';
export 'src/widgets/hrv_poincare_chart.dart';
export 'src/widgets/hrv_psd_chart.dart';
export 'src/widgets/hrv_frequency_spectrum_chart.dart';
export 'src/widgets/hrv_health_gauge.dart';
export 'src/widgets/hrv_trend_chart.dart';
export 'src/widgets/hrv_live_ppg_chart.dart';
