import 'package:flutter/material.dart';

/// Shared visual constants used across the SDK chart widgets.
///
/// Mirrors the palette of the official hrv4life app charts so widgets copied
/// into the SDK keep the same look without depending on an app theme.
abstract final class HrvChartColors {
  /// Brand primary orange.
  static const primary = Color(0xFFF37221);

  /// Secondary blue used by the RR tachogram.
  static const blue = Color(0xFF004E89);

  /// PPG line orange.
  static const orange = Color(0xFFFF6B35);

  /// PSD line dark green.
  static const psdLine = Color(0xFF1B5E20);

  /// VLF band purple.
  static const vlf = Color(0xFF9C27B0);

  /// LF band (brand orange).
  static const lf = Color(0xFFF37221);

  /// HF band blue.
  static const hf = Color(0xFF2196F3);

  /// Health gauge danger red.
  static const gaugeRed = Color(0xFFFF5252);

  /// Health gauge warning orange.
  static const gaugeOrange = Color(0xFFFF9800);

  /// Health gauge caution yellow.
  static const gaugeYellow = Color(0xFFFFC107);

  /// Health gauge healthy green.
  static const gaugeGreen = Color(0xFF4CAF50);
}

/// Placeholder shown by chart widgets when there is no data yet.
class HrvChartEmpty extends StatelessWidget {
  const HrvChartEmpty({
    super.key,
    required this.message,
    this.height = 200,
  });

  /// Message displayed in the middle of the placeholder.
  final String message;

  /// Height of the placeholder box.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ),
    );
  }
}