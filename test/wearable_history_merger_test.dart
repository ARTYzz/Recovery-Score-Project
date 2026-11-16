import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/data/athlete_vault.dart';
import 'package:boxer_recovery/data/huawei_apple_health_source.dart';
import 'package:boxer_recovery/data/wearable_history_merger.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:boxer_recovery/domain/trends_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const huawei = HuaweiAppleHealthSource.sourceName;

WearableSample sample(String day,
        {String source = huawei,
        int? sleep,
        double? hrv,
        double? rhr,
        double? heartRate,
        int? workout}) =>
    WearableSample(
      date: day,
      source: source,
      mode: 'LIVE',
      sleepMinutes: sleep,
      hrv: hrv,
      restingHr: rhr,
      heartRate: heartRate,
      workoutMinutes: workout,
    );

class FakeHuaweiHealthSource extends HuaweiAppleHealthSource {
  List<WearableSample> results = [];

  @override
  bool get supported => true;

  @override
  Future<List<WearableSample>> sync() async => results;

  @override
  Future<List<WearableSample>> connect() async => results;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preserves older history and merges partial readings on the same day',
      () {
    final athlete = AthleteData();
    athlete.wearables.addAll([
      sample('2026-09-01', sleep: 430, rhr: 49),
      sample('2026-11-12', sleep: 420, rhr: 50),
      sample('2026-11-12', source: 'Another source', heartRate: 78),
    ]);
    const merger = WearableHistoryMerger(huawei);
    merger.merge(athlete, [sample('2026-11-12', sleep: 450, hrv: 55)]);

    expect(athlete.wearables, hasLength(3));
    expect(athlete.wearables.first.sleepMinutes, 430);
    final updated = athlete.wearables.singleWhere(
        (record) => record.date == '2026-11-12' && record.source == huawei);
    expect(updated.sleepMinutes, 450);
    expect(updated.hrv, 55);
    expect(updated.restingHr, 50);
    expect(athlete.wearables.any((record) => record.source == 'Another source'),
        isTrue);

    merger.merge(athlete, [sample('2026-11-12', sleep: 450, hrv: 55)]);
    expect(athlete.wearables, hasLength(3));
  });

  test('empty sync keeps encrypted history and connected state after reopen',
      () async {
    SharedPreferences.setMockInitialValues({});
    final athlete = AthleteData(onboardingStage: 'complete');
    athlete.connections['apple'] = 'CONNECTED';
    athlete.healthAcceptedAt = '2026-09-01T08:00:00';
    athlete.wearables.add(sample('2026-09-01', sleep: 430));
    final vault = AthleteVault();
    await vault.create('test-passphrase', athlete);
    final source = FakeHuaweiHealthSource();
    final app = BoxerController(vault: vault, huaweiHealth: source)
      ..data = athlete
      ..busy = false;

    await app.syncHuaweiHealth();
    expect(app.data!.connections['apple'], 'CONNECTED');
    expect(app.data!.healthAcceptedAt, '2026-09-01T08:00:00');
    expect(app.data!.wearables.single.sleepMinutes, 430);
    expect(app.error, contains('Saved history is unchanged'));

    final reopened = await AthleteVault().unlock('test-passphrase');
    expect(reopened.connections['apple'], 'CONNECTED');
    expect(reopened.wearables.single.date, '2026-09-01');
  });

  test('later sync upserts new days without losing history on reload',
      () async {
    SharedPreferences.setMockInitialValues({});
    final athlete = AthleteData(onboardingStage: 'complete');
    athlete.connections['apple'] = 'CONNECTED';
    athlete.wearables.add(sample('2026-09-01', sleep: 430));
    final vault = AthleteVault();
    await vault.create('test-passphrase', athlete);
    final source = FakeHuaweiHealthSource()
      ..results = [sample('2026-11-12', sleep: 450, rhr: 48)];
    final app = BoxerController(vault: vault, huaweiHealth: source)
      ..data = athlete
      ..busy = false;

    await app.syncHuaweiHealth();
    await app.syncHuaweiHealth();
    final reopened = await AthleteVault().unlock('test-passphrase');
    expect(reopened.wearables, hasLength(2));
    expect(reopened.wearables.first.date, '2026-09-01');
    expect(reopened.wearables.last.sleepMinutes, 450);
    expect(reopened.wearables.last.restingHr, 48);
    final year = TrendsDashboard.fromData(
        reopened, TrendWindow(TrendPeriod.year, DateTime(2026, 11, 12)));
    expect(year.metrics['Sleep']!.values[8], 430 / 60);
    expect(year.metrics['Sleep']!.values[10], 7.5);
  });

  test('explicit disconnect still removes imported Huawei records', () async {
    SharedPreferences.setMockInitialValues({});
    final athlete = AthleteData(onboardingStage: 'complete');
    athlete.connections['apple'] = 'CONNECTED';
    athlete.wearables.addAll([
      sample('2026-09-01', sleep: 430),
      sample('2026-11-12', source: 'Another source', heartRate: 78),
    ]);
    final vault = AthleteVault();
    await vault.create('test-passphrase', athlete);
    final app =
        BoxerController(vault: vault, huaweiHealth: FakeHuaweiHealthSource())
          ..data = athlete
          ..busy = false;

    await app.disconnectHuaweiHealth();
    expect(app.data!.connections['apple'], 'DISCONNECTED');
    expect(app.data!.wearables, hasLength(1));
    expect(app.data!.wearables.single.source, 'Another source');
  });
}
