import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../domain/athlete_data.dart';

/// Reads Huawei records that the iPhone has already received in Apple Health.
/// HealthKit is the only live integration here; there is no Huawei API login.
class HuaweiAppleHealthSource {
  static const sourceName = 'Huawei via Apple Health';
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
        endTime: now);
    return HuaweiHealthNormalizer.normalize(points);
  }
}

/// Converts HealthKit samples into the app's nullable daily wearable model.
class HuaweiHealthNormalizer {
  static List<WearableSample> normalize(List<HealthDataPoint> points) {
    final huawei = points.where((point) =>
        point.sourceName.toLowerCase().contains('huawei') ||
        point.sourceId.toLowerCase().contains('huawei'));
    final days = <String, _DayMetrics>{};
    for (final point in huawei) {
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
      final metrics = days.putIfAbsent(day, _DayMetrics.new);
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
              date: entry.key,
              source: HuaweiAppleHealthSource.sourceName,
              mode: 'LIVE',
              sleepMinutes: _minutes(entry.value.stages.isNotEmpty
                  ? entry.value.stages
                  : entry.value.asleep),
              hrv: entry.value.hrv,
              restingHr: entry.value.restingHr,
              heartRate: entry.value.heartRate,
              workoutMinutes: _minutes(entry.value.workouts),
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
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
