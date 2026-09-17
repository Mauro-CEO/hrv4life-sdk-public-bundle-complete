import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../hrv_session.dart';
import '../models/hrv_result.dart';
import '../models/hrv_visualization.dart';
import 'hrv_chart_common.dart';

/// Poincaré scatter plot with the SD1/SD2 ellipse.
///
/// Auto-populates from the last measurement in [HrvSession] when created with
/// no arguments (points from `visualization.poincareData`, SD1/SD2 from
/// `metrics.nonlinear.poincare`):
///
/// ```dart
/// const HrvPoincareChart();
/// ```
class HrvPoincareChart extends StatelessWidget {
  const HrvPoincareChart({
    super.key,
    this.poincareData,
    this.result,
    this.sd1,
    this.sd2,
    this.height = 260,
  });

  /// Explicit points to render (highest priority).
  final HrvPoincareData? poincareData;

  /// Measurement to render when [poincareData] is not provided.
  final HrvResult? result;

  /// SD1 override. Defaults to `result.metrics.nonlinear.poincare.sd1`.
  final double? sd1;

  /// SD2 override. Defaults to `result.metrics.nonlinear.poincare.sd2`.
  final double? sd2;

  /// Height of the chart.
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HrvSession.instance,
      builder: (context, _) {
        final source = result ?? HrvSession.instance.lastResult;
        final data = poincareData ??
            source?.visualization?.poincareData ??
            HrvSession.instance.lastResult?.visualization?.poincareData;
        final points = data?.points ?? const <HrvPoincarePoint>[];

        if (points.isEmpty) {
          return HrvChartEmpty(message: 'Sem dados Poincaré', height: height);
        }

        final effectiveSd1 = sd1 ??
            source?.metrics?.nonlinear.poincare.sd1 ??
            0.0;
        final effectiveSd2 = sd2 ??
            source?.metrics?.nonlinear.poincare.sd2 ??
            0.0;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              size: Size(double.infinity, height),
              painter: _PoincarePainter(
                points: points,
                sd1: effectiveSd1,
                sd2: effectiveSd2,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PoincarePainter extends CustomPainter {
  _PoincarePainter({
    required this.points,
    required this.sd1,
    required this.sd2,
  });

  final List<HrvPoincarePoint> points;
  final double sd1;
  final double sd2;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const padding = EdgeInsets.fromLTRB(32, 16, 16, 28);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    final xs = points.map((p) => p.x).toList();
    final ys = points.map((p) => p.y).toList();
    double minVal = math.min(xs.reduce(math.min), ys.reduce(math.min));
    double maxVal = math.max(xs.reduce(math.max), ys.reduce(math.max));
    if (maxVal == minVal) maxVal = minVal + 1;
    final range = maxVal - minVal;

    final scaleX = chartWidth / range;
    final scaleY = chartHeight / range;

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(padding.left, padding.top),
      Offset(padding.left, padding.top + chartHeight),
      gridPaint,
    );
    canvas.drawLine(
      Offset(padding.left, padding.top + chartHeight),
      Offset(padding.left + chartWidth, padding.top + chartHeight),
      gridPaint,
    );

    canvas.drawLine(
      Offset(padding.left, padding.top + chartHeight),
      Offset(padding.left + chartWidth, padding.top),
      Paint()
        ..color = Colors.grey[400]!
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    if (sd1 > 0 && sd2 > 0) {
      final meanX = xs.reduce((a, b) => a + b) / xs.length;
      final meanY = ys.reduce((a, b) => a + b) / ys.length;

      final cx = padding.left + ((meanX - minVal) / range) * chartWidth;
      final cy =
          padding.top + chartHeight - ((meanY - minVal) / range) * chartHeight;

      final sd2Px = sd2 * (scaleX + scaleY) / 2;
      final sd1Px = sd1 * (scaleX + scaleY) / 2;

      final ellipseFillPaint = Paint()
        ..color = const Color(0xFF2196F3).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;

      final ellipseStrokePaint = Paint()
        ..color = const Color(0xFF2196F3).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(-math.pi / 4);

      final ellipseRect = Rect.fromCenter(
        center: Offset.zero,
        width: sd2Px * 2,
        height: sd1Px * 2,
      );

      canvas.drawOval(ellipseRect, ellipseFillPaint);
      canvas.drawOval(ellipseRect, ellipseStrokePaint);

      final axisPaint = Paint()
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      axisPaint.color = const Color(0xFFE53935).withValues(alpha: 0.7);
      canvas.drawLine(Offset(-sd2Px, 0), Offset(sd2Px, 0), axisPaint);

      axisPaint.color = const Color(0xFF1E88E5).withValues(alpha: 0.7);
      canvas.drawLine(Offset(0, -sd1Px), Offset(0, sd1Px), axisPaint);

      canvas.restore();

      final sd1LabelStyle = const TextStyle(
        fontSize: 9,
        color: Color(0xFF1E88E5),
        fontWeight: FontWeight.w600,
      );
      final sd2LabelStyle = const TextStyle(
        fontSize: 9,
        color: Color(0xFFE53935),
        fontWeight: FontWeight.w600,
      );

      final sd2LabelOffset = Offset(
        cx + sd2Px * math.cos(math.pi / 4) + 4,
        cy - sd2Px * math.sin(math.pi / 4) - 12,
      );
      final sd2Label = TextPainter(
        text: TextSpan(text: 'SD2', style: sd2LabelStyle),
        textDirection: TextDirection.ltr,
      );
      sd2Label.layout();
      sd2Label.paint(canvas, sd2LabelOffset);

      final sd1LabelOffset = Offset(
        cx - sd1Px * math.cos(math.pi / 4) - 22,
        cy - sd1Px * math.sin(math.pi / 4) - 4,
      );
      final sd1Label = TextPainter(
        text: TextSpan(text: 'SD1', style: sd1LabelStyle),
        textDirection: TextDirection.ltr,
      );
      sd1Label.layout();
      sd1Label.paint(canvas, sd1LabelOffset);
    }

    final dotPaint = Paint()
      ..color = HrvChartColors.orange.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    for (final pt in points) {
      final x = padding.left + ((pt.x - minVal) / range) * chartWidth;
      final y =
          padding.top + chartHeight - ((pt.y - minVal) / range) * chartHeight;
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }

    final labelStyle = TextStyle(fontSize: 10, color: Colors.grey[600]);

    final xLabel = TextPainter(
      text: TextSpan(text: 'RR(n) ms', style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    xLabel.layout();
    xLabel.paint(
      canvas,
      Offset(
        padding.left + chartWidth / 2 - xLabel.width / 2,
        size.height - 14,
      ),
    );

    final yLabel = TextPainter(
      text: TextSpan(text: 'RR(n+1) ms', style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    yLabel.layout();
    canvas.save();
    canvas.translate(10, padding.top + chartHeight / 2 + yLabel.width / 2);
    canvas.rotate(-math.pi / 2);
    yLabel.paint(canvas, Offset.zero);
    canvas.restore();

    final minLabel = TextPainter(
      text: TextSpan(text: minVal.toStringAsFixed(0), style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    minLabel.layout();
    minLabel.paint(
      canvas,
      Offset(padding.left, padding.top + chartHeight + 4),
    );

    final maxLabel = TextPainter(
      text: TextSpan(text: maxVal.toStringAsFixed(0), style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    maxLabel.layout();
    maxLabel.paint(
      canvas,
      Offset(
        padding.left + chartWidth - maxLabel.width,
        padding.top + chartHeight + 4,
      ),
    );

    final yMaxLabel = TextPainter(
      text: TextSpan(text: maxVal.toStringAsFixed(0), style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    yMaxLabel.layout();
    yMaxLabel.paint(
      canvas,
      Offset(padding.left - yMaxLabel.width - 4, padding.top - 4),
    );

    final yMinLabel = TextPainter(
      text: TextSpan(text: minVal.toStringAsFixed(0), style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    yMinLabel.layout();
    yMinLabel.paint(
      canvas,
      Offset(
        padding.left - yMinLabel.width - 4,
        padding.top + chartHeight - 4,
      ),
    );
  }

  @override
  bool shouldRepaint(_PoincarePainter old) =>
      old.sd1 != sd1 ||
      old.sd2 != sd2 ||
      !listEquals(old.points, points);
}