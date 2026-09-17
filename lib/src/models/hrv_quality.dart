import 'package:flutter/foundation.dart';

@immutable
class HrvQualityOverall {
  final String level;
  final double percentage;
  final String message;

  const HrvQualityOverall({
    required this.level,
    required this.percentage,
    required this.message,
  });

  factory HrvQualityOverall.fromJson(Map<String, dynamic> json) {
    return HrvQualityOverall(
      level: json['level'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'percentage': percentage,
      'message': message,
    };
  }
}

@immutable
class HrvQualitySignal {
  final double snr;
  final bool lowQuality;
  final int validFrames;
  final int totalFrames;

  const HrvQualitySignal({
    required this.snr,
    required this.lowQuality,
    required this.validFrames,
    required this.totalFrames,
  });

  factory HrvQualitySignal.fromJson(Map<String, dynamic> json) {
    return HrvQualitySignal(
      snr: (json['snr'] as num?)?.toDouble() ?? 0.0,
      lowQuality: json['lowQuality'] as bool? ?? false,
      validFrames: json['validFrames'] as int? ?? 0,
      totalFrames: json['totalFrames'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'snr': snr,
      'lowQuality': lowQuality,
      'validFrames': validFrames,
      'totalFrames': totalFrames,
    };
  }
}

@immutable
class HrvStationarity {
  final bool isStationary;
  final double meanDiffPercent;
  final double varDiffPercent;

  const HrvStationarity({
    required this.isStationary,
    required this.meanDiffPercent,
    required this.varDiffPercent,
  });

  factory HrvStationarity.fromJson(Map<String, dynamic> json) {
    return HrvStationarity(
      isStationary: json['isStationary'] as bool? ?? true,
      meanDiffPercent: (json['meanDiffPercent'] as num?)?.toDouble() ?? 0.0,
      varDiffPercent: (json['varDiffPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isStationary': isStationary,
      'meanDiffPercent': meanDiffPercent,
      'varDiffPercent': varDiffPercent,
    };
  }
}

@immutable
class HrvQualityArtifacts {
  final int total;
  final double percentage;
  final int possibleEctopics;
  final String dataQuality;

  const HrvQualityArtifacts({
    required this.total,
    required this.percentage,
    required this.possibleEctopics,
    required this.dataQuality,
  });

  factory HrvQualityArtifacts.fromJson(Map<String, dynamic> json) {
    return HrvQualityArtifacts(
      total: json['total'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      possibleEctopics: json['possibleEctopics'] as int? ?? 0,
      dataQuality: json['dataQuality'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'percentage': percentage,
      'possibleEctopics': possibleEctopics,
      'dataQuality': dataQuality,
    };
  }
}

@immutable
class HrvQuality {
  final HrvQualityOverall overall;
  final HrvQualitySignal signal;
  final HrvStationarity stationarity;
  final HrvQualityArtifacts artifacts;

  const HrvQuality({
    required this.overall,
    required this.signal,
    required this.stationarity,
    required this.artifacts,
  });

  factory HrvQuality.fromJson(Map<String, dynamic> json) {
    return HrvQuality(
      overall: HrvQualityOverall.fromJson(
          json['overall'] as Map<String, dynamic>? ?? {}),
      signal: HrvQualitySignal.fromJson(
          json['signal'] as Map<String, dynamic>? ?? {}),
      stationarity: HrvStationarity.fromJson(
          json['stationarity'] as Map<String, dynamic>? ?? {}),
      artifacts: HrvQualityArtifacts.fromJson(
          json['artifacts'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall.toJson(),
      'signal': signal.toJson(),
      'stationarity': stationarity.toJson(),
      'artifacts': artifacts.toJson(),
    };
  }
}
