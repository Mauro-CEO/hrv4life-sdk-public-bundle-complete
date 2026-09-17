import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../hrv_session.dart';
import '../models/hrv_result.dart';
import 'hrv_chart_common.dart';

/// Power Spectral Density (PSD) line chart with highlighted frequency bands.
///
/// Auto-populates from the last measurement in [HrvSession] when created with
/// no arguments:
///
/// ```dart
/// const HrvPsdChart();
/// ```
///
/// Accepts either raw PSD data ([psdPoints] as `[frequency, power]` pairs) or
/// falls back to a synthetic curve built from the band powers.
class HrvPsdChart extends StatelessWidget {
  const HrvPsdChart({
    super.key,
    this.result,
    this.psdPoints,
    this.vlfPower,
    this.lfPower,
    this.hfPower,
    this.includeVlf = false,
    this.height = 160,
  });

  /// Measurement to render when explicit values are not provided.
  final HrvResult? result;

  /// Optional raw PSD data as list of `[frequency, power]` pairs.
  final List<List<double>>? psdPoints;

  /// VLF band power override (ms²).
  final double? vlfPower;

  /// LF band power override (ms²).
  final double? lfPower;

  /// HF band power override (ms²).
  final double? hfPower;

  /// Whether the VLF component is included in the synthetic curve.
  final bool includeVlf;

  /// Height of the chart.
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HrvSession.instance,
      builder: (context, _) {
        final source = result ?? HrvSession.instance.lastResult;
        final fd = source?.metrics?.frequencyDomain;

        final effectiveVlf = vlfPower ?? fd?.vlf.power ?? 0;
        final effectiveLf = lfPower ?? fd?.lf.power ?? 0;
        final effectiveHf = hfPower ?? fd?.hf.power ?? 0;
        final raw = psdPoints ?? fd?.psdData;

        final points = raw ?? _syntheticPoints(
          vlfPower: effectiveVlf,
          lfPower: effectiveLf,
          hfPower: effectiveHf,
          includeVlf: includeVlf,
        );
        if (points.isEmpty) return const SizedBox.shrink();

        final maxX = math.max(
          0.4,
          points.map((p) => p[0]).fold<double>(0, math.max) * 1.05,
        );
        final maxY = points.map((p) => p[1]).fold<double>(0, math.max) * 1.15;

        final textColor = Theme.of(context).textTheme.bodySmall?.color;

        return SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              minX: 0,
              maxX: maxX,
              clipData: const FlClipData.all(),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '${s.x.toStringAsFixed(3)} Hz\n${s.y.toStringAsFixed(1)} ms²/Hz',
                            const TextStyle(fontSize: 10, color: Colors.white),
                          ))
                      .toList(),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 0.1,
                    getTitlesWidget: (value, _) {
                      if (value == 0) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(fontSize: 9, color: textColor),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, _) {
                      if (value == 0 || value == maxY) return const SizedBox();
                      return Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(fontSize: 9, color: textColor),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context).dividerColor.withAlpha(60),
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  VerticalLine(
                    x: 0.15,
                    color: Colors.grey.withAlpha(100),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                    label: VerticalLineLabel(
                      show: true,
                      alignment: Alignment.topCenter,
                      style: const TextStyle(fontSize: 8, color: Colors.grey),
                      labelResolver: (_) => '0.15',
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: points.map((p) => FlSpot(p[0], p[1])).toList(),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: HrvChartColors.psdLine,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        HrvChartColors.psdLine.withAlpha(30),
                        HrvChartColors.psdLine.withAlpha(5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a synthetic PSD curve from band powers using Gaussian-shaped
  /// peaks centred at typical LF/HF frequencies. Used when the backend
  /// doesn't provide raw PSD point data.
  static List<List<double>> _syntheticPoints({
    required double vlfPower,
    required double lfPower,
    required double hfPower,
    required bool includeVlf,
  }) {
    final total = vlfPower + lfPower + hfPower;
    if (total <= 0) return [];

    final points = <List<double>>[];
    const step = 0.005;

    for (double f = 0.005; f <= 0.45; f += step) {
      double psd = 0;

      if (includeVlf && vlfPower > 0) {
        psd += _gaussian(f, 0.02, 0.012) * vlfPower * 18;
      }
      if (lfPower > 0) {
        psd += _gaussian(f, 0.09, 0.035) * lfPower * 14;
      }
      if (hfPower > 0) {
        psd += _gaussian(f, 0.25, 0.055) * hfPower * 12;
      }

      points.add([f, psd]);
    }

    return points;
  }

  static double _gaussian(double x, double center, double width) {
    return math.exp(-math.pow((x - center) / width, 2).toDouble());
  }
}