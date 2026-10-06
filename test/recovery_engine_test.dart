import 'package:flutter_test/flutter_test.dart';
import 'package:boxer_recovery/data/mock_sources.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:boxer_recovery/domain/recovery_engine.dart';

void main() {
  test('missing wearable data stays unavailable and does not become zero', () {
    final athlete = AthleteData(
        profile: AthleteProfile(
            name: 'A',
            fightDate: localDay(DateTime.now().add(const Duration(days: 30)))));
    athlete.saveMorning(
        MorningCheckIn(date: localDay(), weight: 72, urine: 2, mood: 'OK'));
    final assessment = RecoveryEngine().assess(athlete);
    expect(athlete.latestWearable, isNull);
    expect(assessment.domains['sleep']!.status, 'INSUFFICIENT_DATA');
    expect(assessment.baselines['hrv']!.value, isNull);
  });

  test('head symptoms override training even with baseline data', () {
    final athlete = const DemoDataFactory().create();
    athlete.saveMorning(MorningCheckIn(
        date: localDay(),
        weight: 74.6,
        urine: 2,
        mood: 'Good',
        headSymptoms: true));
    final assessment = RecoveryEngine().assess(athlete);
    expect(assessment.safety.map((e) => e.code), contains('HEAD_SYMPTOMS'));
    expect(assessment.domains['brain']!.status, 'RESTRICTED');
    expect(assessment.limiter, 'brain');
    expect(assessment.avoid, contains('Sparring'));
    expect(assessment.allowed, isNot(contains('Sparring')));
    expect(RecoveryOverview.fromAssessment(assessment).score, lessThan(30));
  });

  test('FightCamp mock uses normalized session model and personal baseline',
      () {
    final athlete = const DemoDataFactory().create();
    final assessment = RecoveryEngine().assess(athlete);
    expect(athlete.connections['fightcamp'], 'MOCK_CONNECTED');
    expect(athlete.latestFightCamp!.mode, 'DEMO');
    expect(assessment.baselines['punch']!.ready, isTrue);
    expect(assessment.domains['power']!.status, isNot('INSUFFICIENT_DATA'));
  });

  test('disconnect removes mock health records', () {
    final athlete = AthleteData();
    const source = MockHealthSource('apple');
    source.seedHistory(athlete);
    expect(athlete.wearables, isNotEmpty);
    source.disconnect(athlete);
    expect(athlete.wearables, isEmpty);
  });

  test('daily check-in is due only on a new day', () {
    final athlete = AthleteData(onboardingStage: 'complete');
    expect(athlete.morningDue, isTrue);
    athlete.saveMorning(MorningCheckIn(date: localDay(), urine: 2, mood: 'OK'));
    expect(athlete.morningDue, isFalse);
  });

  test('sudden weight change is a safety flag without cut advice', () {
    final athlete = AthleteData();
    athlete.saveMorning(MorningCheckIn(
        date: localDay(DateTime.now().subtract(const Duration(days: 1))),
        weight: 75,
        urine: 2,
        mood: 'OK'));
    athlete.saveMorning(
        MorningCheckIn(date: localDay(), weight: 73.3, urine: 2, mood: 'OK'));
    final result = RecoveryEngine().assess(athlete);
    expect(result.safety.map((e) => e.code), contains('WEIGHT_CHANGE'));
    expect(result.domains['fuel']!.status, 'RESTRICTED');
    expect(result.limiter, 'fuel');
  });
}
