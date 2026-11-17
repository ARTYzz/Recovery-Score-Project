import 'package:boxer_recovery/data/apple_health_source.dart';
import 'package:boxer_recovery/domain/health_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

HealthDataPoint point(HealthDataType type, String from, String to,
    {String source = 'HUAWEI Health: Global',
    String? sourceId,
    RecordingMethod recordingMethod = RecordingMethod.automatic,
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
    recordingMethod: recordingMethod,
  );
}

void main() {
  final huawei = HealthSource.fromProvenance(
      name: 'HUAWEI Health: Global', id: 'HUAWEI Health: Global')!;

  test('keeps source records separate and does not double count sleep', () {
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
    expect(samples, hasLength(2));
    final watch = samples.singleWhere((sample) => sample.source == huawei);
    expect(watch.sleepMinutes, 120);
    expect(watch.hrv, 52);
    expect(watch.restingHr, 48);
    expect(watch.heartRate, isNull);
    expect(watch.workoutMinutes, isNull);
    expect(watch.mode, 'LIVE');
  });

  test('records without any source identity stay unavailable', () {
    expect(
        AppleHealthNormalizer.normalize([
          point(HealthDataType.HEART_RATE, '2026-10-27T07:00:00',
              '2026-10-27T07:00:01',
              source: '', sourceId: '', value: 65)
        ]),
        isEmpty);
  });

  test('time in bed is reported but not counted as sleep', () {
    final inBed = point(HealthDataType.SLEEP_IN_BED, '2026-10-26T23:00:00',
        '2026-10-27T07:00:00',
        value: 0);
    final summary = HealthReadSummary.fromPoints([inBed],
        checkedAt: DateTime.parse('2026-10-27T08:00:00'));
    expect(summary.inBedRecords, 1);
    expect(summary.sleepDays, 0);
    expect(AppleHealthNormalizer.normalize([inBed]), isEmpty);
  });

  test('read summary distinguishes heart rate from resting heart rate', () {
    final heart = point(
        HealthDataType.HEART_RATE, '2026-10-27T07:00:00', '2026-10-27T07:00:01',
        value: 65);
    final summary = HealthReadSummary.fromPoints([heart],
        checkedAt: DateTime.parse('2026-10-27T08:00:00'));
    expect(summary.heartRateDays, 1);
    expect(summary.restingHrDays, 0);
  });

  test('empty HealthKit read reports no returned records, not missing sources',
      () {
    final summary = HealthReadSummary.fromPoints([], checkedAt: DateTime.now());
    expect(summary.returnedRecords, 0);
    expect(summary.emptyImportMessage(), contains('returned no'));
  });

  test('read summary distinguishes manual-only and unidentified records', () {
    final manual = point(
        HealthDataType.HEART_RATE, '2026-10-27T07:00:00', '2026-10-27T07:00:01',
        recordingMethod: RecordingMethod.manual, value: 65);
    final manualSummary =
        HealthReadSummary.fromPoints([manual], checkedAt: DateTime.now());
    expect(manualSummary.manualRecords, 1);
    expect(manualSummary.emptyImportMessage(), contains('manually entered'));

    final unidentified = point(
        HealthDataType.HEART_RATE, '2026-10-27T07:00:00', '2026-10-27T07:00:01',
        source: '', sourceId: '', value: 65);
    final sourceSummary =
        HealthReadSummary.fromPoints([unidentified], checkedAt: DateTime.now());
    expect(sourceSummary.unidentifiedRecords, 1);
    expect(sourceSummary.emptyImportMessage(), contains('identifiable source'));
  });

  test('manually entered Health records are not treated as wearable data', () {
    final manual = point(
        HealthDataType.HEART_RATE, '2026-10-27T07:00:00', '2026-10-27T07:00:01',
        source: 'Health',
        sourceId: 'com.apple.health',
        recordingMethod: RecordingMethod.manual,
        value: 65);
    expect(AppleHealthNormalizer.normalize([manual]), isEmpty);
  });

  test('HRV read summary distinguishes selected and other readable sources',
      () {
    final hrvFromOtherSource = point(HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        '2026-10-27T07:00:00', '2026-10-27T07:00:01',
        source: 'Another Watch', value: 52);
    final summary = HealthReadSummary.fromPoints([hrvFromOtherSource],
        checkedAt: DateTime.parse('2026-10-27T08:00:00'));
    expect(summary.countFor(huawei), 0);
    expect(summary.importedRecords, 1);
    expect(summary.otherHrvRecords, 0);
    expect(summary.hrvExplanation(huawei), contains('another source'));
    expect(AppleHealthNormalizer.normalize([hrvFromOtherSource]), hasLength(1));
  });

  test('missing HRV does not infer it from heart rate', () {
    final summary = HealthReadSummary.fromPoints([
      point(HealthDataType.HEART_RATE, '2026-10-27T07:00:00',
          '2026-10-27T07:00:01',
          value: 48)
    ], checkedAt: DateTime.parse('2026-10-27T08:00:00'));
    expect(summary.countFor(huawei), 1);
    expect(summary.importedRecords, 1);
    expect(summary.otherHrvRecords, 0);
    expect(summary.hrvExplanation(huawei), contains('No HRV'));
  });

  test('discovers Huawei, Garmin, Apple Watch and Da Ring dynamically', () {
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
      point(HealthDataType.SLEEP_ASLEEP, '2026-10-26T23:00:00',
          '2026-10-27T06:30:00',
          source: 'Da Ring', value: 1),
    ]);
    expect(samples, hasLength(4));
    expect(samples.singleWhere((s) => s.source == huawei).sleepMinutes, 420);
    final garmin = HealthSource.fromProvenance(
        name: 'Connect', id: 'com.garmin.connect.mobile')!;
    expect(samples.singleWhere((s) => s.source == garmin).hrv, isNull);
    expect(samples.singleWhere((s) => s.sourceName == 'Art’s Apple Watch').hrv,
        57);
    expect(samples.singleWhere((s) => s.sourceName == 'Da Ring').sleepMinutes,
        450);
  });

  test('Apple Health phone and watch names do not share one source key', () {
    final phone =
        HealthSource.fromProvenance(name: 'Health', id: 'com.apple.health');
    final watch = HealthSource.fromProvenance(
        name: 'Apple Watch', id: 'com.apple.health');
    expect(phone, isNot(watch));
  });
}
