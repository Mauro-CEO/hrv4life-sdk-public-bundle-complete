import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../hrv_session.dart';
import '../models/hrv_result.dart';
import '../models/hrv_visualization.dart';
import 'hrv_chart_common.dart';

/// PPG signal chart.
///
/// Auto-populates from the last measurement in [HrvSession] when created with
/// no arguments:
///
/// ```dart
/// const HrvPpgChart(); // uses session.lastResult.visualization.ppgSignal
/// ```
///
/// Pass [ppgSignal] or [result] to render a specific measurement instead.
class HrvPpgChart extends StatelessWidget {
  const HrvPpgChart({
    super.key,
    this.ppgSignal,
    this.result,
    this.height = 200,
  });

  /// Explicit PPG signal to render (highest priority).
  final HrvPpgSignal? ppgSignal;

  /// Measurement to render when [ppgSignal] is not provided.
  final HrvResult? result;

  /// Height of the chart.
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HrvSession.instance,
      builder: (context, _) {
        final signal = ppgSignal ??
            result?.visualization?.ppgSignal ??
            HrvSession.instance.lastResult?.visualization?.ppgSignal;

        final filtered = signal?.filtered ?? const <double>[];
        final raw = signal?.raw ?? const <double>[];
        final data = filtered.isNotEmpty ? filtered : raw;

        if (data.isEmpty) {
          return HrvChartEmpty(message: 'Sem dados PPG', height: height);
        }

        final peaks = signal?.peaks ?? const <int>[];

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
              painter: _PpgChartPainter(
                values: data,
                lineColor: HrvChartColors.orange,
                fillColor: HrvChartColors.orange.withValues(alpha: 0.1),
                peaks: peaks.isNotEmpty ? peaks : null,
                yLabel: 'Amplitude',
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter that draws a single PPG line with optional detected peaks.
class _PpgChartPainter extends CustomPainter {
  _PpgChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    this.peaks,
    this.yLabel,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final List<int>? peaks;
  final String? yLabel;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const padding = EdgeInsets.fromLTRB(36, 12, 8, 20);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    double minVal = values.reduce(math.min);
    double maxVal = values.reduce(math.max);
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
    canvas.drawLine(
      Offset(padding.left, padding.top + chartHeight / 2),
      Offset(padding.left + chartWidth, padding.top + chartHeight / 2),
      gridPaint,
    );

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = padding.left + (i / (values.length - 1)) * chartWidth;
      final y = padding.top +
          chartHeight -
          ((values[i] - minVal) / (maxVal - minVal)) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
        fPath.moveTo(x, padding.top + chartHeight);
        fPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fPath.lineTo(x, y);
      }
    }

    fPath.lineTo(padding.left + chartWidth, padding.top + chartHeight);
    fPath.close();

    canvas.drawPath(fPath, fPaint);
    canvas.drawPath(path, linePaint);

    if (peaks != null && peaks!.isNotEmpty) {
      final peakPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      for (final peakIdx in peaks!) {
        if (peakIdx >= 0 && peakIdx < values.length) {
          final x =
              padding.left + (peakIdx / (values.length - 1)) * chartWidth;
          final y = padding.top +
              chartHeight -
              ((values[peakIdx] - minVal) / (maxVal - minVal)) * chartHeight;
          canvas.drawCircle(Offset(x, y), 3, peakPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PpgChartPainter old) =>
      old.lineColor != lineColor ||
      old.fillColor != fillColor ||
      old.yLabel != yLabel ||
      !listEquals(old.values, values) ||
      !listEquals(old.peaks, peaks);
}