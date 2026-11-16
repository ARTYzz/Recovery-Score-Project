import 'athlete_data.dart';
import 'recovery_engine.dart';

enum TrendPeriod { day, week, month, year }

const trainingTypes = [
  'Sparring',
  'Boxing / Technical',
  'Conditioning',
  'Strength',
];

class TrendBucket {
  const TrendBucket(this.start, this.end, this.label);
  final DateTime start;
  final DateTime end;
  final String label;

  bool contains(String date) {
    final day = parsedDay(date);
    return day != null && !day.isBefore(start) && day.isBefore(end);
  }
}

/// A calendar window. Every chart uses the same buckets and date range.
class TrendWindow {
  TrendWindow(TrendPeriod period, DateTime anchor)
      : period = period,
        anchor = DateTime(anchor.year, anchor.month, anchor.day),
        buckets = _buckets(period, anchor);

  final TrendPeriod period;
  final DateTime anchor;
  final List<TrendBucket> buckets;

  DateTime get start => buckets.first.start;
  DateTime get end => buckets.last.end;

  bool get includesToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(start) && today.isBefore(end);
  }

  TrendWindow shifted(int amount) {
    final moved = switch (period) {
      TrendPeriod.day => anchor.add(Duration(days: amount)),
      TrendPeriod.week => anchor.add(Duration(days: amount * 7)),
      TrendPeriod.month => DateTime(anchor.year, anchor.month + amount, 1),
      TrendPeriod.year => DateTime(anchor.year + amount, 1, 1),
    };
    return TrendWindow(period, moved);
  }

  static List<TrendBucket> _buckets(TrendPeriod period, DateTime anchor) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    switch (period) {
      case TrendPeriod.day:
        return [
          TrendBucket(day, day.add(const Duration(days: 1)), '${day.day}')
        ];
      case TrendPeriod.week:
        final monday = day.subtract(Duration(days: day.weekday - 1));
        return List.generate(7, (i) {
          final start = monday.add(Duration(days: i));
          return TrendBucket(start, start.add(const Duration(days: 1)),
              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i]);
        });
      case TrendPeriod.month:
        final count = DateTime(day.year, day.month + 1, 0).day;
        return List.generate(count, (i) {
          final start = DateTime(day.year, day.month, i + 1);
          return TrendBucket(
              start, start.add(const Duration(days: 1)), '${i + 1}');
        });
      case TrendPeriod.year:
        return List.generate(12, (i) {
          final start = DateTime(day.year, i + 1, 1);
          return TrendBucket(start, DateTime(day.year, i + 2, 1),
              ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][i]);
        });
    }
  }
}

class TrendSeries {
  const TrendSeries(this.values);
  final List<double?> values;
  int get observedBuckets => values.whereType<double>().length;
  double? get latest {
    for (final value in values.reversed) {
      if (value != null) return value;
    }
    return null;
  }
}

class TrendsDashboard {
  TrendsDashboard._(
      this.window,
      this.metrics,
      this.trainingMinutes,
      this.trainingSessions,
      this.domainScores,
      this.limiters,
      this.completedActions);

  final TrendWindow window;
  final Map<String, TrendSeries> metrics;
  final Map<String, List<int>> trainingMinutes;
  final Map<String, int> trainingSessions;
  final Map<String, TrendSeries> domainScores;
  final Map<String, int> limiters;
  final int completedActions;

  factory TrendsDashboard.fromData(AthleteData data, TrendWindow window) {
    // Keep the last non-null reading of each metric on a calendar day.
    final sleep = <String, double>{};
    final hrv = <String, double>{};
    final rhr = <String, double>{};
    final heartRate = <String, double>{};
    final workout = <String, double>{};
    for (final sample in data.activeWearables) {
      if (sample.sleepMinutes != null) {
        sleep[sample.date] = sample.sleepMinutes!.toDouble() / 60;
      }
      if (sample.hrv != null) hrv[sample.date] = sample.hrv!;
      if (sample.restingHr != null) rhr[sample.date] = sample.restingHr!;
      if (sample.heartRate != null) heartRate[sample.date] = sample.heartRate!;
      if (sample.workoutMinutes != null) {
        workout[sample.date] = sample.workoutMinutes!.toDouble();
      }
    }
    final weight = <String, double>{
      for (final check in data.checkins)
        if (check.weight != null) check.date: check.weight!,
    };
    final punches = <String, double>{
      for (final session in data.fightCampSessions)
        if (session.count != null) session.date: session.count!.toDouble(),
    };
    final latestAssessments = <String, Map<String, dynamic>>{};
    for (final snapshot in data.assessments) {
      final date = snapshot['date'];
      if (date is String) latestAssessments[date] = snapshot;
    }
    final domainDaily = <String, Map<String, double>>{
      for (final key in domainKeys) key: <String, double>{},
    };
    final limiters = <String, int>{};
    for (final entry in latestAssessments.entries) {
      if (!window.buckets.any((bucket) => bucket.contains(entry.key))) continue;
      final rawScores = entry.value['domainScores'];
      if (rawScores is Map) {
        for (final key in domainKeys) {
          final value = rawScores[key];
          if (value is num) domainDaily[key]![entry.key] = value.toDouble();
        }
      }
      final limiter = entry.value['limiter'];
      if (limiter is String && domainKeys.contains(limiter)) {
        limiters[limiter] = (limiters[limiter] ?? 0) + 1;
      }
    }
    final trainingMinutes = <String, List<int>>{
      for (final type in trainingTypes)
        type: List<int>.filled(window.buckets.length, 0),
    };
    final trainingSessions = <String, int>{
      for (final type in trainingTypes) type: 0
    };
    for (final session in data.sessions) {
      final index =
          window.buckets.indexWhere((bucket) => bucket.contains(session.date));
      if (index < 0 || !trainingMinutes.containsKey(session.type)) continue;
      trainingMinutes[session.type]![index] += session.duration;
      trainingSessions[session.type] = trainingSessions[session.type]! + 1;
    }
    final metrics = <String, TrendSeries>{
      'Sleep': _series(window, sleep),
      'HRV': _series(window, hrv),
      'Resting HR': _series(window, rhr),
      'Heart rate': _series(window, heartRate),
      'Watch workout': _series(window, workout),
      'Weight': _series(window, weight),
      'FightCamp punches': _series(window, punches),
    };
    return TrendsDashboard._(
      window,
      metrics,
      trainingMinutes,
      trainingSessions,
      {for (final key in domainKeys) key: _series(window, domainDaily[key]!)},
      limiters,
      data.actions
          .where((action) =>
              window.buckets.any((bucket) => bucket.contains(action.date)))
          .length,
    );
  }

  static TrendSeries _series(TrendWindow window, Map<String, double> daily) {
    return TrendSeries([
      for (final bucket in window.buckets)
        _mean([
          for (final entry in daily.entries)
            if (bucket.contains(entry.key)) entry.value,
        ]),
    ]);
  }

  static double? _mean(List<double> values) =>
      values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
}
