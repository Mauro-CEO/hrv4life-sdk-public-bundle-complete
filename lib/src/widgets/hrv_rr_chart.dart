import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../hrv_session.dart';
import '../models/hrv_result.dart';
import '../models/hrv_visualization.dart';
import 'hrv_chart_common.dart';

/// RR interval tachogram chart (raw RR intervals + smoothed trend).
///
/// Auto-populates from the last measurement in [HrvSession] when created with
/// no arguments:
///
/// ```dart
/// const HrvRrTachogramChart();
/// ```
class HrvRrTachogramChart extends StatelessWidget {
  const HrvRrTachogramChart({
    super.key,
    this.tachogram,
    this.result,
    this.height = 200,
  });

  /// Explicit tachogram to render (highest priority).
  final HrvRRTachogram? tachogram;

  /// Measurement to render when [tachogram] is not provided.
  final HrvResult? result;

  /// Height of the chart.
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HrvSession.instance,
      builder: (context, _) {
        final data = tachogram ??
            result?.visualization?.rrTachogram ??
            HrvSession.instance.lastResult?.visualization?.rrTachogram;

        final rrIntervals = data?.rrIntervals ?? const <double>[];
        final smoothed = data?.smoothed ?? const <double>[];

        if (rrIntervals.isEmpty) {
          return HrvChartEmpty(message: 'Sem dados RR', height: height);
        }

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
              painter: _TachogramPainter(
                values1: rrIntervals,
                values2: smoothed,
                color1: HrvChartColors.blue,
                color2: HrvChartColors.orange,
                label1: 'RR',
                label2: 'Suavizado',
                yLabel: 'ms',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TachogramPainter extends CustomPainter {
  _TachogramPainter({
    required this.values1,
    required this.values2,
    required this.color1,
    required this.color2,
    required this.label1,
    required this.label2,
    this.yLabel,
  });

  final List<double> values1;
  final List<double> values2;
  final Color color1;
  final Color color2;
  final String label1;
  final String label2;
  final String? yLabel;

  @override
  void paint(Canvas canvas, Size size) {
    if (values1.isEmpty) return;

    const padding = EdgeInsets.fromLTRB(36, 28, 8, 20);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    final all = [...values1, ...values2];
    double minVal = all.reduce(math.min);
    double maxVal = all.reduce(math.max);
    if (maxVal == minVal) maxVal = minVal + 1;

    final labelStyle = TextStyle(fontSize: 9, color: Colors.grey[500]);
    final maxLabel = TextPainter(
      text: TextSpan(text: maxVal.toStringAsFixed(0), style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    maxLabel.layout();
    maxLabel.paint(
      canvas,
      Offset(padding.left - maxLabel.width - 4, padding.top - 4),
    );

    final minLabel = TextPainter(
      text: TextSpan(text: minVal.toStringAsFixed(0), style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    minLabel.layout();
    minLabel.paint(
      canvas,
      Offset(
        padding.left - minLabel.width - 4,
        padding.top + chartHeight - 4,
      ),
    );

    if (yLabel != null) {
      final unitLabel = TextPainter(
        text: TextSpan(text: yLabel, style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      unitLabel.layout();
      canvas.save();
      canvas.translate(
        8,
        padding.top + chartHeight / 2 + unitLabel.width / 2,
      );
      canvas.rotate(-math.pi / 2);
      unitLabel.paint(canvas, Offset.zero);
      canvas.restore();
    }

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

    void drawLine(List<double> vals, Color color) {
      if (vals.isEmpty) return;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < vals.length; i++) {
        final x = padding.left + (i / (vals.length - 1)) * chartWidth;
        final y = padding.top +
            chartHeight -
            ((vals[i] - minVal) / (maxVal - minVal)) * chartHeight;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawLine(values1, color1);
    drawLine(values2, color2);

    final textStyle = TextStyle(fontSize: 10, color: Colors.grey[700]);
    _drawLegend(canvas, padding.left + 4, 6, label1, color1, textStyle);
    _drawLegend(canvas, padding.left + 60, 6, label2, color2, textStyle);
  }

  void _drawLegend(
    Canvas canvas,
    double x,
    double y,
    String label,
    Color color,
    TextStyle style,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 2, 14, 8),
        const Radius.circular(2),
      ),
      Paint()..color = color,
    );
    final tp = TextPainter(
      text: TextSpan(text: ' $label', style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x + 16, y));
  }

  @override
  bool shouldRepaint(_TachogramPainter old) =>
      old.color1 != color1 ||
      old.color2 != color2 ||
      old.label1 != label1 ||
      old.label2 != label2 ||
      old.yLabel != yLabel ||
      !listEquals(old.values1, values1) ||
      !listEquals(old.values2, values2);
}