import 'package:flutter/foundation.dart';

// ===== TIME DOMAIN =====

@immutable
class HrvConfidenceInterval {
  final double lower;
  final double upper;

  const HrvConfidenceInterval({
    required this.lower,
    required this.upper,
  });

  factory HrvConfidenceInterval.fromJson(Map<String, dynamic> json) {
    return HrvConfidenceInterval(
      lower: (json['lower'] as num?)?.toDouble() ?? 0.0,
      upper: (json['upper'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lower': lower,
      'upper': upper,
    };
  }
}

@immutable
class HrvHeartRate {
  final double meanHR;
  final double minHR;
  final double maxHR;
  final double meanRR;
  final HrvConfidenceInterval ci95;

  const HrvHeartRate({
    required this.meanHR,
    required this.minHR,
    required this.maxHR,
    required this.meanRR,
    required this.ci95,
  });

  factory HrvHeartRate.fromJson(Map<String, dynamic> json) {
    return HrvHeartRate(
      meanHR: (json['meanHR'] as num?)?.toDouble() ?? 0.0,
      minHR: (json['minHR'] as num?)?.toDouble() ?? 0.0,
      maxHR: (json['maxHR'] as num?)?.toDouble() ?? 0.0,
      meanRR: (json['meanRR'] as num?)?.toDouble() ?? 0.0,
      ci95: HrvConfidenceInterval.fromJson(
          json['ci95'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meanHR': meanHR,
      'minHR': minHR,
      'maxHR': maxHR,
      'meanRR': meanRR,
      'ci95': ci95.toJson(),
    };
  }
}

@immutable
class HrvVariability {
  final double sdnn;
  final double rmssd;
  final double lnRmssd;
  final int nn50;
  final double pnn50;
  final double cvSdnn;
  final double cvRmssd;
  final double hrvTriangular;
  final double tinn;

  const HrvVariability({
    required this.sdnn,
    required this.rmssd,
    required this.lnRmssd,
    required this.nn50,
    required this.pnn50,
    required this.cvSdnn,
    required this.cvRmssd,
    required this.hrvTriangular,
    required this.tinn,
  });

  factory HrvVariability.fromJson(Map<String, dynamic> json) {
    return HrvVariability(
      sdnn: (json['sdnn'] as num?)?.toDouble() ?? 0.0,
      rmssd: (json['rmssd'] as num?)?.toDouble() ?? 0.0,
      lnRmssd: (json['lnRmssd'] as num?)?.toDouble() ?? 0.0,
      nn50: json['nn50'] as int? ?? 0,
      pnn50: (json['pnn50'] as num?)?.toDouble() ?? 0.0,
      cvSdnn: (json['cvSdnn'] as num?)?.toDouble() ?? 0.0,
      cvRmssd: (json['cvRmssd'] as num?)?.toDouble() ?? 0.0,
      hrvTriangular: (json['hrvTriangular'] as num?)?.toDouble() ?? 0.0,
      tinn: (json['tinn'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sdnn': sdnn,
      'rmssd': rmssd,
      'lnRmssd': lnRmssd,
      'nn50': nn50,
      'pnn50': pnn50,
      'cvSdnn': cvSdnn,
      'cvRmssd': cvRmssd,
      'hrvTriangular': hrvTriangular,
      'tinn': tinn,
    };
  }
}

@immutable
class HrvTimeDomain {
  final HrvHeartRate heartRate;
  final HrvVariability variability;
  final List<String>? warnings;

  const HrvTimeDomain({
    required this.heartRate,
    required this.variability,
    this.warnings,
  });

  factory HrvTimeDomain.fromJson(Map<String, dynamic> json) {
    return HrvTimeDomain(
      heartRate: HrvHeartRate.fromJson(
          json['heartRate'] as Map<String, dynamic>? ?? {}),
      variability: HrvVariability.fromJson(
          json['variability'] as Map<String, dynamic>? ?? {}),
      warnings: (json['warnings'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'heartRate': heartRate.toJson(),
      'variability': variability.toJson(),
    };
    if (warnings != null && warnings!.isNotEmpty) {
      map['warnings'] = warnings;
    }
    return map;
  }
}

// ===== FREQUENCY DOMAIN =====

@immutable
class HrvFrequencyBand {
  final double peak;
  final double power;
  final double percentage;
  final double? nu;

  const HrvFrequencyBand({
    required this.peak,
    required this.power,
    required this.percentage,
    this.nu,
  });

  factory HrvFrequencyBand.fromJson(Map<String, dynamic> json) {
    return HrvFrequencyBand(
      peak: (json['peak'] as num?)?.toDouble() ?? 0.0,
      power: (json['power'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      nu: (json['nu'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'peak': peak,
      'power': power,
      'percentage': percentage,
    };
    if (nu != null) {
      map['nu'] = nu;
    }
    return map;
  }
}

@immutable
class HrvFrequencyTotal {
  final double power;

  const HrvFrequencyTotal({required this.power});

  factory HrvFrequencyTotal.fromJson(Map<String, dynamic> json) {
    return HrvFrequencyTotal(
      power: (json['power'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'power': power};
  }
}

@immutable
class HrvFrequencyRatios {
  final double lfHf;

  const HrvFrequencyRatios({
    required this.lfHf,
  });

  factory HrvFrequencyRatios.fromJson(Map<String, dynamic> json) {
    return HrvFrequencyRatios(
      lfHf: (json['lfHf'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lfHf': lfHf,
    };
  }
}

@immutable
class HrvFrequencyInterpretation {
  final String sympathetic;
  final String parasympathetic;
  final String balance;

  const HrvFrequencyInterpretation({
    required this.sympathetic,
    required this.parasympathetic,
    required this.balance,
  });

  factory HrvFrequencyInterpretation.fromJson(Map<String, dynamic> json) {
    return HrvFrequencyInterpretation(
      sympathetic: json['sympathetic'] as String? ?? '',
      parasympathetic: json['parasympathetic'] as String? ?? '',
      balance: json['balance'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sympathetic': sympathetic,
      'parasympathetic': parasympathetic,
      'balance': balance,
    };
  }
}

@immutable
class HrvFrequencyDomain {
  final HrvFrequencyBand vlf;
  final HrvFrequencyBand lf;
  final HrvFrequencyBand hf;
  final HrvFrequencyTotal total;
  final HrvFrequencyRatios ratios;
  final HrvFrequencyInterpretation? interpretation;

  /// Raw PSD curve as `[frequency, power]` pairs (when provided by the
  /// backend). Used by [HrvPsdChart] for a faithful spectrum; otherwise the
  /// chart builds a synthetic curve from the band powers.
  final List<List<double>>? psdData;

  const HrvFrequencyDomain({
    required this.vlf,
    required this.lf,
    required this.hf,
    required this.total,
    required this.ratios,
    this.interpretation,
    this.psdData,
  });

  factory HrvFrequencyDomain.fromJson(Map<String, dynamic> json) {
    return HrvFrequencyDomain(
      vlf: HrvFrequencyBand.fromJson(json['vlf'] as Map<String, dynamic>? ?? {}),
      lf: HrvFrequencyBand.fromJson(json['lf'] as Map<String, dynamic>? ?? {}),
      hf: HrvFrequencyBand.fromJson(json['hf'] as Map<String, dynamic>? ?? {}),
      total: HrvFrequencyTotal.fromJson(
          json['total'] as Map<String, dynamic>? ?? {}),
      ratios: HrvFrequencyRatios.fromJson(
          json['ratios'] as Map<String, dynamic>? ?? {}),
      interpretation: json['interpretation'] != null
          ? HrvFrequencyInterpretation.fromJson(
              json['interpretation'] as Map<String, dynamic>)
          : null,
      psdData: (json['psdData'] as List?)
          ?.map((e) {
            if (e is List && e.length >= 2) {
              return [(e[0] as num).toDouble(), (e[1] as num).toDouble()];
            }
            return null;
          })
          .whereType<List<double>>()
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'vlf': vlf.toJson(),
      'lf': lf.toJson(),
      'hf': hf.toJson(),
      'total': total.toJson(),
      'ratios': ratios.toJson(),
    };
    if (interpretation != null) {
      map['interpretation'] = interpretation!.toJson();
    }
    if (psdData != null) {
      map['psdData'] = psdData;
    }
    return map;
  }
}

// ===== NONLINEAR =====

@immutable
class HrvPoincare {
  final double sd1;
  final double sd2;
  final double ratio;

  const HrvPoincare({
    required this.sd1,
    required this.sd2,
    required this.ratio,
  });

  factory HrvPoincare.fromJson(Map<String, dynamic> json) {
    return HrvPoincare(
      sd1: (json['sd1'] as num?)?.toDouble() ?? 0.0,
      sd2: (json['sd2'] as num?)?.toDouble() ?? 0.0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sd1': sd1,
      'sd2': sd2,
      'ratio': ratio,
    };
  }
}

@immutable
class HrvNonlinearInterpretation {
  final String shortTerm;
  final String longTerm;
  final String balance;

  const HrvNonlinearInterpretation({
    required this.shortTerm,
    required this.longTerm,
    required this.balance,
  });

  factory HrvNonlinearInterpretation.fromJson(Map<String, dynamic> json) {
    return HrvNonlinearInterpretation(
      shortTerm: json['shortTerm'] as String? ?? '',
      longTerm: json['longTerm'] as String? ?? '',
      balance: json['balance'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shortTerm': shortTerm,
      'longTerm': longTerm,
      'balance': balance,
    };
  }
}

// ===== SYMBOLIC ANALYSIS =====

@immutable
class HrvSymbolicTriplets {
  final int zeroV;
  final int oneV;
  final int twoLV;
  final int twoULV;

  const HrvSymbolicTriplets({
    required this.zeroV,
    required this.oneV,
    required this.twoLV,
    required this.twoULV,
  });

  factory HrvSymbolicTriplets.fromJson(Map<String, dynamic> json) {
    return HrvSymbolicTriplets(
      zeroV: json['0V'] as int? ?? 0,
      oneV: json['1V'] as int? ?? 0,
      twoLV: json['2LV'] as int? ?? 0,
      twoULV: json['2ULV'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '0V': zeroV,
      '1V': oneV,
      '2LV': twoLV,
      '2ULV': twoULV,
    };
  }
}

@immutable
class HrvSymbolicPercentages {
  final double zeroV;
  final double oneV;
  final double twoLV;
  final double twoULV;

  const HrvSymbolicPercentages({
    required this.zeroV,
    required this.oneV,
    required this.twoLV,
    required this.twoULV,
  });

  factory HrvSymbolicPercentages.fromJson(Map<String, dynamic> json) {
    return HrvSymbolicPercentages(
      zeroV: (json['0V'] as num?)?.toDouble() ?? 0.0,
      oneV: (json['1V'] as num?)?.toDouble() ?? 0.0,
      twoLV: (json['2LV'] as num?)?.toDouble() ?? 0.0,
      twoULV: (json['2ULV'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '0V': zeroV,
      '1V': oneV,
      '2LV': twoLV,
      '2ULV': twoULV,
    };
  }
}

@immutable
class HrvSymbolicInterpretation {
  final String dominantPattern;
  final String variabilityLevel;
  final String description;

  const HrvSymbolicInterpretation({
    required this.dominantPattern,
    required this.variabilityLevel,
    required this.description,
  });

  factory HrvSymbolicInterpretation.fromJson(Map<String, dynamic> json) {
    return HrvSymbolicInterpretation(
      dominantPattern: json['dominantPattern'] as String? ?? '',
      variabilityLevel: json['variabilityLevel'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dominantPattern': dominantPattern,
      'variabilityLevel': variabilityLevel,
      'description': description,
    };
  }
}

@immutable
class HrvSymbolicAnalysis {
  final double amplitudeRR;
  final double amplitudePares;
  final HrvSymbolicTriplets tripletCounts;
  final HrvSymbolicPercentages tripletPercentages;
  final HrvSymbolicInterpretation? interpretation;

  const HrvSymbolicAnalysis({
    required this.amplitudeRR,
    required this.amplitudePares,
    required this.tripletCounts,
    required this.tripletPercentages,
    this.interpretation,
  });

  factory HrvSymbolicAnalysis.fromJson(Map<String, dynamic> json) {
    return HrvSymbolicAnalysis(
      amplitudeRR: (json['amplitudeRR'] as num?)?.toDouble() ?? 0.0,
      amplitudePares: (json['amplitudePares'] as num?)?.toDouble() ?? 0.0,
      tripletCounts: HrvSymbolicTriplets.fromJson(
          json['tripletCounts'] as Map<String, dynamic>? ?? {}),
      tripletPercentages: HrvSymbolicPercentages.fromJson(
          json['tripletPercentages'] as Map<String, dynamic>? ?? {}),
      interpretation: json['interpretation'] != null
          ? HrvSymbolicInterpretation.fromJson(
              json['interpretation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'amplitudeRR': amplitudeRR,
      'amplitudePares': amplitudePares,
      'tripletCounts': tripletCounts.toJson(),
      'tripletPercentages': tripletPercentages.toJson(),
    };
    if (interpretation != null) {
      map['interpretation'] = interpretation!.toJson();
    }
    return map;
  }
}

// ===== RHYTHM STATUS =====

@immutable
class HrvRhythmIndicator {
  final String name;
  final double value;
  final String normalRange;
  final String assessment;
  final double weight;

  const HrvRhythmIndicator({
    required this.name,
    required this.value,
    required this.normalRange,
    required this.assessment,
    required this.weight,
  });

  factory HrvRhythmIndicator.fromJson(Map<String, dynamic> json) {
    return HrvRhythmIndicator(
      name: json['name'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      normalRange: json['normalRange'] as String? ?? '',
      assessment: json['assessment'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'normalRange': normalRange,
      'assessment': assessment,
      'weight': weight,
    };
  }
}

@immutable
class HrvRhythmAgreement {
  final int normal;
  final int ectopic;
  final int afib;
  final int total;

  const HrvRhythmAgreement({
    required this.normal,
    required this.ectopic,
    required this.afib,
    required this.total,
  });

  factory HrvRhythmAgreement.fromJson(Map<String, dynamic> json) {
    return HrvRhythmAgreement(
      normal: json['normal'] as int? ?? 0,
      ectopic: json['ectopic'] as int? ?? 0,
      afib: json['afib'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'normal': normal,
      'ectopic': ectopic,
      'afib': afib,
      'total': total,
    };
  }
}

@immutable
class HrvRhythmQualityFactors {
  final int recordingDurationMs;
  final bool isShortRecording;
  final double artifactPercentage;
  final bool isStationary;
  final String sensorType;

  const HrvRhythmQualityFactors({
    required this.recordingDurationMs,
    required this.isShortRecording,
    required this.artifactPercentage,
    required this.isStationary,
    required this.sensorType,
  });

  factory HrvRhythmQualityFactors.fromJson(Map<String, dynamic> json) {
    return HrvRhythmQualityFactors(
      recordingDurationMs: json['recordingDurationMs'] as int? ?? 0,
      isShortRecording: json['isShortRecording'] as bool? ?? true,
      artifactPercentage: (json['artifactPercentage'] as num?)?.toDouble() ?? 0.0,
      isStationary: json['isStationary'] as bool? ?? false,
      sensorType: json['sensorType'] as String? ?? 'ppg',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordingDurationMs': recordingDurationMs,
      'isShortRecording': isShortRecording,
      'artifactPercentage': artifactPercentage,
      'isStationary': isStationary,
      'sensorType': sensorType,
    };
  }
}

@immutable
class HrvRhythmStatus {
  final String status;
  final String statusLabel;
  final String confidence;
  final double confidenceScore;
  final List<HrvRhythmIndicator> indicators;
  final HrvRhythmAgreement indicatorAgreement;
  final HrvRhythmQualityFactors qualityFactors;
  final String disclaimer;
  final List<String> warnings;

  const HrvRhythmStatus({
    required this.status,
    required this.statusLabel,
    required this.confidence,
    required this.confidenceScore,
    required this.indicators,
    required this.indicatorAgreement,
    required this.qualityFactors,
    required this.disclaimer,
    required this.warnings,
  }) : _userFeedback = null;

  const HrvRhythmStatus._({
    required this.status,
    required this.statusLabel,
    required this.confidence,
    required this.confidenceScore,
    required this.indicators,
    required this.indicatorAgreement,
    required this.qualityFactors,
    required this.disclaimer,
    required this.warnings,
    HrvRhythmUserFeedback? userFeedback,
  }) : _userFeedback = userFeedback;

  HrvRhythmUserFeedback? get userFeedback => _userFeedback;
  final HrvRhythmUserFeedback? _userFeedback;

  factory HrvRhythmStatus.fromJson(Map<String, dynamic> json) {
    return HrvRhythmStatus._(
      status: json['status'] as String? ?? 'inconclusive',
      statusLabel: json['statusLabel'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'very_low',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      indicators: (json['indicators'] as List?)
          ?.map((e) => HrvRhythmIndicator.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      indicatorAgreement: HrvRhythmAgreement.fromJson(
          json['indicatorAgreement'] as Map<String, dynamic>? ?? {}),
      qualityFactors: HrvRhythmQualityFactors.fromJson(
          json['qualityFactors'] as Map<String, dynamic>? ?? {}),
      disclaimer: json['disclaimer'] as String? ?? '',
      warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
      userFeedback: json['userFeedback'] != null
          ? HrvRhythmUserFeedback.fromJson(json['userFeedback'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'statusLabel': statusLabel,
      'confidence': confidence,
      'confidenceScore': confidenceScore,
      'indicators': indicators.map((e) => e.toJson()).toList(),
      'indicatorAgreement': indicatorAgreement.toJson(),
      'qualityFactors': qualityFactors.toJson(),
      'disclaimer': disclaimer,
      'warnings': warnings,
    };
  }
}

/// Nonlinear metrics: Poincare + SampEn + Symbolic Analysis + Rhythm Status
@immutable
class HrvNonlinear {
  final HrvPoincare poincare;
  final double sampEn;
  final HrvSymbolicAnalysis? symbolicAnalysis;
  final HrvRhythmStatus? rhythmStatus;
  final HrvNonlinearInterpretation? interpretation;

  const HrvNonlinear({
    required this.poincare,
    required this.sampEn,
    this.symbolicAnalysis,
    this.rhythmStatus,
    this.interpretation,
  });

  factory HrvNonlinear.fromJson(Map<String, dynamic> json) {
    return HrvNonlinear(
      poincare: HrvPoincare.fromJson(
          json['poincare'] as Map<String, dynamic>? ?? {}),
      sampEn: (json['sampEn'] as num?)?.toDouble() ?? 0.0,
      symbolicAnalysis: json['symbolicAnalysis'] != null
          ? HrvSymbolicAnalysis.fromJson(
              json['symbolicAnalysis'] as Map<String, dynamic>)
          : null,
      rhythmStatus: json['rhythmStatus'] != null
          ? HrvRhythmStatus.fromJson(
              json['rhythmStatus'] as Map<String, dynamic>)
          : null,
      interpretation: json['interpretation'] != null
          ? HrvNonlinearInterpretation.fromJson(
              json['interpretation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'poincare': poincare.toJson(),
      'sampEn': sampEn,
    };
    if (symbolicAnalysis != null) {
      map['symbolicAnalysis'] = symbolicAnalysis!.toJson();
    }
    if (rhythmStatus != null) {
      map['rhythmStatus'] = rhythmStatus!.toJson();
    }
    if (interpretation != null) {
      map['interpretation'] = interpretation!.toJson();
    }
    return map;
  }
}

// ===== OTHER ANALYSIS =====

@immutable
class HrvStress {
  final double index;
  final String? interpretation;

  const HrvStress({
    required this.index,
    this.interpretation,
  });

  factory HrvStress.fromJson(Map<String, dynamic> json) {
    return HrvStress(
      index: (json['index'] as num?)?.toDouble() ?? 0.0,
      interpretation: json['interpretation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'index': index,
    };
    if (interpretation != null) {
      map['interpretation'] = interpretation;
    }
    return map;
  }
}

@immutable
class HrvRespiratory {
  final double asr;
  final bool present;
  /// Frequência respiratória estimada (respirações/min). null se não detectável.
  final double? respiratoryRate;
  /// Qualidade da estimativa: 'good', 'fair', 'poor'
  final String? respiratoryRateQuality;
  /// Método utilizado: 'spectral', 'autocorrelation', 'peak_counting'
  final String? respiratoryRateMethod;
  /// Frequência respiratória em Hz
  final double? respiratoryFrequencyHz;

  const HrvRespiratory({
    required this.asr,
    required this.present,
    this.respiratoryRate,
    this.respiratoryRateQuality,
    this.respiratoryRateMethod,
    this.respiratoryFrequencyHz,
  });

  factory HrvRespiratory.fromJson(Map<String, dynamic> json) {
    return HrvRespiratory(
      asr: (json['asr'] as num?)?.toDouble() ?? 0.0,
      present: json['present'] as bool? ?? false,
      respiratoryRate: (json['respiratoryRate'] as num?)?.toDouble(),
      respiratoryRateQuality: json['respiratoryRateQuality'] as String?,
      respiratoryRateMethod: json['respiratoryRateMethod'] as String?,
      respiratoryFrequencyHz: (json['respiratoryFrequencyHz'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asr': asr,
      'present': present,
      if (respiratoryRate != null) 'respiratoryRate': respiratoryRate,
      if (respiratoryRateQuality != null) 'respiratoryRateQuality': respiratoryRateQuality,
      if (respiratoryRateMethod != null) 'respiratoryRateMethod': respiratoryRateMethod,
      if (respiratoryFrequencyHz != null) 'respiratoryFrequencyHz': respiratoryFrequencyHz,
    };
  }
}

@immutable
class HrvHealthClassifications {
  final String fc;
  final String rmssd;
  final String hf;

  const HrvHealthClassifications({
    required this.fc,
    required this.rmssd,
    required this.hf,
  });

  factory HrvHealthClassifications.fromJson(Map<String, dynamic> json) {
    return HrvHealthClassifications(
      fc: json['fc'] as String? ?? '',
      rmssd: json['rmssd'] as String? ?? '',
      hf: json['hf'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fc': fc,
      'rmssd': rmssd,
      'hf': hf,
    };
  }
}

@immutable
class HrvHealthDetails {
  final String fcInterpretation;
  final String rmssdInterpretation;
  final String hfInterpretation;

  const HrvHealthDetails({
    required this.fcInterpretation,
    required this.rmssdInterpretation,
    required this.hfInterpretation,
  });

  factory HrvHealthDetails.fromJson(Map<String, dynamic> json) {
    return HrvHealthDetails(
      fcInterpretation: json['fcInterpretation'] as String? ?? '',
      rmssdInterpretation: json['rmssdInterpretation'] as String? ?? '',
      hfInterpretation: json['hfInterpretation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fcInterpretation': fcInterpretation,
      'rmssdInterpretation': rmssdInterpretation,
      'hfInterpretation': hfInterpretation,
    };
  }
}

@immutable
class HrvHealthAlert {
  final HrvHealthClassifications classifications;
  final String healthAlert;
  final int healthScore;
  final String riskClassification;
  final String? interpretation;
  final HrvHealthDetails details;

  const HrvHealthAlert({
    required this.classifications,
    required this.healthAlert,
    required this.healthScore,
    required this.riskClassification,
    this.interpretation,
    required this.details,
  });

  factory HrvHealthAlert.fromJson(Map<String, dynamic> json) {
    return HrvHealthAlert(
      classifications: HrvHealthClassifications.fromJson(
          json['classifications'] as Map<String, dynamic>? ?? {}),
      healthAlert: json['healthAlert'] as String? ?? '',
      healthScore: json['healthScore'] as int? ?? 0,
      riskClassification: json['riskClassification'] as String? ?? '',
      interpretation: json['interpretation'] as String?,
      details: HrvHealthDetails.fromJson(
          json['details'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'classifications': classifications.toJson(),
      'healthAlert': healthAlert,
      'healthScore': healthScore,
      'riskClassification': riskClassification,
      'details': details.toJson(),
    };
    if (interpretation != null) {
      map['interpretation'] = interpretation;
    }
    return map;
  }
}

/// Other analysis: stress, respiratory, healthAlert, trainingReadiness
@immutable
class HrvOtherAnalysis {
  final HrvStress stress;
  final HrvRespiratory respiratory;
  final HrvHealthAlert? healthAlert;
  final HrvTrainingReadiness? trainingReadiness;

  const HrvOtherAnalysis({
    required this.stress,
    required this.respiratory,
    this.healthAlert,
    this.trainingReadiness,
  });

  factory HrvOtherAnalysis.fromJson(Map<String, dynamic> json) {
    return HrvOtherAnalysis(
      stress: HrvStress.fromJson(
          json['stress'] as Map<String, dynamic>? ?? {}),
      respiratory: HrvRespiratory.fromJson(
          json['respiratory'] as Map<String, dynamic>? ?? {}),
      healthAlert: json['healthAlert'] != null
          ? HrvHealthAlert.fromJson(
              json['healthAlert'] as Map<String, dynamic>)
          : null,
      trainingReadiness: json['trainingReadiness'] != null
          ? HrvTrainingReadiness.fromJson(
              json['trainingReadiness'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'stress': stress.toJson(),
      'respiratory': respiratory.toJson(),
    };
    if (healthAlert != null) {
      map['healthAlert'] = healthAlert!.toJson();
    }
    if (trainingReadiness != null) {
      map['trainingReadiness'] = trainingReadiness!.toJson();
    }
    return map;
  }
}

// ===== METRICS (TOP LEVEL) =====

/// Matches the API JSON structure:
/// metrics {
///   timeDomain { heartRate, variability, warnings? }
///   frequencyDomain { vlf, lf, hf, total, ratios, interpretation? }
///   nonlinear { poincare, symbolicAnalysis?, interpretation? }
///   otherAnalysis { stress, respiratory, healthAlert? }
/// }
@immutable
class HrvMetrics {
  final HrvTimeDomain timeDomain;
  final HrvFrequencyDomain frequencyDomain;
  final HrvNonlinear nonlinear;
  final HrvOtherAnalysis otherAnalysis;

  const HrvMetrics({
    required this.timeDomain,
    required this.frequencyDomain,
    required this.nonlinear,
    required this.otherAnalysis,
  });

  factory HrvMetrics.fromJson(Map<String, dynamic> json) {
    return HrvMetrics(
      timeDomain: HrvTimeDomain.fromJson(
          json['timeDomain'] as Map<String, dynamic>? ?? {}),
      frequencyDomain: HrvFrequencyDomain.fromJson(
          json['frequencyDomain'] as Map<String, dynamic>? ?? {}),
      nonlinear: HrvNonlinear.fromJson(
          json['nonlinear'] as Map<String, dynamic>? ?? {}),
      otherAnalysis: HrvOtherAnalysis.fromJson(
          json['otherAnalysis'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeDomain': timeDomain.toJson(),
      'frequencyDomain': frequencyDomain.toJson(),
      'nonlinear': nonlinear.toJson(),
      'otherAnalysis': otherAnalysis.toJson(),
    };
  }
}

// ===== TRAINING READINESS =====

@immutable
class HrvReadinessFactor {
  final double score;
  final double value;
  final String interpretation;

  const HrvReadinessFactor({
    required this.score,
    required this.value,
    required this.interpretation,
  });

  factory HrvReadinessFactor.fromJson(Map<String, dynamic> json) {
    return HrvReadinessFactor(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      interpretation: json['interpretation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'value': value,
      'interpretation': interpretation,
    };
  }
}

@immutable
class HrvReadinessBalanceFactor {
  final double score;
  final double lfHfRatio;
  final String interpretation;

  const HrvReadinessBalanceFactor({
    required this.score,
    required this.lfHfRatio,
    required this.interpretation,
  });

  factory HrvReadinessBalanceFactor.fromJson(Map<String, dynamic> json) {
    return HrvReadinessBalanceFactor(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      lfHfRatio: (json['lfHfRatio'] as num?)?.toDouble() ?? 0.0,
      interpretation: json['interpretation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'lfHfRatio': lfHfRatio,
      'interpretation': interpretation,
    };
  }
}

@immutable
class HrvReadinessFactors {
  final HrvReadinessFactor rmssd;
  final HrvReadinessFactor restingHR;
  final HrvReadinessBalanceFactor autonomicBalance;

  const HrvReadinessFactors({
    required this.rmssd,
    required this.restingHR,
    required this.autonomicBalance,
  });

  factory HrvReadinessFactors.fromJson(Map<String, dynamic> json) {
    return HrvReadinessFactors(
      rmssd: HrvReadinessFactor.fromJson(
          json['rmssd'] as Map<String, dynamic>? ?? {}),
      restingHR: HrvReadinessFactor.fromJson(
          json['restingHR'] as Map<String, dynamic>? ?? {}),
      autonomicBalance: HrvReadinessBalanceFactor.fromJson(
          json['autonomicBalance'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rmssd': rmssd.toJson(),
      'restingHR': restingHR.toJson(),
      'autonomicBalance': autonomicBalance.toJson(),
    };
  }
}

@immutable
class HrvTrainingReadiness {
  final double score;
  final String level;
  final String recommendation;
  final HrvReadinessFactors factors;

  const HrvTrainingReadiness({
    required this.score,
    required this.level,
    required this.recommendation,
    required this.factors,
  });

  factory HrvTrainingReadiness.fromJson(Map<String, dynamic> json) {
    return HrvTrainingReadiness(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      level: json['level'] as String? ?? 'moderate',
      recommendation: json['recommendation'] as String? ?? '',
      factors: HrvReadinessFactors.fromJson(
          json['factors'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level,
      'recommendation': recommendation,
      'factors': factors.toJson(),
    };
  }
}

// ===== FEEDBACK MESSAGES =====

@immutable
class HrvFeedbackMetricStatus {
  final String status;
  final String message;

  const HrvFeedbackMetricStatus({
    required this.status,
    required this.message,
  });

  factory HrvFeedbackMetricStatus.fromJson(Map<String, dynamic> json) {
    return HrvFeedbackMetricStatus(
      status: json['status'] as String? ?? 'normal',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
    };
  }
}

@immutable
class HrvFeedbackMetrics {
  final HrvFeedbackMetricStatus rmssd;
  final HrvFeedbackMetricStatus hr;
  final HrvFeedbackMetricStatus stress;

  const HrvFeedbackMetrics({
    required this.rmssd,
    required this.hr,
    required this.stress,
  });

  factory HrvFeedbackMetrics.fromJson(Map<String, dynamic> json) {
    return HrvFeedbackMetrics(
      rmssd: HrvFeedbackMetricStatus.fromJson(
          json['rmssd'] as Map<String, dynamic>? ?? {}),
      hr: HrvFeedbackMetricStatus.fromJson(
          json['hr'] as Map<String, dynamic>? ?? {}),
      stress: HrvFeedbackMetricStatus.fromJson(
          json['stress'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rmssd': rmssd.toJson(),
      'hr': hr.toJson(),
      'stress': stress.toJson(),
    };
  }
}

@immutable
class HrvFeedbackMessages {
  final String primary;
  final String secondary;
  final String trainingAdvice;
  final List<String> recoveryTips;
  final HrvFeedbackMetrics metrics;

  const HrvFeedbackMessages({
    required this.primary,
    required this.secondary,
    required this.trainingAdvice,
    required this.recoveryTips,
    required this.metrics,
  });

  factory HrvFeedbackMessages.fromJson(Map<String, dynamic> json) {
    return HrvFeedbackMessages(
      primary: json['primary'] as String? ?? '',
      secondary: json['secondary'] as String? ?? '',
      trainingAdvice: json['trainingAdvice'] as String? ?? '',
      recoveryTips: (json['recoveryTips'] as List?)?.cast<String>() ?? [],
      metrics: HrvFeedbackMetrics.fromJson(
          json['metrics'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'secondary': secondary,
      'trainingAdvice': trainingAdvice,
      'recoveryTips': recoveryTips,
      'metrics': metrics.toJson(),
    };
  }
}

// ===== RHYTHM USER FEEDBACK =====

@immutable
class HrvRhythmUserFeedback {
  final String title;
  final String message;
  final String severity; // 'normal', 'attention', 'alert'
  final List<String> actionItems;

  const HrvRhythmUserFeedback({
    required this.title,
    required this.message,
    required this.severity,
    required this.actionItems,
  });

  factory HrvRhythmUserFeedback.fromJson(Map<String, dynamic> json) {
    return HrvRhythmUserFeedback(
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'normal',
      actionItems: (json['actionItems'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'severity': severity,
      'actionItems': actionItems,
    };
  }
}

// ===== RECOVERY SCORE (Body Battery) =====

@immutable
class HrvRecoveryComponent {
  final double value;
  final int normalized;
  final double weight;

  const HrvRecoveryComponent({
    required this.value,
    required this.normalized,
    required this.weight,
  });

  factory HrvRecoveryComponent.fromJson(Map<String, dynamic> json) {
    return HrvRecoveryComponent(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      normalized: (json['normalized'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return { 'value': value, 'normalized': normalized, 'weight': weight };
  }
}

@immutable
class HrvRecoveryComponents {
  final HrvRecoveryComponent rmssd;
  final HrvRecoveryComponent stress;
  final HrvRecoveryComponent heartRate;
  final HrvRecoveryComponent lfHfRatio;

  const HrvRecoveryComponents({
    required this.rmssd,
    required this.stress,
    required this.heartRate,
    required this.lfHfRatio,
  });

  factory HrvRecoveryComponents.fromJson(Map<String, dynamic> json) {
    return HrvRecoveryComponents(
      rmssd: HrvRecoveryComponent.fromJson(json['rmssd'] as Map<String, dynamic>? ?? {}),
      stress: HrvRecoveryComponent.fromJson(json['stress'] as Map<String, dynamic>? ?? {}),
      heartRate: HrvRecoveryComponent.fromJson(json['heartRate'] as Map<String, dynamic>? ?? {}),
      lfHfRatio: HrvRecoveryComponent.fromJson(json['lfHfRatio'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rmssd': rmssd.toJson(),
      'stress': stress.toJson(),
      'heartRate': heartRate.toJson(),
      'lfHfRatio': lfHfRatio.toJson(),
    };
  }
}

@immutable
class HrvRecoveryScore {
  final int score;
  final String level;
  final String label;
  final HrvRecoveryComponents components;
  final String recommendation;

  const HrvRecoveryScore({
    required this.score,
    required this.level,
    required this.label,
    required this.components,
    required this.recommendation,
  });

  factory HrvRecoveryScore.fromJson(Map<String, dynamic> json) {
    return HrvRecoveryScore(
      score: (json['score'] as num?)?.toInt() ?? 0,
      level: json['level'] as String? ?? 'moderate',
      label: json['label'] as String? ?? '',
      components: HrvRecoveryComponents.fromJson(
          json['components'] as Map<String, dynamic>? ?? {}),
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level,
      'label': label,
      'components': components.toJson(),
      'recommendation': recommendation,
    };
  }
}

// ===== TRAINING ZONES =====

@immutable
class HrvTrainingZone {
  final int zone;
  final String name;
  final String intensity;
  final int hrMin;
  final int hrMax;
  final String description;
  final String color;

  const HrvTrainingZone({
    required this.zone,
    required this.name,
    required this.intensity,
    required this.hrMin,
    required this.hrMax,
    required this.description,
    required this.color,
  });

  factory HrvTrainingZone.fromJson(Map<String, dynamic> json) {
    return HrvTrainingZone(
      zone: (json['zone'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      intensity: json['intensity'] as String? ?? '',
      hrMin: (json['hrMin'] as num?)?.toInt() ?? 0,
      hrMax: (json['hrMax'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? '#9E9E9E',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zone': zone, 'name': name, 'intensity': intensity,
      'hrMin': hrMin, 'hrMax': hrMax, 'description': description, 'color': color,
    };
  }
}

@immutable
class HrvTrainingZones {
  final String method;
  final int restingHR;
  final int maxHR;
  final String maxHRFormula;
  final int hrReserve;
  final List<HrvTrainingZone> zones;
  final double? vo2maxEstimate;
  final String? fitnessLevel;

  const HrvTrainingZones({
    required this.method,
    required this.restingHR,
    required this.maxHR,
    required this.maxHRFormula,
    required this.hrReserve,
    required this.zones,
    this.vo2maxEstimate,
    this.fitnessLevel,
  });

  factory HrvTrainingZones.fromJson(Map<String, dynamic> json) {
    return HrvTrainingZones(
      method: json['method'] as String? ?? 'karvonen',
      restingHR: (json['restingHR'] as num?)?.toInt() ?? 0,
      maxHR: (json['maxHR'] as num?)?.toInt() ?? 0,
      maxHRFormula: json['maxHRFormula'] as String? ?? '',
      hrReserve: (json['hrReserve'] as num?)?.toInt() ?? 0,
      zones: (json['zones'] as List?)
          ?.map((e) => HrvTrainingZone.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      vo2maxEstimate: (json['vo2maxEstimate'] as num?)?.toDouble(),
      fitnessLevel: json['fitnessLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method, 'restingHR': restingHR, 'maxHR': maxHR,
      'maxHRFormula': maxHRFormula, 'hrReserve': hrReserve,
      'zones': zones.map((z) => z.toJson()).toList(),
      if (vo2maxEstimate != null) 'vo2maxEstimate': vo2maxEstimate,
      if (fitnessLevel != null) 'fitnessLevel': fitnessLevel,
    };
  }
}