import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../hrv_session.dart';
import '../models/hrv_result.dart';
import 'hrv_chart_common.dart';

/// Metric plotted by the trend charts.
enum HrvTrendMetric {
  /// Mean heart rate (BPM).
  heartRate,

  /// RMSSD (ms).
  rmssd,

  /// Stress index.
  stress,
}

/// Time-series line chart of a single HRV metric across stored measurements.
///
/// Auto-populates from the readings kept in [HrvSession] when created with no
/// arguments:
///
/// ```dart
/// const HrvTrendChart(metric: HrvTrendMetric.heartRate);
/// HrvHeartRateTrendChart(); // convenient wrapper
/// ```
///
/// The default window is the last 10 days; when [enableRangePicker] is `true`
/// the user can change it via a date-range picker.
class HrvTrendChart extends StatefulWidget {
  const HrvTrendChart({
    super.key,
    this.metric = HrvTrendMetric.heartRate,
    this.readings,
    this.title,
    this.subtitle,
    this.color,
    this.enableRangePicker = true,
    this.height = 160,
  });

  /// Metric to plot.
  final HrvTrendMetric metric;

  /// Explicit readings to plot. Defaults to `HrvSession.instance.readings`.
  final List<HrvReading>? readings;

  /// Card title. Defaults to the metric label.
  final String? title;

  /// Card subtitle. Defaults to "Últimos 10 dias".
  final String? subtitle;

  /// Line color. Defaults to the brand primary.
  final Color? color;

  /// Whether the date-range picker button is shown.
  final bool enableRangePicker;

  /// Height of the plot area.
  final double height;

  @override
  State<HrvTrendChart> createState() => _HrvTrendChartState();
}

