import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/data/athlete_vault.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:boxer_recovery/domain/recovery_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new athlete starts without fabricated wearable data', () async {
    SharedPreferences.setMockInitialValues({});
    final app = BoxerController();
    await app.initialize();
    expect(app.route, 'setup');
    await app.createProfile(
        name: 'Boxer',
        fightDate: localDay(DateTime.now().add(const Duration(days: 30))),
        passphrase: 'test-passphrase',
        privacyAccepted: true,
        currentWeight: 73,
        heightCm: 175,
        targetWeight: 75);
    expect(app.route, 'health-preview');
    expect(app.data!.wearables, isEmpty);
    expect(app.data!.connections['apple'], isNull);
    expect(app.data!.latestSleepSample, isNull);
    expect(app.data!.latestMetricSample((sample) => sample.hrv), isNull);
    await app.continueFromHealthPreview();
    await app.start();
    expect(app.route, 'morning');
    expect(app.data!.connections['fightcamp'], 'MOCK_CONNECTED');
    expect(app.data!.latestFightCamp!.mode, 'DEMO');
    await app.saveMorning(
        MorningCheckIn(date: localDay(), weight: 74, urine: 2, mood: 'OK'));
    expect(app.route, 'today');

    final reopened = BoxerController();
    await reopened.initialize();
    expect(reopened.route, 'unlock');
    await reopened.unlock('test-passphrase');
    expect(reopened.route, 'today');
    expect(reopened.data!.wearables, isEmpty);
    expect(reopened.data!.checkins, hasLength(1));
    expect(reopened.data!.connections['fightcamp'], 'MOCK_CONNECTED');
    expect(reopened.data!.profile!.currentWeight, 74);
    expect(reopened.data!.profile!.heightCm, 175);
    expect(reopened.data!.profile!.targetWeight, 75);
  });

  test('old synthetic health is removed while manual and live data survive',
      () async {
    SharedPreferences.setMockInitialValues({});
    final athlete = AthleteData(
        profile: AthleteProfile(
            name: 'Boxer',
            fightDate: localDay(DateTime.now().add(const Duration(days: 30)))),
        onboardingStage: 'complete',
        schemaVersion: 1);
    athlete.connections['apple'] = 'MOCK_CONNECTED';
    athlete.connections['android'] = 'MOCK_CONNECTED';
    athlete.wearables.addAll([
      WearableSample(
          date: localDay(),
          source: 'Apple Health demo',
          mode: 'DEMO',
          sleepMinutes: 437),
      WearableSample(
          date: localDay(),
          source: 'Imported wearable',
          mode: 'LIVE',
          restingHr: 48),
    ]);
    athlete.saveMorning(
        MorningCheckIn(date: localDay(), weight: 73, urine: 2, mood: 'OK'));
    athlete.sessions.add(TrainingSession(
        date: localDay(),
        type: 'Strength',
        duration: 40,
        intensity: 'Moderate'));
    athlete.assessments.add({'date': localDay(), 'limiter': 'sleep'});
    await AthleteVault().create('test-passphrase', athlete);

    final app = BoxerController();
    await app.initialize();
    await app.unlock('test-passphrase');
    expect(app.data!.wearables, hasLength(1));
    expect(app.data!.wearables.single.mode, 'LIVE');
    expect(app.data!.connections['apple'], isNull);
    expect(app.data!.connections['android'], isNull);
    expect(app.data!.assessments, isEmpty);
    expect(app.data!.checkins, hasLength(1));
    expect(app.data!.sessions, hasLength(1));
    expect(app.data!.connections['fightcamp'], 'MOCK_CONNECTED');

    final reopened = BoxerController();
    await reopened.initialize();
    await reopened.unlock('test-passphrase');
    expect(reopened.data!.wearables, hasLength(1));
    expect(reopened.data!.wearables.single.mode, 'LIVE');
    expect(reopened.data!.checkins, hasLength(1));
    expect(reopened.data!.sessions, hasLength(1));
    expect(reopened.data!.assessments, isEmpty);
  });

  test('retired full demo account opens real profile setup', () async {
    SharedPreferences.setMockInitialValues({});
    final athlete = AthleteData(
        profile: AthleteProfile(
            name: 'Demo Boxer',
            fightDate: localDay(DateTime.now().add(const Duration(days: 30)))));
    await AthleteVault().create('demo-passphrase', athlete);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AthleteVault.demoKey, true);

    final app = BoxerController();
    await app.initialize();
    expect(app.route, 'setup');
    await app.createProfile(
        name: 'Real Athlete',
        fightDate: localDay(DateTime.now().add(const Duration(days: 30))),
        passphrase: 'new-passphrase',
        privacyAccepted: true,
        currentWeight: 73,
        heightCm: 175);
    expect(app.data!.profile!.name, 'Real Athlete');
    expect(await app.vault.demoAutoUnlockEnabled(), isFalse);
  });

  test('profile measurements and target can be edited and persist', () async {
    SharedPreferences.setMockInitialValues({});
    final app = BoxerController();
    await app.initialize();
    final fightDate = localDay(DateTime.now().add(const Duration(days: 40)));
    await app.createProfile(
        name: 'Boxer',
        fightDate: fightDate,
        passphrase: 'test-passphrase',
        privacyAccepted: true,
        currentWeight: 74,
        heightCm: 176,
        targetWeight: 72);
    await app.updateProfile(AthleteProfile(
        name: 'Updated Boxer',
        fightDate: fightDate,
        currentWeight: 75,
        heightCm: 177,
        targetWeight: 78));
    final reopened = await AthleteVault().unlock('test-passphrase');
    expect(reopened.profile!.name, 'Updated Boxer');
    expect(reopened.profile!.currentWeight, 75);
    expect(reopened.profile!.heightCm, 177);
    expect(reopened.profile!.targetWeight, 78);
  });

  test('old weigh-in weight is read as target weight', () {
    final profile = AthleteProfile.fromJson({
      'name': 'Boxer',
      'fightDate': '2027-01-01',
      'officialWeighInWeight': 70.5,
    });
    expect(profile.targetWeight, 70.5);
  });

  test('profile requires current weight and height but target is optional',
      () async {
    SharedPreferences.setMockInitialValues({});
    final app = BoxerController();
    await app.initialize();
    final fightDate = localDay(DateTime.now().add(const Duration(days: 40)));
    await expectLater(
        app.createProfile(
            name: 'Boxer',
            fightDate: fightDate,
            passphrase: 'test-passphrase',
            privacyAccepted: true,
            heightCm: 175),
        throwsFormatException);
    await app.createProfile(
        name: 'Boxer',
        fightDate: fightDate,
        passphrase: 'test-passphrase',
        privacyAccepted: true,
        currentWeight: 74,
        heightCm: 175);
    expect(app.data!.profile!.targetWeight, isNull);
  });

  test('athlete can start without a fight date and schedule one later',
      () async {
    SharedPreferences.setMockInitialValues({});
    final app = BoxerController();
    await app.initialize();
    await app.createProfile(
        name: 'Boxer',
        passphrase: 'test-passphrase',
        privacyAccepted: true,
        currentWeight: 74,
        heightCm: 175);
    expect(app.data!.profile!.fightDate, isNull);
    expect(CampClock.fromProfile(app.data!.profile).phase, 'NO_CAMP');
    await app.continueFromHealthPreview();
    await app.start();
    final nextFight = localDay(DateTime.now().add(const Duration(days: 30)));
    await app.updateProfile(AthleteProfile(
        name: 'Boxer', fightDate: nextFight, currentWeight: 74, heightCm: 175));
    final reopened = await AthleteVault().unlock('test-passphrase');
    expect(reopened.profile!.fightDate, nextFight);
  });

  test('fight stays scheduled on fight day and expires the following day', () {
    final profile = AthleteProfile(
        name: 'Boxer',
        fightDate: '2026-11-15',
        currentWeight: 74,
        heightCm: 175,
        targetWeight: 72);
    expect(
        profile.archiveExpiredFight(DateTime(2026, 11, 15, 23, 59)), isFalse);
    expect(CampClock.fromProfile(profile, DateTime(2026, 11, 15)).daysOut, 0);
    expect(profile.archiveExpiredFight(DateTime(2026, 11, 16)), isTrue);
    expect(profile.fightDate, isNull);
    expect(profile.targetWeight, isNull);
    expect(profile.pastFightPlans.single.date, '2026-11-15');
    expect(profile.pastFightPlans.single.targetWeight, 72);
    expect(profile.archiveExpiredFight(DateTime(2026, 11, 17)), isFalse);
    expect(profile.pastFightPlans, hasLength(1));
    expect(CampClock.fromProfile(profile, DateTime(2026, 11, 16)).phase,
        'NO_CAMP');
  });

  test('expired fight is archived and persisted when account unlocks',
      () async {
    SharedPreferences.setMockInitialValues({});
    final past = localDay(DateTime.now().subtract(const Duration(days: 1)));
    final athlete = AthleteData(
        profile: AthleteProfile(
            name: 'Boxer',
            fightDate: past,
            currentWeight: 74,
            heightCm: 175,
            targetWeight: 72),
        onboardingStage: 'complete');
    await AthleteVault().create('test-passphrase', athlete);
    final app = BoxerController();
    await app.initialize();
    await app.unlock('test-passphrase');
    expect(app.data!.profile!.fightDate, isNull);
    final reopened = await AthleteVault().unlock('test-passphrase');
    expect(reopened.profile!.fightDate, isNull);
    expect(reopened.profile!.pastFightPlans.single.date, past);
    final next = localDay(DateTime.now().add(const Duration(days: 30)));
    await app.updateProfile(AthleteProfile(
        name: 'Boxer',
        fightDate: next,
        currentWeight: 74,
        heightCm: 175,
        targetWeight: 73));
    final withNextFight = await AthleteVault().unlock('test-passphrase');
    expect(withNextFight.profile!.fightDate, next);
    expect(withNextFight.profile!.pastFightPlans.single.date, past);
  });

  test('returning to the app also persists fight rollover', () async {
    SharedPreferences.setMockInitialValues({});
    final past = localDay(DateTime.now().subtract(const Duration(days: 1)));
    final athlete = AthleteData(
        profile: AthleteProfile(
            name: 'Boxer', fightDate: past, currentWeight: 74, heightCm: 175),
        onboardingStage: 'complete');
    athlete.saveMorning(
        MorningCheckIn(date: localDay(), weight: 74, urine: 2, mood: 'OK'));
    final vault = AthleteVault();
    await vault.create('test-passphrase', athlete);
    final app = BoxerController(vault: vault)
      ..data = athlete
      ..busy = false;
    await app.refreshDailyGate();
    final reopened = await AthleteVault().unlock('test-passphrase');
    expect(reopened.profile!.fightDate, isNull);
    expect(reopened.profile!.pastFightPlans.single.date, past);
  });
}
