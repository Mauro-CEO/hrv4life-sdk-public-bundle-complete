# HRV4Life SDK

[![pub package](https://img.shields.io/pub/v/hrv4life_sdk.svg)](https://pub.dev/packages/hrv4life_sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.3.0-blue.svg)](https://flutter.dev)

A Flutter package for measuring Heart Rate Variability (HRV) using the device's camera as a PPG (Photoplethysmography) sensor.

## Features

- **Camera-based PPG** - Uses the rear camera with flash to detect blood volume changes
- **Real-time finger detection** - Automatic detection when finger is placed on camera
- **HRV metrics** - Time domain, frequency domain, and non-linear analysis
- **Simple API** - Follows Flutter's standard Controller + Widget pattern (like `video_player`, `camera`)
- **No external state management** - Uses native `ValueNotifier` for reactivity
- **Ready-to-use charts** - Auto-populating PPG, tachogram, Poincaré, PSD, frequency-band, health-gauge and trend widgets
- **Cross-platform** - Works on both Android and iOS

## How It Works

1. User places their finger on the rear camera (with flash on)
2. Camera captures luminosity variations at ~30 FPS
3. Blood flow causes measurable changes in light absorption
4. Data is sent to the HRV4Life API for analysis
5. Returns comprehensive HRV metrics

## Installation

Add `hrv4life_sdk` to your `pubspec.yaml`:

```yaml
dependencies:
  hrv4life_sdk: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Platform Setup

#### Android

Add camera and internet permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.INTERNET" />

    <uses-feature android:name="android.hardware.camera" android:required="true" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <!-- ... rest of manifest -->
</manifest>
```

#### iOS

Add camera usage description to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to measure your heart rate variability.</string>
```

## Quick Start

```dart
import 'package:hrv4life_sdk/hrv4life_sdk.dart';

class HrvScreen extends StatefulWidget {
  @override
  State<HrvScreen> createState() => _HrvScreenState();
}

class _HrvScreenState extends State<HrvScreen> {
  late HrvMonitorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HrvMonitorController(apiToken: 'YOUR_API_TOKEN');
    _controller.initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Camera preview widget
        HrvCameraPreview(controller: _controller),

        // Listen to state changes
        ValueListenableBuilder<HrvMonitorValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            return Column(
              children: [
                Text(value.statusMessage),
                Text('Progress: ${value.progress}%'),
                LinearProgressIndicator(value: value.progress / 100),
              ],
            );
          },
        ),

        // Control buttons
        ElevatedButton(
          onPressed: () => _controller.startMeasurement(),
          child: Text('Start'),
        ),
      ],
    );
  }
}
```

## API Reference

### HrvMonitorController

Main controller for HRV measurement. Extends `ValueNotifier<HrvMonitorValue>`.

```dart
final controller = HrvMonitorController(
  apiToken: 'YOUR_API_TOKEN',
  config: HrvMonitorConfig(
    measurementDuration: Duration(minutes: 3),
    minFingerLuminance: 55,
    maxFingerLuminance: 75,
  ),
);
```

#### Methods

| Method | Description |
|--------|-------------|
| `initialize()` | Initializes camera. Must be called before `startMeasurement()` |
| `startMeasurement()` | Starts HRV measurement |
| `stopMeasurement()` | Stops current measurement |
| `reset()` | Resets controller to ready state |
| `dispose()` | Releases resources. Safe to call multiple times |

#### Callbacks

```dart
controller.onResult = (HrvResult result) {
  print('Heart Rate: ${result.heartRate} BPM');
  print('SDNN: ${result.timeDomain?['sdnn']}');
};

