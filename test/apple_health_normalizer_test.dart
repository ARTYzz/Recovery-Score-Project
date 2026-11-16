import 'package:boxer_recovery/data/apple_health_source.dart';
import 'package:boxer_recovery/domain/health_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

HealthDataPoint point(HealthDataType type, String from, String to,
    {String source = 'HUAWEI Health: Global',
    String? sourceId,
    num value = 1}) {
  return HealthDataPoint(
    uuid: '$type-$from',
    value: NumericHealthValue(numericValue: value),
    type: type,
    unit: HealthDataUnit.MINUTE,
    dateFrom: DateTime.parse(from),
    dateTo: DateTime.parse(to),
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: '',
    sourceId: sourceId ?? source,
    sourceName: source,
  );
}

void main() {
  test('imports only supported watch records and does not double count sleep',
      () {
    final samples = AppleHealthNormalizer.normalize([
      point(HealthDataType.SLEEP_ASLEEP, '2026-10-26T23:00:00',
          '2026-10-27T01:00:00'),
      point(HealthDataType.SLEEP_LIGHT, '2026-10-26T23:00:00',
          '2026-10-27T00:30:00'),
      point(HealthDataType.SLEEP_DEEP, '2026-10-27T00:30:00',
          '2026-10-27T01:00:00'),
      point(HealthDataType.HEART_RATE_VARIABILITY_SDNN, '2026-10-27T07:00:00',
          '2026-10-27T07:00:01',
          value: 52),
      point(HealthDataType.RESTING_HEART_RATE, '2026-10-27T07:00:00',
          '2026-10-27T07:00:01',
          value: 48),
      point(HealthDataType.HEART_RATE, '2026-10-27T07:00:00',
          '2026-10-27T07:00:01',
          source: 'Other Watch', value: 100),
    ]);
    expect(samples, hasLength(1));
    expect(samples.single.sleepMinutes, 120);
    expect(samples.single.hrv, 52);
    expect(samples.single.restingHr, 48);
    expect(samples.single.heartRate, isNull);
    expect(samples.single.workoutMinutes, isNull);
    expect(samples.single.mode, 'LIVE');
  });

  test('missing supported watch records stay unavailable', () {
    expect(
        AppleHealthNormalizer.normalize([
          point(HealthDataType.HEART_RATE, '2026-10-27T07:00:00',
              '2026-10-27T07:00:01',
              source: 'Other Watch', value: 65)
        ]),
        isEmpty);
  });

  test('HRV read summary distinguishes selected and other readable sources',
      () {
    final hrvFromOtherSource = point(HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        '2026-10-27T07:00:00', '2026-10-27T07:00:01',
        source: 'Another Watch', value: 52);
    final summary = HealthReadSummary.fromPoints([hrvFromOtherSource],
        checkedAt: DateTime.parse('2026-10-27T08:00:00'));
    expect(summary.countFor(HealthSource.huawei), 0);
    expect(summary.supportedRecords, 0);
    expect(summary.otherHrvRecords, 1);
    expect(summary.hrvExplanation(HealthSource.huawei),
        contains('another source'));
    expect(AppleHealthNormalizer.normalize([hrvFromOtherSource]), isEmpty);
  });

  test('missing HRV does not infer it from heart rate', () {
    final summary = HealthReadSummary.fromPoints([
      point(HealthDataType.HEART_RATE, '2026-10-27T07:00:00',
          '2026-10-27T07:00:01',
          value: 48)
    ], checkedAt: DateTime.parse('2026-10-27T08:00:00'));
    expect(summary.countFor(HealthSource.huawei), 1);
    expect(summary.supportedRecords, 1);
    expect(summary.otherHrvRecords, 0);
    expect(summary.hrvExplanation(HealthSource.huawei), contains('No HRV'));
  });

  test('keeps Huawei, Garmin and Apple Watch readings separate', () {
    final samples = AppleHealthNormalizer.normalize([
      point(HealthDataType.SLEEP_ASLEEP, '2026-10-26T23:00:00',
          '2026-10-27T06:00:00',
          source: 'HUAWEI Health: Global'),
      point(HealthDataType.HEART_RATE, '2026-10-27T07:00:00',
          '2026-10-27T07:00:01',
          source: 'Connect', sourceId: 'com.garmin.connect.mobile', value: 63),
      point(HealthDataType.HEART_RATE_VARIABILITY_SDNN, '2026-10-27T07:00:00',
          '2026-10-27T07:00:01',
          source: 'Art’s Apple Watch', value: 57),
    ]);
    expect(samples, hasLength(3));
    expect(
        samples
            .singleWhere((s) => s.source == HealthSource.huawei)
            .sleepMinutes,
        420);
    expect(samples.singleWhere((s) => s.source == HealthSource.garmin).hrv,
        isNull);
    expect(samples.singleWhere((s) => s.source == HealthSource.appleWatch).hrv,
        57);
  });
}
