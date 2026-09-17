import 'package:flutter/foundation.dart';

import 'hrv_monitor_controller.dart';
import 'models/hrv_result.dart';

/// A completed measurement result captured at a point in time.
///
/// [result] holds the full analysis produced by [HrvMonitorController] while
/// [measuredAt] records when the measurement finished (used to build
/// time-based trend charts).
@immutable
class HrvReading {
  final HrvResult result;
  final DateTime measuredAt;

  const HrvReading({
    required this.result,
    required this.measuredAt,
  });
}

/// Global, in-memory store of HRV measurement data.
///
/// This is the automatic integration point for the SDK chart widgets.
/// A [HrvMonitorController] publishes its completed results here (and
/// registers itself as the [activeController]) with no configuration; widgets
/// created with no parameters automatically read from [HrvSession.instance]:
///
/// ```dart
/// const HrvHealthGauge();          // uses session.lastResult
/// const HrvPpgChart();             // uses session.lastResult
/// const HrvHeartRateTrendChart();  // uses session.readings
/// const HrvLivePpgChart();         // uses session.activeController
/// ```
class HrvSession extends ChangeNotifier {
  HrvSession._();

  /// Shared instance used by the auto-populating widgets.
  static final HrvSession instance = HrvSession._();

  final List<HrvReading> _readings = [];

  HrvMonitorController? _activeController;

  /// Completed readings ordered from oldest to newest.
  List<HrvReading> get readings => List.unmodifiable(_readings);

  /// The results of all completed readings, oldest to newest.
  List<HrvResult> get results => List.unmodifiable(_readings.map((r) => r.result));

  /// Last successfully completed measurement, or `null` when none yet.
  HrvResult? get lastResult => _readings.isEmpty ? null : _readings.last.result;

  /// The [HrvMonitorController] most recently created (and not yet disposed).
  ///
  /// Used by live widgets (e.g. [HrvLivePpgChart]) to render streaming data
  /// while a measurement is in progress.
  HrvMonitorController? get activeController => _activeController;

  /// Registers (or unregisters) the active controller.
  ///
  /// Called automatically by [HrvMonitorController]; app code normally does
  /// not need to call this.
  set activeController(HrvMonitorController? controller) {
    if (identical(_activeController, controller)) return;
    _activeController = controller;
    notifyListeners();
  }

  /// Stores a successful measurement result.
  ///
  /// Failed results are ignored. Readings with the same [HrvResult.measurementId]
  /// are stored only once. Listeners of this session are notified so
  /// auto-populating widgets rebuild.
  void addResult(HrvResult result, {DateTime? measuredAt}) {
    if (!result.success) return;

    final id = result.measurementId;
    if (id != null && id.isNotEmpty) {
      final alreadyStored = _readings.any((reading) => reading.result.measurementId == id);
      if (alreadyStored) return;
    }

    _readings.add(HrvReading(
      result: result,
      measuredAt: measuredAt ?? DateTime.now(),
    ));
    _readings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    notifyListeners();
  }

  /// Removes all stored readings (in-memory only; nothing is persisted).
  void clearReadings() {
    if (_readings.isEmpty) return;
    _readings.clear();
    notifyListeners();
  }
}