import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../hrv_monitor_controller.dart';
import '../hrv_monitor_status.dart';
import '../hrv_monitor_value.dart';
import '../hrv_session.dart';
import 'hrv_chart_common.dart';

/// Live PPG signal intensity chart shown *during* a measurement.
///
/// Auto-binds to the controller currently registered in [HrvSession], so it
/// can be created with no arguments:
///
/// ```dart
/// const HrvLivePpgChart();
/// ```
///
/// Falls back to a waiting placeholder when no measurement is in progress.
class HrvLivePpgChart extends StatelessWidget {
  const HrvLivePpgChart({
    super.key,
    this.controller,
    this.title = 'Intensidade do sinal',
    this.waitingMessage = 'Aguardando leitura',
    this.height = 110,
  });

  /// Explicit controller to listen to (defaults to the session controller).
  final HrvMonitorController? controller;

  /// Header label.
  final String title;

  /// Message shown while there is no signal yet.
  final String waitingMessage;

  /// Height of the waveform area.
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HrvSession.instance,
      builder: (context, _) {
        final ctrl = controller ?? HrvSession.instance.activeController;
        if (ctrl == null) {
          return _buildShell(
            child: Center(
              child: Text(
                waitingMessage,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
          );
        }

        return ValueListenableBuilder<HrvMonitorValue>(
          valueListenable: ctrl,
          builder: (context, value, _) {
            final show = value.chartData.isNotEmpty &&
                (value.status == HrvMonitorStatus.measuring ||
                    value.status == HrvMonitorStatus.processing);

            return _buildShell(
              child: show
                  ? CustomPaint(
                      size: Size(double.infinity, height),
                      painter: _LiveWaveformPainter(
                        data: value.chartData,
                        color: HrvChartColors.primary,
                      ),
                    )
                  : Center(
                      child: Text(
                        waitingMessage,
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: HrvChartColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

/// Smoothed signal-intensity waveform with detected peaks.
class _LiveWaveformPainter extends CustomPainter {
  _LiveWaveformPainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.05), Colors.white],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.05)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    if (range == 0) return;

    final xStep = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height -
          (normalizedValue * size.height * 0.85) -
          (size.height * 0.075);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * xStep;
        final prevY = size.height -
            ((data[i - 1] - minValue) / range * size.height * 0.85) -
            (size.height * 0.075);
        final controlX = prevX + (x - prevX) / 2;
        path.quadraticBezierTo(controlX, prevY, x, y);
        fillPath.quadraticBezierTo(controlX, prevY, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final startPoint = data.length > 20 ? data.length - 20 : 0;
    for (int i = startPoint; i < data.length; i++) {
      var isPeak = false;
      if (i > 0 && i < data.length - 1) {
        if (data[i] > data[i - 1] && data[i] > data[i + 1]) {
          isPeak = true;
        }
      }
      if (isPeak) {
        final x = i * xStep;
        final normalizedValue = (data[i] - minValue) / range;
        final y = size.height -
            (normalizedValue * size.height * 0.85) -
            (size.height * 0.075);
        const pulseSize = 4.0;
        canvas.drawCircle(Offset(x, y), pulseSize, pointBorderPaint);
        canvas.drawCircle(Offset(x, y), pulseSize - 2, pointPaint);
      }
    }

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.2)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_LiveWaveformPainter old) =>
      old.color != color || !listEquals(old.data, data);
}