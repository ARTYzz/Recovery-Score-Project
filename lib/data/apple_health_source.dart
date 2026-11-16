import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../domain/athlete_data.dart';
import '../domain/health_source.dart';

/// Reads records already present in Apple Health from their reported sources.
/// This is a HealthKit connection, not a direct wearable vendor API login.
class AppleHealthSource {
  HealthReadSummary? lastReadSummary;
  static const types = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE,
    HealthDataType.WORKOUT,
  ];

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<List<WearableSample>> connect() async {
    if (!supported) {
      throw const FormatException('Apple Health requires an iPhone.');
    }
    final health = Health();
    await health.configure();
    await health.requestAuthorization(types,
        permissions: List.filled(types.length, HealthDataAccess.READ));
    // HealthKit does not reveal whether read permission was denied. Only
    // matching returned records count as a usable connection.
    return _read(health);
  }

  Future<List<WearableSample>> sync() async {
    if (!supported) return [];
    final health = Health();
    await health.configure();
    return _read(health);
  }

  Future<List<WearableSample>> _read(Health health) async {
    final now = DateTime.now();
    final points = await health.getHealthDataFromTypes(
        types: types,
        startTime: now.subtract(const Duration(days: 14)),
        endTime: now,
        recordingMethodsToFilter: const [RecordingMethod.manual]);
    lastReadSummary = HealthReadSummary.fromPoints(points, checkedAt: now);
    return AppleHealthNormalizer.normalize(points);
  }
}

/// Counts readable HealthKit records without storing health values.
/// An empty result cannot distinguish no records from denied read permission.
class HealthReadSummary {
  const HealthReadSummary({
    required this.checkedAt,
    required this.recordsBySource,
    required this.hrvBySource,
    required this.otherHrvRecords,
  });

  final DateTime checkedAt;
  final Map<String, int> recordsBySource;
  final Map<String, int> hrvBySource;
  final int otherHrvRecords;
  int get importedRecords =>
      recordsBySource.values.fold(0, (sum, count) => sum + count);
  int countFor(String source) => recordsBySource[source] ?? 0;

  factory HealthReadSummary.fromPoints(List<HealthDataPoint> points,
      {required DateTime checkedAt}) {
    final records = <String, int>{};
    final hrv = <String, int>{};
    var otherHrv = 0;
    for (final point in points) {
      if (point.recordingMethod == RecordingMethod.manual) continue;
      final source = AppleHealthNormalizer.sourceFor(point);
      if (source != null) {
        records.update(source, (count) => count + 1, ifAbsent: () => 1);
      }
      if (point.type != HealthDataType.HEART_RATE_VARIABILITY_SDNN ||
          point.value is! NumericHealthValue ||
          (point.value as NumericHealthValue).numericValue <= 0) {
        continue;
      }
      if (source != null) {
        hrv.update(source, (count) => count + 1, ifAbsent: () => 1);
      } else {
        otherHrv++;
      }
    }
    return HealthReadSummary(
        checkedAt: checkedAt,
        recordsBySource: records,
        hrvBySource: hrv,
        otherHrvRecords: otherHrv);
  }

  String hrvExplanation(String? selectedSource) {
    if (selectedSource != null && (hrvBySource[selectedSource] ?? 0) > 0) {
      return 'The selected source has readable HRV (SDNN) records.';
    }
    if (hrvBySource.isNotEmpty || otherHrvRecords > 0) {
      return 'HRV exists from another source, but no HRV was readable from the selected source. Sources are not mixed for recovery scoring.';
    }
    return 'No HRV (SDNN) record was readable in the last 14 days. Check Heart Rate Variability > Data Sources in Apple Health and Boxer Recovery read access. HealthKit cannot distinguish absent data from denied read access.';
  }
}

/// Converts HealthKit samples into the app's nullable daily source model.
class AppleHealthNormalizer {
  static String? sourceFor(HealthDataPoint point) {
    if (point.recordingMethod == RecordingMethod.manual) return null;
    return HealthSource.fromProvenance(
        name: point.sourceName, id: point.sourceId);
  }