controller.onError = (String error) {
  print('Error: $error');
};
```

### HrvMonitorValue

Immutable state class representing the current monitor state.

| Property | Type | Description |
|----------|------|-------------|
| `status` | `HrvMonitorStatus` | Current status |
| `isInitialized` | `bool` | Whether controller is initialized |
| `isMeasuring` | `bool` | Whether measurement is in progress |
| `isFingerDetected` | `bool` | Whether finger is detected on camera |
| `progress` | `int` | Measurement progress (0-100) |
| `elapsedSeconds` | `int` | Seconds since measurement started |
| `statusMessage` | `String` | Human-readable status message |
| `chartData` | `List<double>` | Last 100 intensity points for visualization |
| `result` | `HrvResult?` | Measurement result (when completed) |
| `error` | `String?` | Error message (when status is error) |

### HrvMonitorStatus

```dart
enum HrvMonitorStatus {
  uninitialized,    // Controller not initialized
  initializing,     // Setting up camera
  ready,            // Ready to start measurement
  waitingForFinger, // Waiting for finger placement
  measuring,        // Actively measuring
  processing,       // Sending data to API
  completed,        // Measurement complete
  error,            // An error occurred
}
```

### HrvCameraPreview

Widget that displays the camera preview.

```dart
HrvCameraPreview(
  controller: _controller,
  width: 150,                    // Optional, default: 150
  height: 150,                   // Optional, default: 150
  borderRadius: 75,              // Optional, default: 75 (circular)
  placeholder: CircularProgressIndicator(), // Optional
  showFingerIndicator: true,     // Optional, default: true
)
```

### HrvResult

Result returned after successful measurement.

| Property | Type | Description |
|----------|------|-------------|
| `heartRate` | `double` | Average heart rate in BPM |
| `timeDomain` | `Map<String, dynamic>?` | SDNN, RMSSD, pNN50, etc. |
| `frequencyDomain` | `Map<String, dynamic>?` | LF, HF, LF/HF ratio, etc. |
| `nonLinear` | `Map<String, dynamic>?` | SD1, SD2, etc. |
| `success` | `bool` | Whether analysis was successful |
| `errorMessage` | `String?` | Error message if failed |

### HrvMonitorConfig

Configuration options for measurement.

```dart
HrvMonitorConfig(
  measurementDuration: Duration(minutes: 3), // Default: 3 minutes
  minFingerLuminance: 55,                     // Default: 55
  maxFingerLuminance: 75,                     // Default: 75
)
```

## Charts (auto-populated)

The SDK ships ready-to-use chart widgets that require **zero configuration**.
Every `HrvMonitorController` automatically publishes its completed results to a
global, in-memory `HrvSession` singleton, so each widget can be created with no
arguments and will populate itself with the user's own measurement data as soon
as a measurement finishes:

```dart
// No parameters — reads from HrvSession.instance automatically.
const HrvHealthGauge();          // health score gauge
const HrvPpgChart();             // raw/filtered PPG signal
const HrvRrTachogramChart();     // RR interval tachogram
const HrvPoincareChart();        // Poincaré scatter + SD1/SD2 ellipse
const HrvFrequencySpectrumChart(); // VLF/LF/HF proportion bars
const HrvPsdChart();             // power spectral density curve
const HrvHeartRateTrendChart();  // BPM history
const HrvRmssdTrendChart();      // RMSSD history
const HrvStressTrendChart();     // stress index history

