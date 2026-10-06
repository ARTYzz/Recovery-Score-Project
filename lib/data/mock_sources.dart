import '../domain/athlete_data.dart';

/// Prototype sources share the same normalized model as future authorized adapters.
class MockHealthSource {
  const MockHealthSource(this.kind);
  final String kind;

  String get sourceName => kind == 'apple'
      ? 'Apple Health demo'
      : kind == 'android'
          ? 'Health Connect demo'
          : 'Synthetic wearable demo';

  void connect(AthleteData data) => data.connections[kind] = 'MOCK_CONNECTED';
  void disconnect(AthleteData data) {
    data.connections[kind] = 'DISCONNECTED';
    data.wearables.removeWhere((sample) => sample.source == sourceName);
  }

  void sync(AthleteData data, WearableSample sample) {
    if (data.connections[kind] != 'MOCK_CONNECTED') return;
    data.wearables
        .removeWhere((e) => e.date == sample.date && e.source == sample.source);
    data.wearables.add(sample);
    data.wearables.sort((a, b) => a.date.compareTo(b.date));
  }

  void seedHistory(AthleteData data, {DateTime? at}) {
    connect(data);
    final now = at ?? DateTime.now();
    for (var daysAgo = 6; daysAgo >= 0; daysAgo--) {
      final date = localDay(now.subtract(Duration(days: daysAgo)));
      if (data.wearables.any((e) => e.date == date && e.source == sourceName)) {
        continue;
      }
      sync(
          data,
          WearableSample(
            date: date,
            source: sourceName,
            mode: 'DEMO',
            sleepMinutes: 420 + (daysAgo % 3) * 18,
            hrv: (64 + (daysAgo % 4) * 3).toDouble(),
            restingHr: (45 + (daysAgo % 3)).toDouble(),
            heartRate: (70 + (daysAgo % 5)).toDouble(),
            workoutMinutes: daysAgo.isEven ? 52 : 0,
          ));
    }
  }
}

class MockFightCampSource {
  const MockFightCampSource();

  void ensureDemoData(AthleteData data, {DateTime? at}) {
    if (data.connections['fightcamp'] == 'CONNECTED') return;
    data.connections['fightcamp'] = 'MOCK_CONNECTED';
    final now = at ?? DateTime.now();
    const samples = [
      (9, 63, 8.1, 77, 5),
      (6, 61, 7.9, 74, 6),
      (3, 64, 8.3, 79, 5),
      (0, 59, 7.7, 70, 6),
    ];
    for (final sample in samples) {
      final date = localDay(now.subtract(Duration(days: sample.$1)));
      final id = 'fightcamp-demo-$date';
      if (data.fightCampSessions.any((e) => e.sessionId == id)) continue;
      data.fightCampSessions.add(FightCampSession(
        date: date,
        source: 'FightCamp demo',
        mode: 'DEMO',
        sessionId: id,
        count: sample.$2,
        speed: sample.$3,
        output: sample.$4,
        rounds: sample.$5,
      ));
    }
    data.fightCampSessions.sort((a, b) => a.date.compareTo(b.date));
  }
}

class DemoDataFactory {
  const DemoDataFactory();
  AthleteData create({DateTime? at}) {
    final now = at ?? DateTime.now();
    final data = AthleteData(
      profile: AthleteProfile(
          name: 'Demo Boxer',
          fightDate: localDay(now.add(const Duration(days: 32))),
          officialWeighInWeight: 72.5),
      privacyAcceptedAt: now.toIso8601String(),
      healthAcceptedAt: now.toIso8601String(),
      onboardingStage: 'complete',
      mockOnly: true,
      demoAnchorDay: localDay(now),
    );
    data.connections['mock'] = 'MOCK_CONNECTED';
    const MockFightCampSource().ensureDemoData(data, at: now);
    for (var daysAgo = 10; daysAgo >= 0; daysAgo--) {
      data.wearables.add(WearableSample(
        date: localDay(now.subtract(Duration(days: daysAgo))),
        source: 'Synthetic wearable demo',
        mode: 'DEMO',
        hrv: (daysAgo == 0 ? 58 : 69 + daysAgo % 4).toDouble(),
        restingHr: (daysAgo == 0 ? 47 : 41 + daysAgo % 3).toDouble(),
        sleepMinutes: daysAgo == 0 ? 342 : 430 + daysAgo % 4 * 12,
        heartRate: (72 + daysAgo % 5).toDouble(),
        workoutMinutes: daysAgo.isOdd ? 45 : 70,
      ));
    }
    data.sessions.addAll([
      TrainingSession(
          date: localDay(now.subtract(const Duration(days: 3))),
          type: 'Boxing / Technical',
          duration: 60,
          intensity: 'Moderate'),
      TrainingSession(
          date: localDay(now.subtract(const Duration(days: 2))),
          type: 'Strength',
          duration: 45,
          intensity: 'Moderate'),
      TrainingSession(
          date: localDay(now.subtract(const Duration(days: 1))),
          type: 'Sparring',
          duration: 50,
          intensity: 'Moderate',
          rounds: 5,
          contact: 'Moderate'),
    ]);
    for (var daysAgo = 6; daysAgo >= 1; daysAgo--) {
      data.saveMorning(MorningCheckIn(
          date: localDay(now.subtract(Duration(days: daysAgo))),
          weight: 74.6 + daysAgo * .15,
          urine: 2,
          mood: 'OK'));
    }
    data.saveMorning(MorningCheckIn(
        date: localDay(now), weight: 74.6, urine: 2, mood: 'Low'));
    for (final sample in data.wearables.skip(4)) {
      data.assessments.add({
        'date': sample.date,
        'limiter': sample.sleepMinutes != null && sample.sleepMinutes! < 390
            ? 'sleep'
            : null,
        'domains': {
          'brain': 'INSUFFICIENT_DATA',
          'fuel': 'READY',
          'sleep': sample.sleepMinutes != null && sample.sleepMinutes! < 390
              ? 'CAUTION'
              : 'READY',
          'power': 'INSUFFICIENT_DATA',
          'body': 'INSUFFICIENT_DATA',
          'mind':
              sample.date == localDay(now) ? 'CAUTION' : 'INSUFFICIENT_DATA',
        },
        'safety': <String>[],
      });
    }
    return data;
  }
}
