import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'hrv_monitor_controller.dart';
import 'hrv_monitor_status.dart';

/// Widget that displays the camera preview for HRV measurement.
///
/// Requires an initialized [HrvMonitorController].
class HrvCameraPreview extends StatelessWidget {
  /// The controller managing the HRV measurement.
  final HrvMonitorController controller;

  /// Width of the preview. Defaults to 150.
  final double width;

  /// Height of the preview. Defaults to 150.
  final double height;

  /// Border radius of the preview. Defaults to 75 (circular).
  final double borderRadius;

  /// Widget to show when camera is not initialized.
  final Widget? placeholder;

  /// Whether to show finger detection indicator. Defaults to true.
  final bool showFingerIndicator;

  const HrvCameraPreview({
    super.key,
    required this.controller,
    this.width = 150,
    this.height = 150,
    this.borderRadius = 75,
    this.placeholder,
    this.showFingerIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        final cameraController = controller.cameraController;

        if (!value.isInitialized || cameraController == null || !cameraController.value.isInitialized) {
          return _buildPlaceholder();
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: SizedBox(
                width: width,
                height: height,
                child: _buildCameraPreview(cameraController),
              ),
            ),
            if (showFingerIndicator) _buildFingerIndicator(value.status, value.isFingerDetected),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _buildCameraPreview(CameraController cameraController) {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: cameraController.value.previewSize?.height ?? width,
        height: cameraController.value.previewSize?.width ?? height,
        child: CameraPreview(cameraController),
      ),
    );
  }

  Widget _buildFingerIndicator(HrvMonitorStatus status, bool isFingerDetected) {
    if (status == HrvMonitorStatus.ready || status == HrvMonitorStatus.uninitialized) {
      return const SizedBox.shrink();
    }

    Color borderColor;
    if (status == HrvMonitorStatus.waitingForFinger) {
      borderColor = Colors.orange;
    } else if (isFingerDetected) {
      borderColor = Colors.green;
    } else {
      borderColor = Colors.red;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: 4,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
