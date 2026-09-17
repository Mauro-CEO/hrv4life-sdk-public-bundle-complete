import 'package:flutter/foundation.dart';

/// Measurement summary metadata.
@immutable
class HrvSummary {
  final double duration;
  final int beatsCount;
  final String readingType;
  final String deviceType;
  final String processedAt;
  final int processingTime;

  const HrvSummary({
    required this.duration,
    required this.beatsCount,
    required this.readingType,
    required this.deviceType,
    required this.processedAt,
    required this.processingTime,
  });

  factory HrvSummary.fromJson(Map<String, dynamic> json) {
    return HrvSummary(
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      beatsCount: json['beatsCount'] as int? ?? 0,
      readingType: json['readingType'] as String? ?? '',
      deviceType: json['deviceType'] as String? ?? '',
      processedAt: json['processedAt'] as String? ?? '',
      processingTime: json['processingTime'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'beatsCount': beatsCount,
      'readingType': readingType,
      'deviceType': deviceType,
      'processedAt': processedAt,
      'processingTime': processingTime,
    };
  }
}