  static List<WearableSample> normalize(List<HealthDataPoint> points) {
    final days = <String, _DayMetrics>{};
    for (final point in points) {
      final source = sourceFor(point);
      if (source == null) continue;
      final isSleep = const {
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
      }.contains(point.type);
      // Evening sleep belongs to the following morning's recovery day.
      final localEnd = point.dateTo.toLocal();
      final day = localDay(isSleep && localEnd.hour >= 18
          ? localEnd.add(const Duration(days: 1))
          : localEnd);
      final metrics = days.putIfAbsent('$source|$day', _DayMetrics.new);
      metrics.source = source;
      metrics.day = day;
      metrics.sourceId ??= point.sourceId;
      metrics.sourceName ??= point.sourceName;
      final value = point.value;
      final number =
          value is NumericHealthValue ? value.numericValue.toDouble() : null;
      switch (point.type) {
        case HealthDataType.SLEEP_ASLEEP:
          metrics.asleep.add((point.dateFrom, point.dateTo));
        case HealthDataType.SLEEP_LIGHT:
        case HealthDataType.SLEEP_DEEP:
        case HealthDataType.SLEEP_REM:
          metrics.stages.add((point.dateFrom, point.dateTo));
        case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
          if (number != null && number > 0) {
            metrics.setHrv(number, point.dateTo);
          }
        case HealthDataType.RESTING_HEART_RATE:
          if (number != null && number > 0) {
            metrics.setRestingHr(number, point.dateTo);
          }
        case HealthDataType.HEART_RATE:
          if (number != null && number > 0) {
            metrics.setHeartRate(number, point.dateTo);
          }
        case HealthDataType.WORKOUT:
          metrics.workouts.add((point.dateFrom, point.dateTo));
        default:
          break;
      }
    }
    return days.entries
        .map((entry) => WearableSample(
              date: entry.value.day,
              source: entry.value.source,
              mode: 'LIVE',
              sourceId: entry.value.sourceId,
              sourceName: entry.value.sourceName,
              sleepMinutes: _minutes(entry.value.stages.isNotEmpty
                  ? entry.value.stages
                  : entry.value.asleep),
              hrv: entry.value.hrv,
              restingHr: entry.value.restingHr,
              heartRate: entry.value.heartRate,
              workoutMinutes: _minutes(entry.value.workouts),
            ))
        .toList()
      ..sort((a, b) {
        final date = a.date.compareTo(b.date);
        return date != 0 ? date : a.source.compareTo(b.source);
      });
  }

  static int? _minutes(List<(DateTime, DateTime)> ranges) {
    if (ranges.isEmpty) return null;
    final sorted = [...ranges]..sort((a, b) => a.$1.compareTo(b.$1));
    var start = sorted.first.$1;
    var end = sorted.first.$2;
    var total = Duration.zero;
    for (final range in sorted.skip(1)) {
      if (range.$1.isAfter(end)) {
        total += end.difference(start);
        start = range.$1;
        end = range.$2;
      } else if (range.$2.isAfter(end)) {
        end = range.$2;
      }
    }
    total += end.difference(start);
    return total.inMinutes;
  }
}

class _DayMetrics {
  String source = '';
  String day = '';
  String? sourceId;
  String? sourceName;
  final asleep = <(DateTime, DateTime)>[];
  final stages = <(DateTime, DateTime)>[];
  final workouts = <(DateTime, DateTime)>[];
  double? hrv;
  double? restingHr;
  double? heartRate;
  DateTime? _hrvAt;
  DateTime? _restingAt;
  DateTime? _heartAt;

  void setHrv(double value, DateTime at) {
    if (_hrvAt == null || at.isAfter(_hrvAt!)) {
      hrv = value;
      _hrvAt = at;
    }
  }

  void setRestingHr(double value, DateTime at) {
    if (_restingAt == null || at.isAfter(_restingAt!)) {
      restingHr = value;
      _restingAt = at;
    }
  }

  void setHeartRate(double value, DateTime at) {
    if (_heartAt == null || at.isAfter(_heartAt!)) {
      heartRate = value;
      _heartAt = at;
    }
  }
}
