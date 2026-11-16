import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:boxer_recovery/domain/trends_dashboard.dart';
import 'package:boxer_recovery/ui/design.dart';
import 'package:boxer_recovery/ui/screens.dart';
import 'package:boxer_recovery/ui/screens/trends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AthleteData historyFixture() {
  final data = AthleteData();
  data.wearables.addAll([
    WearableSample(
        date: '2026-11-09',
        source: 'HealthKit',
        mode: 'LIVE',
        sleepMinutes: 420,
        restingHr: 52),
    WearableSample(
        date: '2026-11-11',
        source: 'HealthKit',
        mode: 'LIVE',
        sleepMinutes: 450,
        restingHr: 50,
        hrv: 56,
        workoutMinutes: 48),
    WearableSample(
        date: '2026-11-11', source: 'HealthKit', mode: 'LIVE', hrv: 58),
    WearableSample(
        date: '2026-10-15',
        source: 'HealthKit',
        mode: 'LIVE',
        sleepMinutes: 360,
        restingHr: 55),
  ]);
  data.sessions.addAll([
    TrainingSession(
        date: '2026-11-09',
        type: 'Sparring',
        duration: 30,
        intensity: 'Moderate'),
    TrainingSession(
        date: '2026-11-11', type: 'Strength', duration: 45, intensity: 'Easy'),
    TrainingSession(
        date: '2026-10-15',
        type: 'Conditioning',
        duration: 60,
        intensity: 'Hard'),
  ]);
  data.saveMorning(
      MorningCheckIn(date: '2026-11-11', weight: 74.2, urine: 2, mood: 'OK'));
  data.assessments.addAll([
    {
      'date': '2026-11-11',
      'limiter': 'body',
      'domainScores': {'body': 50, 'sleep': 70}
    },
    {
      'date': '2026-11-11',
      'limiter': 'sleep',
      'domainScores': {'body': 60, 'sleep': 75}
    },
  ]);
  return data;
}

void main() {
  test('day, week, month and year use calendar buckets', () {
    final date = DateTime(2026, 11, 11);
    expect(TrendWindow(TrendPeriod.day, date).buckets.length, 1);
    final week = TrendWindow(TrendPeriod.week, date);
    expect(localDay(week.start), '2026-11-09');
    expect(localDay(week.end), '2026-11-16');
    expect(TrendWindow(TrendPeriod.month, date).buckets.length, 30);
    expect(TrendWindow(TrendPeriod.year, date).buckets.length, 12);
    expect(localDay(week.shifted(-1).start), '2026-11-02');
  });

  test('health gaps stay null and readings are not summed or zero-filled', () {
    final data = historyFixture();
    final report = TrendsDashboard.fromData(
        data, TrendWindow(TrendPeriod.week, DateTime(2026, 11, 11)));
    expect(report.metrics['Sleep']!.values[0], 7);
    expect(report.metrics['Sleep']!.values[1], isNull);
    expect(report.metrics['Sleep']!.values[2], 7.5);
    expect(report.metrics['HRV']!.values[2], 58);
    expect(report.metrics['HRV']!.values[0], isNull);
    expect(report.metrics['Heart rate']!.latest, isNull);
    expect(report.metrics['Watch workout']!.values[2], 48);
  });

  test('training categories and latest daily assessment survive reload', () {
    final data = AthleteData.decode(historyFixture().encode());
    final report = TrendsDashboard.fromData(
        data, TrendWindow(TrendPeriod.week, DateTime(2026, 11, 11)));
    expect(report.trainingSessions['Sparring'], 1);
    expect(report.trainingMinutes['Sparring']![0], 30);
    expect(report.trainingMinutes['Strength']![2], 45);
    expect(report.trainingSessions['Conditioning'], 0);
    expect(report.domainScores['body']!.values[2], 60);
    expect(report.limiters['sleep'], 1);
    expect(report.limiters['body'], isNull);
  });

  test('year view averages only observed days within each month', () {
    final report = TrendsDashboard.fromData(historyFixture(),
        TrendWindow(TrendPeriod.year, DateTime(2026, 11, 11)));
    expect(report.metrics['Sleep']!.values[9], 6);
    expect(report.metrics['Sleep']!.values[10], 7.25);
    expect(report.metrics['Sleep']!.values[8], isNull);
    expect(report.trainingMinutes['Conditioning']![9], 60);
    expect(report.trainingMinutes['Sparring']![10], 30);
  });

  testWidgets('mobile Trends screen switches time range without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = BoxerController()
      ..data = historyFixture()
      ..busy = false;
    await tester.pumpWidget(MaterialApp(
        theme: boxerTheme(),
        home: Scaffold(
            body: SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: TrendsScreen(controller))))));
    expect(find.text('Trends'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('Daily readings · calendar month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile bottom navigation exposes Trends without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = BoxerController()
      ..data = historyFixture()
      ..busy = false
      ..route = 'trends';
    await tester.pumpWidget(MaterialApp(
        theme: boxerTheme(), home: AppScreens(controller: controller)));
    expect(find.text('Trends'), findsNWidgets(2));
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
