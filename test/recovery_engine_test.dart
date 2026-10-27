import 'package:flutter_test/flutter_test.dart';
import 'package:boxer_recovery/data/fightcamp_demo_source.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:boxer_recovery/domain/recovery_engine.dart';

/// Explicit test fixture; no synthetic wearable source is shipped in the app.
AthleteData seededAthlete() {
  final now = DateTime.now();
  final athlete = AthleteData(
      profile: AthleteProfile(
          name: 'Test athlete',
          fightDate: localDay(now.add(const Duration(days: 32)))));
  const MockFightCampSource().ensureDemoData(athlete, at: now);
  for (var daysAgo = 10; daysAgo >= 0; daysAgo--) {
    athlete.wearables.add(WearableSample(
        date: localDay(now.subtract(Duration(days: daysAgo))),
        source: 'Test fixture',
        mode: 'TEST',
        hrv: (daysAgo == 0 ? 58 : 69 + daysAgo % 4).toDouble(),
        restingHr: (daysAgo == 0 ? 47 : 41 + daysAgo % 3).toDouble(),
        sleepMinutes: daysAgo == 0 ? 342 : 430 + daysAgo % 4 * 12));
  }
  for (var daysAgo = 6; daysAgo >= 0; daysAgo--) {
    athlete.saveMorning(MorningCheckIn(
        date: localDay(now.subtract(Duration(days: daysAgo))),
        weight: 74.6 + daysAgo * .15,
        urine: 2,
        mood: daysAgo == 0 ? 'Low' : 'OK'));
  }
  return athlete;
}

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
    expect(assessment.observedCount, assessment.assessedCount);
  });

  test('Sleep remains available when the latest source reports only HRV', () {
    final athlete = AthleteData();
    athlete.wearables.add(WearableSample(
        date: localDay(),
        source: 'Test sleep fixture',
        mode: 'TEST',
        sleepMinutes: 437));
    athlete.wearables.add(WearableSample(
        date: localDay(), source: 'Test HRV fixture', mode: 'TEST', hrv: 66));
    expect(athlete.latestWearable?.sleepMinutes, isNull);
    expect(athlete.latestSleepSample?.sleepMinutes, 437);
    final assessment = RecoveryEngine().assess(athlete);
    expect(assessment.baselines['sleep']!.value, 437);
    expect(assessment.domains['sleep']!.status, 'INSUFFICIENT_DATA');
    expect(assessment.observedCount, assessment.assessedCount + 1);
    expect(RecoveryOverview.fromAssessment(assessment).score, isNull);
  });

  test('head symptoms override training even with baseline data', () {
    final athlete = seededAthlete();
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
    final athlete = seededAthlete();
    final assessment = RecoveryEngine().assess(athlete);
    expect(athlete.connections['fightcamp'], 'MOCK_CONNECTED');
    expect(athlete.latestFightCamp!.mode, 'DEMO');
    expect(assessment.baselines['punch']!.ready, isTrue);
    expect(assessment.domains['power']!.status, isNot('INSUFFICIENT_DATA'));
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

  test('long strength session with sore shoulder recommends resting that area',
      () {
    final athlete = AthleteData();
    athlete.sessions.add(TrainingSession(
        date: localDay(),
        type: 'Strength',
        duration: 90,
        intensity: 'Moderate',
        soreness: ['Shoulders']));
    final result = RecoveryEngine().assess(athlete);
    expect(result.domains['body']!.status, 'RESTRICTED');
    expect(result.limiter, 'body');
    expect(result.trainingGuidance['Strength']!.status, 'AVOID');
    expect(result.trainingGuidance['Strength']!.title, contains('Rest'));
    expect(result.trainingGuidance['Boxing / Technical']!.status, 'MODIFIED');
    expect(result.avoid, contains('Strength for affected area'));
    expect(result.allowed, isNot(contains('Strength')));
  });

  test('mild soreness after a short easy strength session modifies load', () {
    final athlete = AthleteData();
    athlete.sessions.add(TrainingSession(
        date: localDay(),
        type: 'Strength',
        duration: 20,
        intensity: 'Easy',
        soreness: ['Shoulders']));
    final result = RecoveryEngine().assess(athlete);
    expect(result.domains['body']!.status, 'CAUTION');
    expect(result.trainingGuidance['Strength']!.status, 'MODIFIED');
    expect(
        result.trainingGuidance['Conditioning']!.status, 'INSUFFICIENT_DATA');
  });

  test('painful shoulder after strength restricts affected loading', () {
    final session = TrainingSession(
        date: localDay(),
        type: 'Strength',
        duration: 30,
        intensity: 'Moderate',
        soreness: ['Shoulders'],
        painSeverity: 'Painful');
    expect(TrainingSession.fromJson(session.toJson()).painSeverity, 'Painful');
    final athlete = AthleteData()..sessions.add(session);
    final result = RecoveryEngine().assess(athlete);
    expect(result.trainingGuidance['Strength']!.status, 'AVOID');
    expect(result.trainingGuidance['Boxing / Technical']!.status, 'MODIFIED');
    expect(result.safety, isEmpty);
  });

  test('long hard conditioning limits intervals without restricting strength',
      () {
    final athlete = seededAthlete();
    athlete.sessions.add(TrainingSession(
        date: athlete.currentDay,
        type: 'Conditioning',
        duration: 90,
        intensity: 'Hard'));
    final result = RecoveryEngine().assess(athlete);
    expect(result.trainingGuidance['Conditioning']!.status, 'MODIFIED');
    expect(
        result.trainingGuidance['Conditioning']!.reason, contains('interval'));
    expect(result.avoid, contains('Hard conditioning'));
    expect(result.trainingGuidance['Strength']!.status, isNot('AVOID'));
  });

  test('long hard technical boxing changes body and power guidance', () {
    final athlete = seededAthlete();
    athlete.sessions.add(TrainingSession(
        date: athlete.currentDay,
        type: 'Boxing / Technical',
        duration: 90,
        intensity: 'Hard'));
    final result = RecoveryEngine().assess(athlete);
    expect(result.domains['body']!.status, 'CAUTION');
    expect(result.domains['power']!.status, 'CAUTION');
    expect(result.trainingGuidance['Boxing / Technical']!.status, 'MODIFIED');
    expect(result.trainingGuidance['Boxing / Technical']!.reason,
        contains('long hard technical'));
  });

  test('body restriction becomes primary limiter over equally restricted sleep',
      () {
    final athlete = seededAthlete();
    athlete.sessions.add(TrainingSession(
        date: athlete.currentDay,
        type: 'Strength',
        duration: 90,
        intensity: 'Moderate',
        soreness: ['Shoulders']));
    final result = RecoveryEngine().assess(athlete);
    expect(result.domains['sleep']!.status, 'RESTRICTED');
    expect(result.domains['body']!.status, 'RESTRICTED');
    expect(result.limiter, 'body');
  });

  test('severe pain safety overrides all four categories', () {
    final athlete = seededAthlete();
    athlete.sessions.add(TrainingSession(
        date: athlete.currentDay,
        type: 'Strength',
        duration: 20,
        intensity: 'Easy',
        soreness: ['Shoulders'],
        painSeverity: 'Severe'));
    final result = RecoveryEngine().assess(athlete);
    expect(result.safety.map((e) => e.code), contains('PHYSICAL'));
    expect(result.trainingGuidance.values.every((e) => e.status == 'AVOID'),
        isTrue);
    expect(result.allowed, isEmpty);
  });

  test('old training sessions do not drive todays guidance', () {
    final athlete = AthleteData();
    athlete.sessions.add(TrainingSession(
        date: localDay(DateTime.now().subtract(const Duration(days: 9))),
        type: 'Strength',
        duration: 90,
        intensity: 'Hard',
        soreness: ['Shoulders']));
    final result = RecoveryEngine().assess(athlete);
    expect(result.domains['body']!.status, 'INSUFFICIENT_DATA');
    expect(result.trainingGuidance['Strength']!.status, 'INSUFFICIENT_DATA');
  });
}
