import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../hrv_session.dart';
import '../models/hrv_result.dart';
import 'hrv_chart_common.dart';

/// Bar chart representing VLF, LF and HF frequency band powers as
/// proportions of total power.
///
/// Auto-populates from the last measurement in [HrvSession] when created with
/// no arguments:
///
/// ```dart
/// const HrvFrequencySpectrumChart();
/// ```
///
/// [includeVlf] controls whether the VLF band is displayed. Defaults to
/// `false`, since the VLF component is inconsistent in short recordings
/// (e.g. 60s) and tends to mislead interpretation.
class HrvFrequencySpectrumChart extends StatelessWidget {
  const HrvFrequencySpectrumChart({
    super.key,
    this.result,
    this.vlfPower,
    this.lfPower,
    this.hfPower,
    this.includeVlf = false,
    this.height = 120,
  });

  /// Measurement to render when explicit values are not provided.
  final HrvResult? result;

  /// VLF band power override (ms²).
  final double? vlfPower;

  /// LF band power override (ms²).
  final double? lfPower;

  /// HF band power override (ms²).
  final double? hfPower;

  /// Whether the VLF band is displayed.
  final bool includeVlf;

  /// Height of the plot area (legends rendered below).
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HrvSession.instance,
      builder: (context, _) {
        final source = result ?? HrvSession.instance.lastResult;
        final fd = source?.metrics?.frequencyDomain;

        final vlf = includeVlf ? (vlfPower ?? fd?.vlf.power ?? 0) : 0.0;
        final lf = lfPower ?? fd?.lf.power ?? 0;
        final hf = hfPower ?? fd?.hf.power ?? 0;

        final total = vlf + lf + hf;
        if (total <= 0) return const SizedBox.shrink();

        final vlfPct = vlf / total;
        final lfPct = lf / total;
        final hfPct = hf / total;

        final textColor = Theme.of(context).textTheme.bodySmall?.color;

        final bars = <BarChartGroupData>[];
        final labels = <String>[];
        final legends = <Widget>[];
        if (includeVlf) {
          bars.add(_bar(0, vlfPct, HrvChartColors.vlf));
          labels.add('VLF');
          legends.add(_legend('VLF', HrvChartColors.vlf,
              '${(vlfPct * 100).round()}%'));
        }
        final lfIndex = includeVlf ? 1 : 0;
        final hfIndex = includeVlf ? 2 : 1;
        bars.add(_bar(lfIndex, lfPct, HrvChartColors.lf));
        bars.add(_bar(hfIndex, hfPct, HrvChartColors.hf));
        labels.addAll(['LF', 'HF']);
        legends.add(
            _legend('LF', HrvChartColors.lf, '${(lfPct * 100).round()}%'));
        legends.add(
            _legend('HF', HrvChartColors.hf, '${(hfPct * 100).round()}%'));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: height,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.0,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
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
                          if (value == 0 || value == 0.5 || value == 1.0) {
                            return Text(
                              '${(value * 100).round()}%',
                              style: TextStyle(fontSize: 9, color: textColor),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.25,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Theme.of(context).dividerColor.withAlpha(80),
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: bars,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: legends,
            ),
          ],
        );
      },
    );
  }

  BarChartGroupData _bar(int x, double pct, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: pct,
          color: color,
          width: 32,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 1.0,
            color: color.withAlpha(20),
          ),
        ),
      ],
    );
  }

  Widget _legend(String label, Color color, String pct) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label $pct',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}