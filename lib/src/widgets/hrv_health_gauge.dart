import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../hrv_session.dart';
import '../models/hrv_result.dart';
import 'hrv_chart_common.dart';

/// Color for the gauge based on a normalized value (0.0 to 1.0).
Color _gaugeColor(double normalizedValue) {
  if (normalizedValue < 0.3) return HrvChartColors.gaugeRed;
  if (normalizedValue < 0.5) return HrvChartColors.gaugeOrange;
  if (normalizedValue < 0.7) return HrvChartColors.gaugeYellow;
  return HrvChartColors.gaugeGreen;
}

/// Standalone health gauge widget.
///
/// Auto-populates from the last measurement in [HrvSession] when created with
/// no arguments (score from `metrics.otherAnalysis.healthAlert.healthScore`,
/// classification from `healthAlert.riskClassification` / `aiOpinion`):
///
/// ```dart
/// const HrvHealthGauge();
/// ```
///
/// [healthScore] is provided by the API as 3-9 (3 = best, 9 = worst).
class HrvHealthGauge extends StatelessWidget {
  const HrvHealthGauge({
    super.key,
    this.result,
    this.healthScore,
    this.riskClassification,
    this.label = 'Score de Saúde',
  });

  /// Measurement to render when explicit values are not provided.
  final HrvResult? result;

  /// Health score override (3-9).
  final int? healthScore;

  /// Risk classification override.
  final String? riskClassification;

  /// Label rendered under the gauge score.
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HrvSession.instance,
      builder: (context, _) {
        final source = result ?? HrvSession.instance.lastResult;
        final alert = source?.metrics?.otherAnalysis.healthAlert;

        final score = healthScore ?? alert?.healthScore ?? 0;
        if (score <= 0) {
          return const _GaugeCard(
            child: HrvChartEmpty(message: 'Sem dados de score', height: 160),
          );
        }

        final rawRisk = riskClassification ??
            alert?.riskClassification ??
            source?.aiOpinion;
        final risk = (rawRisk == null || rawRisk.isEmpty) ? null : rawRisk;

        final rawScore = score.clamp(3, 9);
        // Convert to 0-100 scale (inverted: 3→100, 9→0).
        final score100 = ((9 - rawScore) / 6.0 * 100).round().clamp(0, 100);
        final normalized = score100 / 100.0;

        return _GaugeCard(
          child: Column(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: normalized),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, animValue, _) {
                    return CustomPaint(
                      painter: _GaugePainter(
                        normalizedValue: animValue,
                        score: score100,
                        label: label,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              if (risk != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _gaugeColor(normalized).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    risk,
                    style: TextStyle(
                      color: _gaugeColor(normalized),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.normalizedValue,
    required this.score,
    required this.label,
  });

  final double normalizedValue;
  final int score;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height * 0.7);
    final radius = math.min(size.width * 0.38, size.height * 0.55);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final zones = [
      (HrvChartColors.gaugeRed, 0.0, 0.3),
      (HrvChartColors.gaugeOrange, 0.3, 0.5),
      (HrvChartColors.gaugeYellow, 0.5, 0.7),
      (HrvChartColors.gaugeGreen, 0.7, 1.0),
    ];

    for (final (color, start, end) in zones) {
      canvas.drawArc(
        rect,
        math.pi + math.pi * start,
        math.pi * (end - start),
        false,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    final valueClamp = normalizedValue.clamp(0.0, 1.0);
    if (valueClamp > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * valueClamp,
        false,
        Paint()
          ..color = _gaugeColor(valueClamp)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    final needleAngle = math.pi * (1 + valueClamp);
    final needleLength = radius - strokeWidth - 6;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = const Color(0xFF424242)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF424242));

    final scoreText = TextPainter(
      text: TextSpan(
        text: '$score',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF424242),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    scoreText.layout();
    scoreText.paint(
      canvas,
      Offset(
        center.dx - scoreText.width / 2,
        center.dy - scoreText.height - 12,
      ),
    );

    final labelText = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
      ),
      textDirection: TextDirection.ltr,
    );
    labelText.layout();
    labelText.paint(
      canvas,
      Offset(center.dx - labelText.width / 2, center.dy + 8),
    );

    final minText = TextPainter(
      text: const TextSpan(
        text: '0',
        style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
      ),
      textDirection: TextDirection.ltr,
    );
    minText.layout();
    minText.paint(
      canvas,
      Offset(center.dx - radius - 4, center.dy + strokeWidth / 2 + 4),
    );

    final maxText = TextPainter(
      text: const TextSpan(
        text: '100',
        style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
      ),
      textDirection: TextDirection.ltr,
    );
    maxText.layout();
    maxText.paint(
      canvas,
      Offset(
        center.dx + radius - maxText.width + 4,
        center.dy + strokeWidth / 2 + 4,
      ),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.normalizedValue != normalizedValue ||
      old.score != score ||
      old.label != label;
}