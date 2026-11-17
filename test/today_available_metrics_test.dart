import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:boxer_recovery/domain/health_source.dart';
import 'package:boxer_recovery/ui/components.dart';
import 'package:boxer_recovery/ui/screens/home_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Today shows only available health values and updates after sync',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final athlete = AthleteData();
    final healthSource =
        HealthSource.fromProvenance(name: 'Test watch', id: 'test.watch')!;
    final controller = BoxerController()..data = athlete;
    Future<void> showToday() async => tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(child: TodayScreen(controller)))));

    await showToday();
    expect(find.text('Last sleep'), findsNothing);
    expect(find.text('Last HRV'), findsNothing);
    expect(find.text('Resting HR'), findsNothing);
    expect(find.byType(MetricTile), findsNothing);
    expect(find.text('Connected data'), findsNothing);

    athlete.wearables.add(WearableSample(
        date: athlete.currentDay,
        source: healthSource,
        mode: 'LIVE',
        heartRate: 72));
    await showToday();
    expect(find.text('Last HR'), findsOneWidget);
    expect(find.text('Resting HR'), findsNothing);
    athlete.wearables.clear();

    athlete.wearables.add(WearableSample(
        date: athlete.currentDay,
        source: healthSource,
        mode: 'LIVE',
        restingHr: 51));
    await showToday();
    expect(find.text('Resting HR'), findsOneWidget);
    expect(find.byType(MetricTile), findsOneWidget);
    expect(find.text('Last sleep'), findsNothing);
    expect(find.text('Last HRV'), findsNothing);

    athlete.wearables.add(WearableSample(
        date: athlete.currentDay, source: healthSource, mode: 'LIVE', hrv: 62));
    await showToday();
    expect(find.text('Last sleep'), findsNothing);
    expect(find.text('Last HRV'), findsOneWidget);
    expect(find.text('Resting HR'), findsOneWidget);
    expect(find.byType(MetricTile), findsNWidgets(2));

    athlete.wearables.add(WearableSample(
        date: athlete.currentDay,
        source: healthSource,
        mode: 'LIVE',
        sleepMinutes: 425));
    await showToday();
    expect(find.text('Last sleep'), findsOneWidget);
    expect(find.text('7 h 5 min'), findsOneWidget);
    expect(find.byType(MetricTile), findsNWidgets(2));
    expect(find.textContaining('Unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
