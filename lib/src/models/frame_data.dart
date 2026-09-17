/// Data captured from a single camera frame.
class FrameData {
  /// Average intensity value from the Y plane.
  final double intensity;

  /// Timestamp when the frame was captured (milliseconds since epoch).
  final int timestamp;

  const FrameData({
    required this.intensity,
    required this.timestamp,
  });

  /// Converts to JSON for API submission.
  Map<String, dynamic> toJson() {
    return {
      'intensity': intensity,
      'timestamp': timestamp,
    };
  }
}
