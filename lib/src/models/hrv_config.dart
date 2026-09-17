/// Preset measurement durations.
enum HrvMeasurementDuration {
  oneMinute(Duration(minutes: 1)),
  threeMinutes(Duration(minutes: 3)),
  fiveMinutes(Duration(minutes: 5)),
  tenMinutes(Duration(minutes: 10)),

  /// Runs until manually stopped.
  indefinite(Duration(days: 365));

  const HrvMeasurementDuration(this.duration);
  final Duration duration;
}

/// Configuration for HRV measurement.
class HrvMonitorConfig {
  /// Duration of the measurement.
  final Duration measurementDuration;

  /// Minimum luminance value indicating finger presence (default: 50).
  final int minFingerLuminance;

  /// Maximum luminance value indicating finger presence (default: 95).
  final int maxFingerLuminance;

  /// Base URL for the API.
  /// Defaults to production: 'https://api.hrv4life.com/api'.
  /// For local Docker testing, use 'http://localhost:3000/api' (iOS simulator)
  /// or 'http://10.0.2.2:3000/api' (Android emulator).
  final String? baseUrl;

  const HrvMonitorConfig({
    this.measurementDuration = const Duration(minutes: 3),
    this.minFingerLuminance = 50,
    this.maxFingerLuminance = 95,
    this.baseUrl,
  });

  /// Creates a copy with modified values.
  HrvMonitorConfig copyWith({
    Duration? measurementDuration,
    int? minFingerLuminance,
    int? maxFingerLuminance,
    String? baseUrl,
  }) {
    return HrvMonitorConfig(
      measurementDuration: measurementDuration ?? this.measurementDuration,
      minFingerLuminance: minFingerLuminance ?? this.minFingerLuminance,
      maxFingerLuminance: maxFingerLuminance ?? this.maxFingerLuminance,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}
