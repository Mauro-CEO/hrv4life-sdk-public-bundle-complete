import 'package:flutter/foundation.dart';

@immutable
class HrvPpgSignal {
  final List<double> timestamps;
  final List<double> raw;
  final List<double> filtered;
  final List<int> peaks;

  const HrvPpgSignal({
    required this.timestamps,
    required this.raw,
    required this.filtered,
    required this.peaks,
  });

  factory HrvPpgSignal.fromJson(Map<String, dynamic> json) {
    return HrvPpgSignal(
      timestamps: (json['timestamps'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      raw: (json['raw'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      filtered: (json['filtered'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      peaks: (json['peaks'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamps': timestamps,
      'raw': raw,
      'filtered': filtered,
      'peaks': peaks,
    };
  }
}

@immutable
class HrvRRTachogram {
  final List<int> beats;
  final List<double> rrIntervals;
  final List<double> smoothed;

  const HrvRRTachogram({
    required this.beats,
    required this.rrIntervals,
    required this.smoothed,
  });

  factory HrvRRTachogram.fromJson(Map<String, dynamic> json) {
    return HrvRRTachogram(
      beats: (json['beats'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      rrIntervals: (json['rrIntervals'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      smoothed: (json['smoothed'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'beats': beats,
      'rrIntervals': rrIntervals,
      'smoothed': smoothed,
    };
  }
}

@immutable
class HrvPoincarePoint {
  final double x;
  final double y;

  const HrvPoincarePoint({
    required this.x,
    required this.y,
  });

  factory HrvPoincarePoint.fromJson(Map<String, dynamic> json) {
    return HrvPoincarePoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}

@immutable
class HrvPoincareData {
  final List<HrvPoincarePoint> points;

  const HrvPoincareData({required this.points});

  factory HrvPoincareData.fromJson(Map<String, dynamic> json) {
    final pointsList = json['points'] as List? ?? [];
    return HrvPoincareData(
      points: pointsList
          .map((p) => HrvPoincarePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
    };
  }
}

@immutable
class HrvVisualization {
  final HrvPpgSignal ppgSignal;
  final HrvRRTachogram rrTachogram;
  final HrvPoincareData poincareData;

  const HrvVisualization({
    required this.ppgSignal,
    required this.rrTachogram,
    required this.poincareData,
  });

  factory HrvVisualization.fromJson(Map<String, dynamic> json) {
    return HrvVisualization(
      ppgSignal: HrvPpgSignal.fromJson(
          json['ppgSignal'] as Map<String, dynamic>? ?? {}),
      rrTachogram: HrvRRTachogram.fromJson(
          json['rrTachogram'] as Map<String, dynamic>? ?? {}),
      poincareData: HrvPoincareData.fromJson(
          json['poincareData'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ppgSignal': ppgSignal.toJson(),
      'rrTachogram': rrTachogram.toJson(),
      'poincareData': poincareData.toJson(),
    };
  }
}