class _HrvTrendChartState extends State<HrvTrendChart> {
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeEnd = DateTime(now.year, now.month, now.day);
    _rangeStart = _rangeEnd.subtract(const Duration(days: 9));
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: HrvChartColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (result != null && mounted) {
      setState(() {
        _rangeStart = result.start;
        _rangeEnd = result.end;
      });
    }
  }

  String get _title {
    if (widget.title != null) return widget.title!;
    switch (widget.metric) {
      case HrvTrendMetric.heartRate:
        return 'BPM';
      case HrvTrendMetric.rmssd:
        return 'RMSSD';
      case HrvTrendMetric.stress:
        return 'Estresse';
    }
  }

  IconData get _emptyIcon {
    switch (widget.metric) {
      case HrvTrendMetric.heartRate:
        return Icons.timeline_outlined;
      case HrvTrendMetric.rmssd:
        return Icons.show_chart;
      case HrvTrendMetric.stress:
        return Icons.psychology_outlined;
    }
  }

  double? _valueOf(HrvResult result) {
    final metrics = result.metrics;
    if (metrics == null) return null;
    switch (widget.metric) {
      case HrvTrendMetric.heartRate:
        final value = metrics.timeDomain.heartRate.meanHR;
        return value > 0 ? value : null;
      case HrvTrendMetric.rmssd:
        final value = metrics.timeDomain.variability.rmssd;
        return value > 0 ? value : null;
      case HrvTrendMetric.stress:
        final value = metrics.otherAnalysis.stress.index;
        return value > 0 ? value : null;
    }
  }

  List<HrvReading> get _filtered {
    final source = widget.readings ?? HrvSession.instance.readings;
    final start = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
    final end =
        DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day, 23, 59, 59);
    return source
        .where((r) =>
            !r.measuredAt.isBefore(start) && !r.measuredAt.isAfter(end))
        .where((r) => _valueOf(r.result) != null)
        .toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.cardColor;
    final border = theme.dividerColor.withValues(alpha: 0.5);
    final onSurface = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final grayText = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final color = widget.color ?? HrvChartColors.primary;

    return ListenableBuilder(
      listenable: HrvSession.instance,
      builder: (context, _) {
        final data = _filtered;

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle ?? 'Últimos 10 dias',
                          style: TextStyle(fontSize: 12, color: grayText),
                        ),
                      ],
                    ),
                  ),
                  if (widget.enableRangePicker)
                    GestureDetector(
                      onTap: _pickRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: HrvChartColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: HrvChartColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatRange(_rangeStart, _rangeEnd),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: HrvChartColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: widget.height,
                child: data.isEmpty
                    ? _buildEmptyState(onSurface, grayText)
                    : _buildChart(data, color, grayText),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(Color onSurface, Color grayText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_emptyIcon, size: 32, color: grayText),
          const SizedBox(height: 10),
          Text(
            'Sem histórico',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Faça sua primeira medição para ver o histórico',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: grayText),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<HrvReading> data, Color color, Color grayText) {
    final ref = data
        .map((r) => r.measuredAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    double toX(DateTime dt) => dt.difference(ref).inMicroseconds / 3600000000.0;

    final spots = <FlSpot>[
      for (final r in data) FlSpot(toX(r.measuredAt), _valueOf(r.result)!),
    ];

    final maxX = math.max(spots.map((s) => s.x).reduce(math.max), 1.0);
    final spanHours = maxX;
    final showHours = spanHours <= 24;
    final xMargin = math.max(0.5, maxX * 0.04);

    final dataMin = spots.map((s) => s.y).reduce(math.min);
    final dataMax = spots.map((s) => s.y).reduce(math.max);
    final padding = math.max(10.0, (dataMax - dataMin) / 5);
    final minY = math.max(0.0, dataMin - padding);
    final maxY = dataMax + padding;

    return LineChart(
      LineChartData(
        minX: -xMargin,
        maxX: maxX + xMargin,
        minY: minY,
        maxY: maxY,
        clipData: FlClipData.all(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: _niceHourInterval(spanHours),
              getTitlesWidget: (value, _) {
                final dt = ref
                    .add(Duration(milliseconds: (value * 3600000).round()));
                final label = showHours
                    ? '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
                    : '${dt.day}/${dt.month}';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 9, color: grayText),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRange(DateTime start, DateTime end) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(start.day)}/${two(start.month)} - ${two(end.day)}/${two(end.month)}';
  }
}

/// Trend chart for mean heart rate (BPM).
class HrvHeartRateTrendChart extends StatelessWidget {
  const HrvHeartRateTrendChart({
    super.key,
    this.readings,
    this.height = 160,
    this.enableRangePicker = true,
  });

  final List<HrvReading>? readings;
  final double height;
  final bool enableRangePicker;

  @override
  Widget build(BuildContext context) {
    return HrvTrendChart(
      metric: HrvTrendMetric.heartRate,
      readings: readings,
      height: height,
      enableRangePicker: enableRangePicker,
    );
  }
}

/// Trend chart for RMSSD.
class HrvRmssdTrendChart extends StatelessWidget {
  const HrvRmssdTrendChart({
    super.key,
    this.readings,
    this.height = 160,
    this.enableRangePicker = true,
  });

  final List<HrvReading>? readings;
  final double height;
  final bool enableRangePicker;

  @override
  Widget build(BuildContext context) {
    return HrvTrendChart(
      metric: HrvTrendMetric.rmssd,
      readings: readings,
      height: height,
      enableRangePicker: enableRangePicker,
    );
  }
}

/// Trend chart for the stress index.
class HrvStressTrendChart extends StatelessWidget {
  const HrvStressTrendChart({
    super.key,
    this.readings,
    this.height = 160,
    this.enableRangePicker = true,
  });

  final List<HrvReading>? readings;
  final double height;
  final bool enableRangePicker;

  @override
  Widget build(BuildContext context) {
    return HrvTrendChart(
      metric: HrvTrendMetric.stress,
      readings: readings,
      height: height,
      enableRangePicker: enableRangePicker,
    );
  }
}

double _niceHourInterval(double spanHours) {
  if (spanHours <= 0) return 1;
  final target = spanHours / 6;
  const steps = [1, 2, 3, 6, 12, 24, 48, 72, 168, 336, 720, 1440];
  for (final s in steps) {
    if (s >= target) return s.toDouble();
  }
  return (spanHours / 6).ceilToDouble();
}