import 'package:flutter/foundation.dart';

import 'hrv_monitor_status.dart';
import 'models/hrv_result.dart';

/// Immutable value representing the current state of the HRV monitor.
@immutable
class HrvMonitorValue {
  /// Current status of the monitor.
  final HrvMonitorStatus status;

  /// Whether the controller has been initialized.
  final bool isInitialized;

  /// Whether a measurement is currently in progress.
  final bool isMeasuring;

  /// Whether a finger is currently detected on the camera.
  final bool isFingerDetected;

  /// Progress of the current measurement (0-100).
  final int progress;

  /// Elapsed seconds since measurement started.
  final int elapsedSeconds;

  /// Human-readable status message.
  final String statusMessage;

  /// Last 100 intensity points for chart visualization.
  final List<double> chartData;

  /// Result of the measurement (available when status is completed).
  final HrvResult? result;

  /// Error message (available when status is error).
  final String? error;

  const HrvMonitorValue({
    this.status = HrvMonitorStatus.uninitialized,
    this.isInitialized = false,
    this.isMeasuring = false,
    this.isFingerDetected = false,
    this.progress = 0,
    this.elapsedSeconds = 0,
    this.statusMessage = '',
    this.chartData = const [],
    this.result,
    this.error,
  });

  /// Creates a copy with modified values.
  HrvMonitorValue copyWith({
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
    return HrvMonitorValue(
      status: status ?? this.status,
      isInitialized: isInitialized ?? this.isInitialized,
      isMeasuring: isMeasuring ?? this.isMeasuring,
      isFingerDetected: isFingerDetected ?? this.isFingerDetected,
      progress: progress ?? this.progress,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      statusMessage: statusMessage ?? this.statusMessage,
      chartData: chartData ?? this.chartData,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'HrvMonitorValue('
        'status: $status, '
        'isInitialized: $isInitialized, '
        'isMeasuring: $isMeasuring, '
        'fingerDetected: $isFingerDetected, '
        'progress: $progress%, '
        'elapsed: ${elapsedSeconds}s, '
        'chartPoints: ${chartData.length}, '
        'hasResult: ${result != null}, '
        'error: ${error != null}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HrvMonitorValue) return false;
    return status == other.status &&
        isInitialized == other.isInitialized &&
        isMeasuring == other.isMeasuring &&
        isFingerDetected == other.isFingerDetected &&
        progress == other.progress &&
        elapsedSeconds == other.elapsedSeconds &&
        statusMessage == other.statusMessage &&
        listEquals(chartData, other.chartData) &&
        result == other.result &&
        error == other.error;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      isInitialized,
      isMeasuring,
      isFingerDetected,
      progress,
      elapsedSeconds,
      statusMessage,
      Object.hashAll(chartData),
      result,
      error,
    );
  }
}
