import '../domain/athlete_data.dart';

/// Preserves previously imported days while refreshing the days returned by
/// the current health query. A null in a partial response means unavailable
/// in that response, not that an earlier reading was zero or deleted.
class WearableHistoryMerger {
  const WearableHistoryMerger(this.source);

  final String source;

  void merge(AthleteData athlete, Iterable<WearableSample> updates) {
    final history = <String, WearableSample>{};
    final otherSources = <WearableSample>[];

    for (final sample in athlete.wearables) {
      if (sample.source == source) {
        history.update(sample.date, (prior) => _combine(prior, sample),
            ifAbsent: () => sample);
      } else {
        otherSources.add(sample);
      }
    }
    for (final sample in updates) {
      if (sample.source != source) continue;
      history.update(sample.date, (prior) => _combine(prior, sample),
          ifAbsent: () => sample);
    }

    athlete.wearables
      ..clear()
      ..addAll(otherSources)
      ..addAll(history.values)
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.source.compareTo(b.source);
      });
  }

  WearableSample _combine(WearableSample prior, WearableSample update) =>
      WearableSample(
        date: update.date,
        source: source,
        mode: update.mode,
        sleepMinutes: update.sleepMinutes ?? prior.sleepMinutes,
        hrv: update.hrv ?? prior.hrv,
        restingHr: update.restingHr ?? prior.restingHr,
        heartRate: update.heartRate ?? prior.heartRate,
        workoutMinutes: update.workoutMinutes ?? prior.workoutMinutes,
      );
}
