import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boxer_recovery/app/boxer_controller.dart';
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
    expect(app.route, 'baseline-intro');
    expect(app.data!.healthAcceptedAt, isNull);
    expect(app.data!.connections['mock'], 'MOCK_CONNECTED');
    expect(app.data!.latestWearable?.mode, 'DEMO');
    expect(app.data!.latestWearable?.source, 'Synthetic wearable demo');
    expect(app.data!.latestWearable?.sleepMinutes, 437);
    expect(app.data!.latestWearable?.hrv, 66);
    expect(app.data!.latestWearable?.restingHr, 48);
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
    await reopened.disconnectDemo('mock');
    expect(reopened.data!.latestWearable, isNull);
    await reopened.connectDemo('mock');
    expect(reopened.data!.latestWearable?.mode, 'DEMO');
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