// Live waveform during the measurement itself.
const HrvLivePpgChart();
```

All widgets rebuild automatically when the session changes (new measurement,
history cleared or a live controller attached), so you can drop them anywhere in
your widget tree.

> See **[WIDGETS.md](WIDGETS.md)** for a complete guide with every widget, its
> parameters and data sources.

### HrvSession

| Member | Type | Description |
|--------|------|-------------|
| `HrvSession.instance` | `HrvSession` | Shared global session |
| `readings` | `List<HrvReading>` | Completed readings (oldest → newest); `HrvReading` = `result` + `measuredAt` |
| `results` | `List<HrvResult>` | Results of all completed readings |
| `lastResult` | `HrvResult?` | Result of the most recent successful measurement |
| `activeController` | `HrvMonitorController?` | Controller currently measuring (used by `HrvLivePpgChart`) |
| `addResult(result, {measuredAt})` | `void` | Stores a successful result (failed/duplicate results are ignored) |
| `clearReadings()` | `void` | Clears the in-memory history |

> History is **in-memory only** — nothing is persisted across app restarts.
> Feed your own data by calling `HrvSession.instance.addResult(...)`, e.g. after
> loading previous measurements from your backend.

### Explicit data (override the session)

Every widget also accepts explicit data, which takes priority over the session.
This is useful to render a specific measurement from a history list:

```dart
HrvPpgChart(result: selectedResult);
HrvPpgChart(ppgSignal: someSignal);
HrvHealthGauge(healthScore: 5, riskClassification: 'Moderado');
HrvTrendChart(
  metric: HrvTrendMetric.rmssd,
  readings: [HrvReading(result: r, measuredAt: when)],
  title: 'RMSSD',
);
```

`HrvTrendChart` shows the **last 10 days** by default and includes a date-range
picker (`enableRangePicker: false` to hide it). The convenience wrappers
`HrvHeartRateTrendChart`, `HrvRmssdTrendChart` and `HrvStressTrendChart` cover
the most common metrics.

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:hrv4life_sdk/hrv4life_sdk.dart';

class HrvMonitorPage extends StatefulWidget {
  const HrvMonitorPage({super.key});

  @override
  State<HrvMonitorPage> createState() => _HrvMonitorPageState();
}

class _HrvMonitorPageState extends State<HrvMonitorPage> {
  late HrvMonitorController _controller;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _controller = HrvMonitorController(
      apiToken: 'YOUR_API_TOKEN',
      config: const HrvMonitorConfig(
        measurementDuration: Duration(minutes: 3),
      ),
    );

    _controller.onResult = _handleResult;
    _controller.onError = _handleError;

    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initialize();
    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  void _handleResult(HrvResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Measurement Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Heart Rate: ${result.heartRate.toStringAsFixed(1)} BPM'),
            if (result.timeDomain != null) ...[
              const SizedBox(height: 8),
              Text('SDNN: ${result.timeDomain!['sdnn']} ms'),
              Text('RMSSD: ${result.timeDomain!['rmssd']} ms'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.reset();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('HRV Monitor')),
      body: ValueListenableBuilder<HrvMonitorValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Camera preview
                HrvCameraPreview(
                  controller: _controller,
                  width: 200,
                  height: 200,
                  borderRadius: 100,
                ),
                const SizedBox(height: 24),

                // Status
                Text(
                  value.statusMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // Progress
                if (value.isMeasuring) ...[
                  LinearProgressIndicator(value: value.progress / 100),
                  const SizedBox(height: 8),
                  Text('${value.progress}% - ${value.elapsedSeconds}s'),
                ],

                const Spacer(),

                // Action button
                ElevatedButton(
                  onPressed: value.isMeasuring
                      ? _controller.stopMeasurement
                      : _controller.startMeasurement,
                  child: Text(value.isMeasuring ? 'Stop' : 'Start'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## Finger Detection

The package automatically detects finger placement using luminance analysis:

- **With finger**: Luminance typically 55-75 (light absorbed by blood)
- **Without finger**: Luminance typically 75-85+ (light reflected)
- **Detection**: Requires 5 consecutive frames in range
- **Loss detection**: Requires 10 consecutive frames out of range

## Best Practices

1. **Lighting conditions**: Works best in normal indoor lighting
2. **Finger placement**: Cover the entire camera lens and flash
3. **Stability**: Keep the device steady during measurement
4. **Duration**: Minimum 3 minutes (180 seconds) recommended for accurate HRV analysis
5. **User guidance**: Show clear instructions for proper finger placement

## Error Handling

The package never throws exceptions to the consuming app. All errors are handled internally:

```dart
// Errors are communicated via:
// 1. HrvMonitorValue.status == HrvMonitorStatus.error
// 2. HrvMonitorValue.error contains the message
// 3. onError callback is called

controller.onError = (String error) {
  // Handle error (show snackbar, dialog, etc.)
};
```

## Requirements

- Flutter >= 3.3.0
- Dart >= 3.0.0
- Android: minSdkVersion 21+
- iOS: iOS 11.0+

## Dependencies

- [camera](https://pub.dev/packages/camera) - Camera access
- [dio](https://pub.dev/packages/dio) - HTTP client for API calls
- [fl_chart](https://pub.dev/packages/fl_chart) - PSD, frequency-band and trend charts

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- Issues: [GitHub Issues](https://github.com/hrv4life/hrv4life_sdk/issues)
- Documentation: [API Reference](https://pub.dev/documentation/hrv4life_sdk/latest/)

---

Made with ❤️ by [HRV4Life](https://hrv4life.com)
