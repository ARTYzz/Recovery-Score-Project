import '../domain/athlete_data.dart';

/// The only synthetic runtime source until an authorized FightCamp API exists.
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
