import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:boxer_recovery/domain/health_source.dart';
import 'package:boxer_recovery/ui/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RefreshController extends BoxerController {
  int reads = 0;
  @override
  Future<void> refreshToday() async {
    reads++;
    data!.wearables.add(WearableSample(
        date: localDay(),
        source:
            HealthSource.fromProvenance(name: 'Test watch', id: 'test.watch')!,
        sourceName: 'Test watch',
        sourceId: 'test.watch',
        mode: 'LIVE',
        sleepMinutes: 425,
        restingHr: 51));
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pulling Today down requests refresh and reveals new cards',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final athlete = AthleteData(onboardingStage: 'complete');
    athlete.connections['healthSource'] = HealthSource.huawei;
    athlete.wearables.add(WearableSample(
        date: localDay(),
        source: HealthSource.huawei,
        mode: 'LIVE',
        heartRate: 70));
    athlete.saveMorning(
        MorningCheckIn(date: localDay(), weight: 73, urine: 2, mood: 'OK'));
    final controller = RefreshController()
      ..data = athlete
      ..route = 'today'
      ..busy = false;

    await tester.pumpWidget(AnimatedBuilder(
        animation: controller,
        builder: (context, _) =>
            MaterialApp(home: AppScreens(controller: controller))));
    expect(find.text('Last sleep'), findsNothing);
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, 350));
    await tester.pumpAndSettle();

    expect(controller.reads, 1);
    expect(controller.busy, isFalse);
    expect(find.text('Last sleep'), findsOneWidget);
    expect(find.text('Resting HR'), findsOneWidget);
    expect(find.text('Last HRV'), findsNothing);
    expect(find.text('View only'), findsOneWidget);
    expect(find.text('Test watch · not in recovery score'), findsNWidgets(2));
    expect(
        controller.data!
            .latestVisibleHealthMetric((sample) => sample.sleepMinutes)
            ?.sleepMinutes,
        425);
    expect(controller.data!.latestSleepSample, isNull);
    expect(controller.data!.activeHealthSource, HealthSource.huawei);
    expect(tester.takeException(), isNull);
  });
}
