import 'package:boxer_recovery/data/huawei_apple_health_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

HealthDataPoint point(HealthDataType type, String from, String to,
    {String source = 'HUAWEI Health: Global', num value = 1}) {
  return HealthDataPoint(
    uuid: '$type-$from',
    value: NumericHealthValue(numericValue: value),
    type: type,
    unit: HealthDataUnit.MINUTE,
    dateFrom: DateTime.parse(from),
    dateTo: DateTime.parse(to),
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: '',
    sourceId: source,
    sourceName: source,
  );
}

void main() {
  test('imports only Huawei records and does not double count sleep', () {
    final samples = HuaweiHealthNormalizer.normalize([
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

  test('missing Huawei records stay unavailable', () {
    expect(
        HuaweiHealthNormalizer.normalize([
          point(HealthDataType.HEART_RATE, '2026-10-27T07:00:00',
              '2026-10-27T07:00:01',
              source: 'Other Watch', value: 65)
        ]),
        isEmpty);
  });
}
