import 'package:flutter/foundation.dart';
import 'hrv_summary.dart';
import 'hrv_quality.dart';
import 'hrv_metrics.dart';
import 'hrv_visualization.dart';

/// Result of an HRV measurement analysis.
@immutable
class HrvResult {
  final bool success;
  final String? message;
  final String? measurementId;
  final HrvSummary? summary;
  final HrvQuality? quality;
  final HrvMetrics? metrics;
  final HrvVisualization? visualization;
  final HrvTrainingReadiness? trainingReadiness;
  final HrvFeedbackMessages? feedbackMessages;
  final HrvRecoveryScore? recoveryScore;
  final HrvTrainingZones? trainingZones;
  final String? aiOpinion;

  const HrvResult({
    required this.success,
    this.message,
    this.measurementId,
    this.summary,
    this.quality,
    this.metrics,
    this.visualization,
    this.trainingReadiness,
    this.feedbackMessages,
    this.recoveryScore,
    this.trainingZones,
    this.aiOpinion,
  });

  factory HrvResult.fromJson(Map<String, dynamic> json) {
    try {
      final topLevelSuccess = json['success'] as bool? ?? false;
      final responseData = json['data'] as Map<String, dynamic>?;

      if (!topLevelSuccess || responseData == null) {
        return HrvResult(
          success: false,
          message: json['message'] as String? ?? 'Analysis failed',
          measurementId: responseData?['id'] as String?,
        );
      }

      final innerSuccess = responseData['success'] as bool? ?? false;
      if (!innerSuccess) {
        return HrvResult(
          success: false,
          message: json['message'] as String? ?? 'Analysis failed',
          measurementId: responseData['id'] as String?,
        );
      }

      final measurementId = responseData['id'] as String?;
      final actualData = responseData['data'] as Map<String, dynamic>? ?? {};

      return HrvResult(
        success: true,
        message: json['message'] as String?,
        measurementId: measurementId,
        summary: actualData['summary'] != null
            ? HrvSummary.fromJson(actualData['summary'] as Map<String, dynamic>)
            : null,
        quality: actualData['quality'] != null
            ? HrvQuality.fromJson(actualData['quality'] as Map<String, dynamic>)
            : null,
        metrics: actualData['metrics'] != null
            ? HrvMetrics.fromJson(actualData['metrics'] as Map<String, dynamic>)
            : null,
        visualization: actualData['visualization'] != null
            ? HrvVisualization.fromJson(
                actualData['visualization'] as Map<String, dynamic>)
            : null,
        // trainingReadiness moved into metrics.otherAnalysis (API-5); fall back to
        // old top-level key for responses from older API versions.
        trainingReadiness: _parseTrainingReadiness(actualData),
        feedbackMessages: actualData['feedbackMessages'] != null
            ? HrvFeedbackMessages.fromJson(
                actualData['feedbackMessages'] as Map<String, dynamic>)
            : null,
        recoveryScore: actualData['recoveryScore'] != null
            ? HrvRecoveryScore.fromJson(
                actualData['recoveryScore'] as Map<String, dynamic>)
            : null,
        trainingZones: actualData['trainingZones'] != null
            ? HrvTrainingZones.fromJson(
                actualData['trainingZones'] as Map<String, dynamic>)
            : null,
        aiOpinion: actualData['aiOpinion'] != null
            ? (actualData['aiOpinion'] as Map<String, dynamic>)['opinion'] as String?
            : null,
      );
    } catch (e) {
      return HrvResult(
        success: false,
        message: 'Failed to parse response: $e',
      );
    }
  }

  static HrvTrainingReadiness? _parseTrainingReadiness(Map<String, dynamic> data) {
    // New location: metrics.otherAnalysis.trainingReadiness (since API-5)
    final metricsJson = data['metrics'] as Map<String, dynamic>?;
    final otherJson = metricsJson?['otherAnalysis'] as Map<String, dynamic>?;
    final nested = otherJson?['trainingReadiness'] as Map<String, dynamic>?;
    if (nested != null) return HrvTrainingReadiness.fromJson(nested);
    // Fallback: old top-level location
    final topLevel = data['trainingReadiness'] as Map<String, dynamic>?;
    if (topLevel != null) return HrvTrainingReadiness.fromJson(topLevel);
    return null;
  }

  factory HrvResult.error(String message) {
    return HrvResult(
      success: false,
      message: message,
    );
  }

  Map<String, dynamic> toJson() {
    if (!success) {
      return {
        'data': {
          'success': false,
        },
        'message': message,
        'measurementId': measurementId,
      };
    }

    return {
      'data': {
        'success': true,
        'data': {
          'summary': summary?.toJson(),
          'quality': quality?.toJson(),
          'metrics': metrics?.toJson(),
          'visualization': visualization?.toJson(),
          'trainingReadiness': trainingReadiness?.toJson(),
          'feedbackMessages': feedbackMessages?.toJson(),
          'recoveryScore': recoveryScore?.toJson(),
          'trainingZones': trainingZones?.toJson(),
          if (aiOpinion != null) 'aiOpinion': {'opinion': aiOpinion},
        },
      },
      'message': message,
      'measurementId': measurementId,
    };
  }

  @override
  String toString() {
    if (!success) {
      return 'HrvResult(success: false, message: $message)';
    }
    final hr = metrics?.timeDomain.heartRate.meanHR;
    final rmssd = metrics?.timeDomain.variability.rmssd;
    return 'HrvResult(success: true, hr: $hr, rmssd: $rmssd)';
  }
}
