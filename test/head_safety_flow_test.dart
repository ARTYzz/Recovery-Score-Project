import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/data/athlete_vault.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:boxer_recovery/domain/head_safety_tracker.dart';
import 'package:boxer_recovery/ui/design.dart';
import 'package:boxer_recovery/ui/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AthleteData athleteWithEarlierHeadConcern() {
  final athlete = AthleteData(onboardingStage: 'complete');
  athlete.saveMorning(MorningCheckIn(
      date: localDay(DateTime.now().subtract(const Duration(days: 1))),
      urine: 2,
      mood: 'OK',
      headSymptoms: true));
  athlete.saveMorning(MorningCheckIn(
      date: localDay(), urine: 2, mood: 'Good', headSymptoms: false));
  return athlete;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('external plan record persists but never suggests sparring clearance',
      () async {
    SharedPreferences.setMockInitialValues({});
    final athlete = athleteWithEarlierHeadConcern();
    final vault = AthleteVault();
    await vault.create('test-passphrase', athlete);
    final controller = BoxerController(vault: vault)
      ..data = athlete
      ..busy = false;

    await controller.recordExternalHeadPlan();
    final restored = await AthleteVault().unlock('test-passphrase');
    expect(restored.headSafetyReviews, hasLength(1));
    expect(HeadSafetyTracker(restored).hasExternalPlan, isTrue);
    final reopened = BoxerController()..data = restored;
    expect(
        reopened.assessment!.trainingGuidance['Sparring']!.status, 'MODIFIED');
    expect(reopened.assessment!.allowed, isNot(contains('Sparring')));
  });

  testWidgets('mobile Brain screen explains follow-up before recording a plan',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final athlete = athleteWithEarlierHeadConcern();
    final controller = BoxerController()
      ..data = athlete
      ..busy = false
      ..route = 'brain';
    await tester.pumpWidget(MaterialApp(
        theme: boxerTheme(),
        home: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => AppScreens(controller: controller))));

    expect(find.textContaining('A symptom-free morning'), findsOneWidget);
    final record = find.text('Record clinician guidance');
    await tester.ensureVisible(record);
    await tester.tap(record);
    await tester.pumpAndSettle();
    expect(find.textContaining('the app cannot verify'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(athlete.headSafetyReviews, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
