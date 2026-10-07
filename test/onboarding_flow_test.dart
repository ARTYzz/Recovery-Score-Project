import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/data/athlete_vault.dart';
import 'package:boxer_recovery/data/mock_sources.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new athlete receives clearly labelled demo wearable data automatically',
      () async {
    SharedPreferences.setMockInitialValues({});
    final app = BoxerController();
    await app.initialize();
    expect(app.route, 'setup');
    await app.createProfile(
        name: 'Boxer',
        fightDate: localDay(DateTime.now().add(const Duration(days: 30))),
        passphrase: 'test-passphrase',
        privacyAccepted: true);
    expect(app.route, 'health-preview');
    expect(app.data!.healthAcceptedAt, isNull);
    expect(app.data!.connections['apple'], 'MOCK_CONNECTED');
    expect(app.data!.connections['android'], 'MOCK_CONNECTED');
    expect(app.data!.latestWearable?.mode, 'DEMO');
    expect(app.data!.wearables.map((sample) => sample.source),
        containsAll(['Apple Health demo', 'Health Connect demo']));
    expect(app.data!.latestWearable?.sleepMinutes, 437);
    expect(app.data!.latestWearable?.hrv, 66);
    expect(app.data!.latestWearable?.restingHr, 48);
    app.lock();
    await app.unlock('test-passphrase');
    expect(app.route, 'health-preview');
    await app.continueFromHealthPreview();
    expect(app.route, 'baseline-intro');
    await app.start();
    expect(app.route, 'morning');
    await app.saveMorning(
        MorningCheckIn(date: localDay(), weight: 73, urine: 2, mood: 'OK'));
    expect(app.route, 'today');
    app.lock();
    await app.unlock('test-passphrase');
    expect(app.route, 'today');
    expect(app.data!.latestWearable?.hrv, 66);
    expect(app.data!.connections['fightcamp'], 'MOCK_CONNECTED');
    final reopened = BoxerController();
    await reopened.initialize();
    expect(reopened.route, 'unlock');
    await reopened.unlock('test-passphrase');
    expect(reopened.data!.latestWearable?.sleepMinutes, 437);
    await reopened.disconnectDemo('apple');
    expect(reopened.data!.connections['apple'], 'DISCONNECTED');
    expect(reopened.data!.latestWearable, isNotNull);
    await reopened.disconnectDemo('android');
    expect(reopened.data!.latestWearable, isNull);
    reopened.lock();
    await reopened.unlock('test-passphrase');
    expect(reopened.data!.connections['apple'], 'DISCONNECTED');
    expect(reopened.data!.connections['android'], 'DISCONNECTED');
    expect(reopened.data!.latestWearable, isNull);
    await reopened.connectDemo('apple');
    expect(reopened.data!.connections['android'], 'DISCONNECTED');
    expect(reopened.data!.latestWearable?.mode, 'DEMO');
  });

  test('demo Sleep is synced for a new day and never duplicated on reopen', () {
    final athlete = AthleteData(
        mockOnly: true, demoAnchorDay: localDay(), onboardingStage: 'complete');
    const sources = AutomaticDemoHealthSources();
    sources.ensure(athlete);
    final firstDay = athlete.currentDay;
    expect(athlete.latestSleepSample?.sleepMinutes, 437);
    athlete.demoDayOffset = 1;
    sources.ensure(athlete);
    expect(athlete.currentDay, isNot(firstDay));
    expect(
        athlete.wearables
            .where((sample) =>
                sample.date == athlete.currentDay &&
                sample.sleepMinutes != null)
            .length,
        2);
    sources.ensure(athlete);
    expect(athlete.wearables.length, 4);
  });

  test('existing generic demo records migrate once and preserve source history',
      () async {
    SharedPreferences.setMockInitialValues({});
    final athlete = AthleteData(onboardingStage: 'complete');
    athlete.connections['mock'] = 'MOCK_CONNECTED';
    for (var daysAgo = 6; daysAgo >= 0; daysAgo--) {
      athlete.wearables.add(WearableSample(
          date: localDay(DateTime.now().subtract(Duration(days: daysAgo))),
          source: 'Synthetic wearable demo',
          mode: 'DEMO',
          sleepMinutes: 420,
          hrv: 65,
          restingHr: 48));
    }
    await AthleteVault().create('test-passphrase', athlete);
    final app = BoxerController();
    await app.initialize();
    await app.unlock('test-passphrase');
    expect(app.data!.connections['apple'], 'MOCK_CONNECTED');
    expect(app.data!.connections['android'], 'MOCK_CONNECTED');
    expect(app.data!.wearables.length, 14);
    expect(
        app.data!.wearables
            .where((sample) => sample.source == 'Synthetic wearable demo'),
        isEmpty);
    app.lock();
    await app.unlock('test-passphrase');
    expect(app.data!.wearables.length, 14);
  });

  test('demo runs the full daily loop and survives app reload', () async {
    SharedPreferences.setMockInitialValues({});
    final app = BoxerController();
    await app.initialize();
    await app.tryDemo();
    final firstDay = app.data!.currentDay;
    expect(app.route, 'today');
    await app.saveTraining(TrainingSession(
        date: firstDay,
        type: 'Boxing / Technical',
        duration: 45,
        intensity: 'Moderate'));
    expect(app.route, 'nutrition');
    await app.saveNutrition(NutritionCheck(
        date: firstDay, meal: 'Yes', protein: 'Yes', carbs: 'Medium'));
    expect(app.route, 'today');
    await app.completeAction(DateTime.now());
    expect(
        app.data!.actions.where((action) => action.date == firstDay).length, 1);
    await app.advanceMockDay();
    expect(app.route, 'morning');
    expect(app.data!.currentDay, isNot(firstDay));
    final beforeCheckIn = BoxerController();
    await beforeCheckIn.initialize();
    expect(beforeCheckIn.route, 'morning');
    await beforeCheckIn.saveMorning(MorningCheckIn(
        date: beforeCheckIn.data!.currentDay,
        weight: 74.5,
        urine: 2,
        mood: 'Good'));
    expect(beforeCheckIn.route, 'feedback');
    expect(beforeCheckIn.data!.actions.last.nextDay, isNotNull);
    expect(
        beforeCheckIn.feedback
            .insight(beforeCheckIn.data!, beforeCheckIn.data!.actions.last.id)
            .detail,
        contains('Next morning'));
    beforeCheckIn.navigate('today');
    final afterReload = BoxerController();
    await afterReload.initialize();
    expect(afterReload.route, 'today');
    expect(
        afterReload.data!.sessions.any(
            (session) => session.date == firstDay && session.duration == 45),
        isTrue);
    expect(afterReload.data!.nutrition.any((entry) => entry.date == firstDay),
        isTrue);
    expect(afterReload.data!.demoDayOffset, 1);
  });
}
