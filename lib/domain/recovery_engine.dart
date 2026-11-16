import 'dart:math' as math;

import 'athlete_data.dart';
import 'head_safety_tracker.dart';

const domainKeys = ['brain', 'fuel', 'sleep', 'power', 'body', 'mind'];
const domainLabels = {
  'brain': 'Brain',
  'fuel': 'Fuel & Weight',
  'sleep': 'Sleep & Heart',
  'power': 'Power & Speed',
  'body': 'Body',
  'mind': 'Mind',
};

class CampState {
  const CampState(this.daysOut, this.phase);
  final int? daysOut;
  final String phase;
}

class CampClock {
  static CampState fromProfile(AthleteProfile? profile, [DateTime? at]) {
    final fight = parsedDay(profile?.fightDate);
    if (fight == null) return const CampState(null, 'NO_CAMP');
    final now = at ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = fight.difference(today).inDays;
    return CampState(
        days,
        days < 0
            ? 'POST_FIGHT'
            : days <= 7
                ? 'FIGHT_WEEK'
                : days <= 14
                    ? 'TAPER'
                    : days <= 28
                        ? 'PEAK'
                        : days <= 56
                            ? 'BUILD'
                            : 'BASE');
  }

  static bool isFuture(String value, [DateTime? at]) {
    final selected = parsedDay(value);
    if (selected == null || localDay(selected) != value) return false;
    final now = at ?? DateTime.now();
    return selected.isAfter(DateTime(now.year, now.month, now.day));
  }

  static String formatted(String? value) {
    final date = parsedDay(value);
    if (date == null) return 'No fight date';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class Baseline {
  const Baseline(this.value, this.count, this.ready, {this.standardDeviation});
  final double? value;
  final int count;
  final bool ready;
  final double? standardDeviation;
}

class PersonalBaseline {
  PersonalBaseline(this.data);
  final AthleteData data;

  Baseline wearable(double? Function(WearableSample) read) {
    final source = data.activeHealthSource;
    if (source == null) return const Baseline(null, 0, false);
    final daily = <String, double>{};
    final cutoff =
        localDay(data.currentDate.subtract(const Duration(days: 30)));
    for (final sample in data.wearables) {
      if (sample.source != source) {
        continue;
      }
      if (sample.date.compareTo(cutoff) < 0 ||
          sample.date.compareTo(data.currentDay) >= 0) {
        continue;
      }
      final value = read(sample);
      if (value != null) {
        daily[sample.date] = value;
      }
    }
    final dates = daily.keys.toList()..sort();
    final values = dates.map((day) => daily[day]!).toList();
    final mean =
        values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
    final sd = mean == null || values.length < 2
        ? null
        : math.sqrt(values.fold<double>(
                0, (sum, value) => sum + math.pow(value - mean, 2).toDouble()) /
            values.length);
    return Baseline(mean, values.length, values.length >= 7,
        standardDeviation: sd);
  }

  Baseline punch() {
    if (data.connections['fightcamp'] != 'MOCK_CONNECTED' &&
        data.connections['fightcamp'] != 'CONNECTED') {
      return const Baseline(null, 0, false);
    }
    final source = data.latestFightCamp?.source;
    final daily = <String, double>{};
    for (final session in data.fightCampSessions) {
      if (source != null && source != session.source) continue;
      if (session.count != null) {
        daily[session.date] = session.count!.toDouble();
      }
    }
    final cutoff =
        localDay(data.currentDate.subtract(const Duration(days: 30)));
    final values = daily.entries
        .where((entry) =>
            entry.key.compareTo(cutoff) >= 0 &&
            entry.key.compareTo(data.currentDay) < 0)
        .map((entry) => entry.value)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final best = values.take(3).toList();
    return Baseline(
        best.isEmpty ? null : best.reduce((a, b) => a + b) / best.length,
        values.length,
        values.length >= 4);
  }
}

class SafetyFlag {
  const SafetyFlag(this.code, this.domain, this.message);
  final String code;
  final String domain;
  final String message;
}

class SafetyGate {
  List<SafetyFlag> evaluate(AthleteData data) {
    final check =
        data.latestCheckIn?.date == data.currentDay ? data.latestCheckIn : null;
    final head = HeadSafetyTracker(data);
    final recent = RecentTraining(data, 7);
    final flags = <SafetyFlag>[];
    if (head.needsProfessionalFollowUp) {
      if (head.newSymptomsToday) {
        flags.add(const SafetyFlag('HEAD_SYMPTOMS', 'brain',
            'New symptoms after head contact. Pause training, avoid further head impact, and seek qualified medical evaluation.'));
      } else if (head.headPainToday) {
        flags.add(const SafetyFlag('HEAD_PAIN', 'brain',
            'Head pain was reported after contact. Pause training and seek qualified medical evaluation.'));
      } else {
        flags.add(SafetyFlag('HEAD_FOLLOWUP', 'brain',
            'Head-impact concern reported on ${head.latestIncidentDate} still needs professional follow-up. A symptom-free check-in does not remove this restriction.'));
      }
    }
    if (recent.sessions
            .where((e) => e.type == 'Sparring' && e.contact == 'Heavy')
            .length >=
        2) {
      flags.add(const SafetyFlag('HEAD_LOAD', 'brain',
          'Repeated heavy head contact reported recently. Avoid further head-impact training and consider qualified evaluation.'));
    }
    if (check?.painSeverity == 'Severe' ||
        RecentTraining(data, 2)
            .sessions
            .any((e) => e.soreness.isNotEmpty && e.painSeverity == 'Severe')) {
      flags.add(const SafetyFlag('PHYSICAL', 'body',
          'Severe pain reported. Avoid loading the affected area and seek appropriate professional assessment.'));
    }
    if ((check?.urine ?? 0) >= 4) {
      flags.add(const SafetyFlag('HYDRATION', 'fuel',
          'A dark urine-colour report may signal a hydration concern. Prioritize hydration awareness and professional support if symptoms persist.'));
    }
    if (data.checkins.length >= 2) {
      final current = data.checkins[data.checkins.length - 1];
      final prior = data.checkins[data.checkins.length - 2];
      final currentDay = parsedDay(current.date);
      final priorDay = parsedDay(prior.date);
      if (currentDay != null &&
          priorDay != null &&
          currentDay.difference(priorDay).inDays == 1 &&
          current.weight != null &&
          prior.weight != null &&
          prior.weight! > 0 &&
          (current.weight! - prior.weight!).abs() / prior.weight! > .015) {
        flags.add(const SafetyFlag('WEIGHT_CHANGE', 'fuel',
            'A sudden weight change was recorded. Review hydration and seek qualified support if this is unexpected or accompanied by symptoms.'));
      }
    }
    return flags;
  }
}

/// Uses calendar days rather than the last N records, so old sessions expire.
class RecentTraining {
  RecentTraining(AthleteData data, int days)
      : sessions = data.sessions.where((session) {
          final day = parsedDay(session.date);
          if (day == null) return false;
          final age = DateTime(data.currentDate.year, data.currentDate.month,
                  data.currentDate.day)
              .difference(day)
              .inDays;
          return age >= 0 && age < days;
        }).toList();

  final List<TrainingSession> sessions;

  List<TrainingSession> ofType(String type) =>
      sessions.where((session) => session.type == type).toList();

  int minutes(String type) =>
      ofType(type).fold(0, (sum, session) => sum + session.duration);

  bool hasArea(String area) => sessions.any((e) => e.soreness.contains(area));
  bool get upperSoreness =>
      ['Shoulders', 'Arms', 'Hands', 'Wrists', 'Neck', 'Back'].any(hasArea);
  bool get lowerSoreness =>
      ['Legs', 'Calves', 'Hips', 'Back', 'Lower back'].any(hasArea);
  bool get painful => sessions.any((e) =>
      e.soreness.isNotEmpty &&
      (e.painSeverity == 'Painful' || e.painSeverity == 'Severe'));
}

class DomainResult {
  const DomainResult(this.status, this.reasons, {this.score});
  final String status;
  final List<String> reasons;
  final int? score;
}

/// Scores only observed inputs. A missing measurement remains null, never zero.
/// These are training-support indicators, not medical measurements or clearance.
class DomainScorer {
  const DomainScorer();

  int? score(String key, AthleteData data, Map<String, Baseline> baselines,
      List<SafetyFlag> safety) {
    final check =
        data.latestCheckIn?.date == data.currentDay ? data.latestCheckIn : null;
    final recent = RecentTraining(data, 7);
    int? value;
    switch (key) {
      case 'brain':
        if (check == null && recent.ofType('Sparring').isEmpty) {
          break;
        }
        var penalty = 0.0;
        for (final session in recent.ofType('Sparring')) {
          final age =
              data.currentDate.difference(parsedDay(session.date)!).inDays;
          final contact = switch (session.contact) {
            'Heavy' => 3.0,
            'Moderate' => 1.8,
            'Light' => 0.8,
            _ => 0.0,
          };
          penalty +=
              math.min(session.rounds, 12) * contact * math.exp(-age / 3.0);
        }
        value = (100 - penalty).round().clamp(0, 100);
      case 'fuel':
        final nutrition = data.latestNutrition?.date == data.currentDay
            ? data.latestNutrition
            : null;
        final parts = <(double, double)>[];
        if (check != null) {
          parts.add((
            switch (check.urine) {
              <= 2 => 100.0,
              3 => 85.0,
              4 => 55.0,
              _ => 20.0,
            },
            0.5
          ));
          final prior = data.checkins
              .where((e) =>
                  e.date.compareTo(data.currentDay) < 0 && e.weight != null)
              .toList();
          if (check.weight != null && prior.isNotEmpty) {
            final previous = prior.last;
            final days =
                data.currentDate.difference(parsedDay(previous.date)!).inDays;
            if (days == 1) {
              final change =
                  (check.weight! - previous.weight!).abs() / previous.weight!;
              parts.add((change > .015 ? 35.0 : 100.0, 0.15));
            }
          }
        }
        if (nutrition != null) {
          final routine = (nutrition.meal == 'Yes' ? 40 : 0) +
              (nutrition.protein == 'Yes' ? 35 : 0) +
              (nutrition.carbs == 'Low'
                  ? 5
                  : nutrition.carbs == 'Medium'
                      ? 20
                      : 25);
          parts.add((routine.toDouble(), 0.35));
        }
        value = _weighted(parts);
      case 'sleep':
        final parts = <(double, double)>[];
        final hrv = data.latestMetricSample((e) => e.hrv);
        final rhr = data.latestMetricSample((e) => e.restingHr);
        final sleep = data.latestSleepSample;
        final hrvBase = baselines['hrv']!;
        final rhrBase = baselines['restingHr']!;
        final sleepBase = baselines['sleep']!;
        if (hrv?.date == data.currentDay && hrv?.hrv != null && hrvBase.ready) {
          // HealthKit HRV is SDNN; do not apply an rMSSD-specific threshold.
          final sd =
              math.max(hrvBase.standardDeviation ?? 0, hrvBase.value! * .08);
          final z = (hrv!.hrv! - hrvBase.value!) / sd;
          parts.add(((80 + z * 20).round().clamp(0, 100).toDouble(), .40));
        }
        if (rhr?.date == data.currentDay &&
            rhr?.restingHr != null &&
            rhrBase.ready) {
          final delta = rhr!.restingHr! - rhrBase.value!;
          parts.add(((90 - delta * 8).round().clamp(0, 100).toDouble(), .30));
        }
        if (sleep?.date == data.currentDay &&
            sleep?.sleepMinutes != null &&
            sleepBase.ready) {
          final ratio = sleep!.sleepMinutes! / sleepBase.value!;
          parts.add(((ratio * 90).round().clamp(0, 100).toDouble(), .30));
        }
        value = _weighted(parts);
      case 'power':
        final punch = data.connections['fightcamp'] == 'MOCK_CONNECTED' ||
                data.connections['fightcamp'] == 'CONNECTED'
            ? data.latestFightCamp
            : null;
        final base = baselines['punch']!;
        if (punch?.date != data.currentDay ||
            punch?.count == null ||
            !base.ready) {
          break;
        }
        final ratio = punch!.count! / base.value!;
        value = ratio >= .96
            ? (90 + (ratio - .96) * 100).round().clamp(90, 100)
            : ratio >= .90
                ? (65 + (ratio - .90) / .06 * 15).round().clamp(65, 80)
                : (ratio / .90 * 50).round().clamp(0, 50);
      case 'body':
        final sessions = RecentTraining(data, 2).sessions;
        if (check == null && sessions.isEmpty) {
          break;
        }
        var penalty = 0.0;
        final areas = <String>{
          if (check != null) ...check.soreness,
          for (final session in sessions) ...session.soreness,
        };
        final severity = check?.painSeverity == 'Severe' ||
                sessions.any((e) => e.painSeverity == 'Severe')
            ? 60.0
            : check?.painSeverity == 'Painful' ||
                    sessions.any((e) => e.painSeverity == 'Painful')
                ? 40.0
                : 25.0;
        for (final area in areas) {
          penalty += severity *
              (['Head', 'Neck', 'Hands', 'Wrists'].contains(area) ? 1.5 : 1);
        }
        if (sessions.any((e) => e.duration >= 60 && e.intensity == 'Hard')) {
          penalty += 25;
        }
        if (sessions.any((e) =>
            e.type == 'Strength' && e.duration >= 60 && areas.isNotEmpty)) {
          penalty += 30;
        }
        value = (100 - penalty).round().clamp(0, 100);
      case 'mind':
        if (check == null) {
          break;
        }
        value = switch (check.mood) {
          'Good' => 100,
          'OK' => 75,
          'Flat' => 45,
          'Low' => 25,
          _ => null,
        };
        final recentMoods = data.checkins.where((e) {
          final day = parsedDay(e.date);
          return day != null &&
              data.currentDate.difference(day).inDays < 3 &&
              data.currentDate.difference(day).inDays >= 0;
        }).toList();
        if (value != null &&
            recentMoods.length >= 3 &&
            recentMoods.every((e) => e.mood == 'Flat' || e.mood == 'Low')) {
          value = math.max(0, value - 15);
        }
    }
    for (final flag in safety.where((e) => e.domain == key)) {
      final cap = flag.code == 'HEAD_SYMPTOMS' ||
              flag.code == 'HEAD_PAIN' ||
              flag.code == 'HEAD_FOLLOWUP'
          ? 0
          : 39;
      value = math.min(value ?? cap, cap);
    }
    if (key == 'brain' && HeadSafetyTracker(data).hasExternalPlan) {
      // A self-reported external plan does not make this app a clearance tool.
      value = math.min(value ?? 79, 79);
    }
    return value;
  }

  int? _weighted(List<(double, double)> parts) {
    if (parts.isEmpty) return null;
    final weight = parts.fold<double>(0, (sum, part) => sum + part.$2);
    return (parts.fold<double>(0, (sum, part) => sum + part.$1 * part.$2) /
            weight)
        .round()
        .clamp(0, 100);
  }
}

class RecoveryAction {
  const RecoveryAction(this.id, this.title, this.reason, this.seconds);
  final String id;
  final String title;
  final String reason;
  final int seconds;
}

class TrainingAdvice {
  const TrainingAdvice(this.status, this.title, this.reason,
      {this.allowedLabel, this.avoidLabel});
  final String status; // AVAILABLE, MODIFIED, AVOID, or INSUFFICIENT_DATA.
  final String title;
  final String reason;
  final String? allowedLabel;
  final String? avoidLabel;
}

/// Converts independent domains and recent, type-specific loads into guidance.
/// These are conservative prototype rules, not medical clearance.
class TrainingAdvisor {
  Map<String, TrainingAdvice> evaluate(
      AthleteData data,
      Map<String, DomainResult> domains,
      List<SafetyFlag> safety,
      CampState camp) {
    final recent = RecentTraining(data, 2);
    final strength = recent.ofType('Strength');
    final technical = recent.ofType('Boxing / Technical');
    final conditioning = recent.ofType('Conditioning');
    final upperPain = recent.upperSoreness ||
        (data.latestCheckIn?.date == data.currentDay &&
            data.latestCheckIn!.soreness.any((area) => [
                  'Shoulders',
                  'Arms',
                  'Hands',
                  'Wrists',
                  'Neck',
                  'Back'
                ].contains(area)));
    final lowerPain = recent.lowerSoreness ||
        (data.latestCheckIn?.date == data.currentDay &&
            data.latestCheckIn!.soreness.any((area) => [
                  'Legs',
                  'Calves',
                  'Hips',
                  'Back',
                  'Lower back'
                ].contains(area)));
    final seriousPain = recent.painful ||
        (data.latestCheckIn?.date == data.currentDay &&
            ['Moderate', 'Severe'].contains(data.latestCheckIn!.painSeverity));
    final longStrength = strength.any((e) => e.duration >= 60) ||
        recent.minutes('Strength') >= 75;
    final hardStrength = strength.any((e) => e.intensity == 'Hard');
    final longTechnical = technical.any((e) => e.duration >= 60) ||
        recent.minutes('Boxing / Technical') >= 75;
    final hardTechnical = technical.any((e) => e.intensity == 'Hard');
    final longConditioning = conditioning.any((e) => e.duration >= 60) ||
        recent.minutes('Conditioning') >= 75;
    final hardConditioning = conditioning.any((e) => e.intensity == 'Hard');
    final enoughData = domains.values
            .where((domain) => domain.status != 'INSUFFICIENT_DATA')
            .length >=
        4;
    final headConcern = safety.any((flag) =>
        flag.code == 'HEAD_SYMPTOMS' ||
        flag.code == 'HEAD_PAIN' ||
        flag.code == 'HEAD_FOLLOWUP');
    final headPlan = HeadSafetyTracker(data).hasExternalPlan;
    final headLoad = safety.any((flag) => flag.code == 'HEAD_LOAD');
    final hydrationConcern = safety.any(
        (flag) => flag.code == 'HYDRATION' || flag.code == 'WEIGHT_CHANGE');
    final fuelRestricted = domains['fuel']?.status == 'RESTRICTED';
    final powerRestricted = domains['power']?.status == 'RESTRICTED';
    final severePhysical = safety.any((flag) => flag.code == 'PHYSICAL');
    const unknown = TrainingAdvice('INSUFFICIENT_DATA', 'More data needed',
        'Complete the check-in and build a personal baseline before a positive training suggestion.');
    if (headConcern) {
      return {
        for (final type in [
          'Sparring',
          'Boxing / Technical',
          'Conditioning',
          'Strength'
        ])
          type: TrainingAdvice('AVOID', 'Pause training and get assessed',
              'Head pain or symptoms after contact need qualified evaluation before further training.',
              avoidLabel: type)
      };
    }
    if (severePhysical) {
      return {
        for (final type in [
          'Sparring',
          'Boxing / Technical',
          'Conditioning',
          'Strength'
        ])
          type: TrainingAdvice('AVOID', 'Pause loading and get assessed',
              'Severe pain was reported. Avoid training until the affected area is assessed.',
              avoidLabel: type)
      };
    }

    final advice = <String, TrainingAdvice>{};
    if (headLoad ||
        domains['brain']!.status == 'RESTRICTED' ||
        camp.phase == 'FIGHT_WEEK' ||
        powerRestricted ||
        fuelRestricted) {
      advice['Sparring'] = TrainingAdvice(
          'AVOID',
          'Avoid sparring today',
          headLoad
              ? 'Repeated heavy head contact was logged in the last 7 days.'
              : camp.phase == 'FIGHT_WEEK'
                  ? 'Fight-week plan favours avoiding sparring.'
                  : powerRestricted
                      ? 'Punch output is below your personal FightCamp baseline.'
                      : fuelRestricted
                          ? 'Fuel signals need attention before high-intensity contact.'
                          : domains['brain']!.reasons.join(' · '),
          avoidLabel: 'Sparring');
    } else if (headPlan) {
      advice['Sparring'] = const TrainingAdvice(
          'MODIFIED',
          'Follow your clinician\'s return-to-contact plan',
          'An external plan was self-reported. This app cannot verify it or decide when sparring is safe.',
          avoidLabel: 'Unsupervised sparring');
    } else if (upperPain && (seriousPain || longStrength)) {
      advice['Sparring'] = const TrainingAdvice('AVOID', 'Skip sparring today',
          'Shoulder, arm, neck or back pain after training can limit safe defence and punching.',
          avoidLabel: 'Sparring with upper-body pain');
    } else if (domains['brain']!.status == 'CAUTION' ||
        domains['sleep']!.status == 'RESTRICTED' ||
        hydrationConcern) {
      advice['Sparring'] = TrainingAdvice(
          'MODIFIED',
          'Avoid hard contact',
          domains['brain']!.status == 'CAUTION'
              ? domains['brain']!.reasons.join(' · ')
              : hydrationConcern
                  ? 'Hydration or weight trend needs attention before intense work.'
                  : 'Sleep and heart signals need recovery before intense work.',
          avoidLabel: 'Hard sparring');
    } else {
      advice['Sparring'] = enoughData && domains['brain']!.status == 'READY'
          ? const TrainingAdvice('AVAILABLE', 'Sparring can be considered',
              'No head-impact warning is reported in the available data. Follow your coach and safety checks.',
              allowedLabel: 'Sparring')
          : unknown;
    }

    if (upperPain && (seriousPain || longStrength)) {
      advice['Boxing / Technical'] = const TrainingAdvice(
          'MODIFIED',
          'Footwork only; rest the shoulder',
          'Upper-body pain after training makes further punching load a poor choice today.',
          allowedLabel: 'No-contact footwork',
          avoidLabel: 'Pads and bag work with upper-body pain');
    } else if (headPlan && !headLoad) {
      advice['Boxing / Technical'] = const TrainingAdvice(
          'MODIFIED',
          'Follow the clinician\'s activity plan',
          'Use only activity allowed by your external return-to-training plan. The app does not provide clearance.',
          avoidLabel: 'Unplanned head-contact drills');
    } else if (headLoad ||
        hydrationConcern ||
        fuelRestricted ||
        powerRestricted ||
        (hardTechnical && longTechnical) ||
        domains['body']!.status == 'CAUTION') {
      advice['Boxing / Technical'] = TrainingAdvice(
          'MODIFIED',
          'Keep technical work light',
          headLoad
              ? 'Keep drills strictly no-contact after repeated head contact.'
              : powerRestricted
                  ? 'Punch output is below your personal baseline; keep technique slow and no-contact.'
                  : hydrationConcern || fuelRestricted
                      ? 'Hydration or weight trend needs attention before hard technical work.'
                      : hardTechnical && longTechnical
                          ? 'A long hard technical session was logged recently.'
                          : domains['body']!.reasons.join(' · '),
          allowedLabel: 'Light no-contact technique',
          avoidLabel: 'Hard pads or bag work');
    } else {
      advice['Boxing / Technical'] = enoughData
          ? const TrainingAdvice('AVAILABLE', 'Technical boxing is an option',
              'No specific technical-load restriction appears in the available data.',
              allowedLabel: 'Boxing / Technical')
          : unknown;
    }

    if (lowerPain && seriousPain) {
      advice['Conditioning'] = const TrainingAdvice(
          'MODIFIED',
          'Avoid leg-loading conditioning',
          'Pain in the legs or back was reported; avoid running and intervals that aggravate it.',
          avoidLabel: 'Leg-loading conditioning');
    } else if ((hardConditioning && longConditioning) ||
        domains['sleep']!.status == 'RESTRICTED' ||
        hydrationConcern ||
        fuelRestricted ||
        (lowerPain && longConditioning)) {
      advice['Conditioning'] = TrainingAdvice(
          'MODIFIED',
          'Easy aerobic work only',
          hardConditioning && longConditioning
              ? 'A long hard conditioning session was logged recently; skip another interval session.'
              : hydrationConcern || fuelRestricted
                  ? 'Hydration or weight trend needs attention before hard conditioning.'
                  : lowerPain
                      ? 'Leg or back soreness was reported after a long session.'
                      : 'Sleep and heart signals call for reduced intensity.',
          allowedLabel: 'Easy conditioning',
          avoidLabel: 'Hard conditioning');
    } else {
      advice['Conditioning'] = enoughData
          ? const TrainingAdvice('AVAILABLE', 'Conditioning is an option',
              'No specific conditioning restriction appears in the available data.',
              allowedLabel: 'Conditioning')
          : unknown;
    }

    if ((upperPain || lowerPain) && (seriousPain || longStrength)) {
      advice['Strength'] = TrainingAdvice(
          'AVOID',
          'Rest the ${upperPain ? 'upper body' : 'affected area'} today',
          'A ${longStrength ? 'long ' : ''}strength session and ${seriousPain ? 'pain' : 'soreness'} were reported. Skip another strength session that loads this area.',
          avoidLabel: 'Strength for affected area');
    } else if (hardStrength ||
        longStrength ||
        upperPain ||
        lowerPain ||
        hydrationConcern ||
        fuelRestricted ||
        domains['sleep']!.status == 'RESTRICTED') {
      advice['Strength'] = TrainingAdvice(
          'MODIFIED',
          'Skip heavy lifting today',
          upperPain || lowerPain
              ? 'Soreness was reported; avoid loading the sore area.'
              : hydrationConcern || fuelRestricted
                  ? 'Hydration or weight trend needs attention before heavy lifting.'
                  : longStrength || hardStrength
                      ? 'A long or hard strength session was logged recently.'
                      : 'Sleep and heart signals call for a lighter session.',
          allowedLabel: 'Light strength away from sore areas',
          avoidLabel: 'Heavy strength');
    } else {
      advice['Strength'] = enoughData
          ? const TrainingAdvice('AVAILABLE', 'Strength is an option',
              'No specific strength-load restriction appears in the available data.',
              allowedLabel: 'Strength')
          : unknown;
    }
    if (headPlan) {
      for (final type in ['Boxing / Technical', 'Conditioning', 'Strength']) {
        final current = advice[type]!;
        if (current.status == 'AVOID') continue;
        advice[type] = TrainingAdvice(
            'MODIFIED',
            'Follow your clinician\'s activity plan',
            '${current.reason} An external plan was self-reported; the app cannot verify it or clear this activity.',
            avoidLabel:
                current.avoidLabel ?? 'Training outside the clinician plan');
      }
    }
    return advice;
  }
}

class Assessment {
  Assessment(
      {required this.camp,
      required this.domains,
      required this.safety,
      required this.limiter,
      required this.reason,
      required this.allowed,
      required this.avoid,
      required this.trainingGuidance,
      required this.action,
      required this.baselines,
      required this.hasCurrentWearable});
  final CampState camp;
  final Map<String, DomainResult> domains;
  final List<SafetyFlag> safety;
  final String? limiter;
  final String reason;
  final List<String> allowed;
  final List<String> avoid;
  final Map<String, TrainingAdvice> trainingGuidance;
  final RecoveryAction action;
  final Map<String, Baseline> baselines;
  final bool hasCurrentWearable;

  int get assessedCount =>
      domains.values.where((e) => e.status != 'INSUFFICIENT_DATA').length;
  // A raw wearable reading counts as present on the dashboard, even while
  // Sleep & Heart still needs a personal baseline for training guidance.
  int get observedCount =>
      assessedCount +
      (domains['sleep']?.status == 'INSUFFICIENT_DATA' && hasCurrentWearable
          ? 1
          : 0);
  Map<String, dynamic> snapshot(String day) => {
        'date': day,
        'limiter': limiter,
        'domains': domains.map((key, value) => MapEntry(key, value.status)),
        'domainScores': domains.map((key, value) => MapEntry(key, value.score)),
        'safety': safety.map((e) => e.code).toList(),
      };
}

class RecoveryEngine {
  final SafetyGate safetyGate = SafetyGate();

  Assessment assess(AthleteData data) {
    final safety = safetyGate.evaluate(data);
    final baseline = PersonalBaseline(data);
    final hrv = baseline.wearable((e) => e.hrv);
    final rhr = baseline.wearable((e) => e.restingHr);
    final sleep = baseline.wearable((e) => e.sleepMinutes?.toDouble());
    final punchBaseline = baseline.punch();
    final sleepWear = data.latestSleepSample;
    final hrvWear = data.latestMetricSample((sample) => sample.hrv);
    final rhrWear = data.latestMetricSample((sample) => sample.restingHr);
    final check =
        data.latestCheckIn?.date == data.currentDay ? data.latestCheckIn : null;
    final nutrition = data.latestNutrition?.date == data.currentDay
        ? data.latestNutrition
        : null;
    final recent = RecentTraining(data, 2);
    final punch = data.connections['fightcamp'] == 'MOCK_CONNECTED' ||
            data.connections['fightcamp'] == 'CONNECTED'
        ? data.latestFightCamp
        : null;
    final camp = CampClock.fromProfile(data.profile, data.currentDate);
    final domains = {
      for (final key in domainKeys)
        key: const DomainResult('INSUFFICIENT_DATA', <String>[])
    };

    if (sleepWear != null || hrvWear != null || rhrWear != null) {
      final reasons = <String>[];
      if (sleep.ready &&
          sleepWear?.sleepMinutes != null &&
          sleepWear!.sleepMinutes! < sleep.value! * 0.85) {
        reasons.add('Sleep below your baseline');
      }
      if (hrv.ready &&
          hrvWear?.hrv != null &&
          hrvWear!.hrv! < hrv.value! * 0.85) {
        reasons.add('HRV below your baseline');
      }
      if (rhr.ready &&
          rhrWear?.restingHr != null &&
          rhrWear!.restingHr! > rhr.value! * 1.1) {
        reasons.add('Resting HR above your baseline');
      }
      if (recent
          .ofType('Conditioning')
          .any((e) => e.intensity == 'Hard' && e.duration >= 60)) {
        reasons.add('Long hard conditioning session reported recently');
      }
      final status = reasons.length >= 2
          ? 'RESTRICTED'
          : reasons.isNotEmpty
              ? 'CAUTION'
              : hrv.ready || sleep.ready
                  ? 'READY'
                  : 'INSUFFICIENT_DATA';
      domains['sleep'] = DomainResult(
          status,
          reasons.isNotEmpty
              ? reasons
              : hrv.ready || sleep.ready
                  ? ['Within your personal baseline']
                  : ['Learning your baseline']);
    }

    if (check != null || nutrition != null) {
      final reasons = <String>[];
      if ((check?.urine ?? 0) >= 3) {
        reasons.add('Urine colour suggests hydration attention');
      }
      if (nutrition?.meal == 'No') reasons.add('Post-training meal missed');
      if (nutrition?.protein == 'No') reasons.add('Protein plan incomplete');
      if (recent
          .ofType('Conditioning')
          .any((e) => e.intensity == 'Hard' && e.duration >= 60)) {
        reasons.add('Long hard conditioning increases refuelling attention');
      }
      domains['fuel'] =
          DomainResult(reasons.isEmpty ? 'READY' : 'CAUTION', reasons);
    }
    if (recent.ofType('Sparring').isNotEmpty || check?.headSymptoms == true) {
      final reasons = <String>[];
      for (final session in recent.ofType('Sparring')) {
        if (session.contact != 'None' || session.rounds >= 6) {
          reasons.add(
              '${session.rounds} sparring rounds · ${session.contact.toLowerCase()} contact');
        }
      }
      domains['brain'] =
          DomainResult(reasons.isEmpty ? 'READY' : 'CAUTION', reasons);
    }
    if (punch?.count != null) {
      domains['power'] = DomainResult(
        punchBaseline.ready && punch!.count! < punchBaseline.value! * 0.85
            ? 'CAUTION'
            : punchBaseline.ready
                ? 'READY'
                : 'INSUFFICIENT_DATA',
        punchBaseline.ready
            ? [
                'FightCamp punch count compared with your baseline (${punchBaseline.value!.round()})'
              ]
            : ['Learning your FightCamp punch baseline'],
      );
    }
    final hardPowerLoad = recent.sessions.any((e) =>
        (e.type == 'Strength' || e.type == 'Boxing / Technical') &&
        e.intensity == 'Hard' &&
        e.duration >= 60);
    if (hardPowerLoad && domains['power']!.status != 'RESTRICTED') {
      final current = domains['power']!;
      domains['power'] = DomainResult('CAUTION', [
        ...current.reasons,
        'Long hard strength or technical load reported; a power change has not been measured'
      ]);
    }
    final soreAreas = <String>{
      if (check?.date == data.currentDay) ...check!.soreness,
      for (final session in recent.sessions) ...session.soreness
    };
    final longStrength = recent.ofType('Strength').any((e) => e.duration >= 60);
    final longTechnical = recent
        .ofType('Boxing / Technical')
        .any((e) => e.duration >= 60 && e.intensity == 'Hard');
    final soreAfterLongStrength = longStrength &&
        soreAreas.any((area) => [
              'Shoulders',
              'Arms',
              'Hands',
              'Wrists',
              'Neck',
              'Back',
              'Lower back',
              'Hips',
              'Legs',
              'Calves'
            ].contains(area));
    final painful = recent.painful || check?.painSeverity == 'Severe';
    if (soreAreas.isNotEmpty || longStrength || longTechnical) {
      final reasons = <String>[
        if (soreAreas.isNotEmpty)
          'Reported soreness/pain: ${soreAreas.join(', ')}',
        if (longStrength) 'Strength load of 60 min or more reported',
        if (longTechnical) 'Long hard technical boxing reported'
      ];
      domains['body'] = DomainResult(
          painful || soreAfterLongStrength ? 'RESTRICTED' : 'CAUTION', reasons);
    }
    if (check?.mood.isNotEmpty == true) {
      domains['mind'] = DomainResult(
          ['Flat', 'Low'].contains(check!.mood) ? 'CAUTION' : 'READY',
          ['Mood: ${check.mood}']);
    }
    for (final flag in safety) {
      domains[flag.domain] = DomainResult('RESTRICTED', [flag.message]);
    }
    if (HeadSafetyTracker(data).hasExternalPlan &&
        !safety.any((flag) => flag.domain == 'brain')) {
      domains['brain'] = const DomainResult('CAUTION', [
        'External professional plan self-reported. The app cannot verify it or clear contact training.'
      ]);
    }

    final baselines = {
      'hrv': hrv,
      'restingHr': rhr,
      'sleep': sleep,
      'punch': punchBaseline,
    };
    const scorer = DomainScorer();
    for (final key in domainKeys) {
      final previous = domains[key]!;
      var score = scorer.score(key, data, baselines, safety);
      if (key == 'power' && score != null && hardPowerLoad) {
        score = math.min(score, 75);
      }
      final hasSafety = safety.any((flag) => flag.domain == key);
      final status = hasSafety
          ? 'RESTRICTED'
          : score == null
              ? 'INSUFFICIENT_DATA'
              : score < 50
                  ? 'RESTRICTED'
                  : score < 80
                      ? 'CAUTION'
                      : 'READY';
      domains[key] = DomainResult(status, previous.reasons, score: score);
    }

    const tiePriority = {
      'brain': 6,
      'body': 5,
      'sleep': 4,
      'fuel': 3,
      'power': 2,
      'mind': 1
    };
    String? limiter = safety.any((flag) => flag.domain == 'brain')
        ? 'brain'
        : safety.isNotEmpty
            ? safety.first.domain
            : null;
    if (limiter == null) {
      for (final key in domainKeys) {
        final score = domains[key]!.score;
        if (score != null &&
            score < 80 &&
            (limiter == null ||
                score < domains[limiter]!.score! ||
                (score == domains[limiter]!.score &&
                    tiePriority[key]! > tiePriority[limiter]!))) {
          limiter = key;
        }
      }
    }
    final guidance = TrainingAdvisor().evaluate(data, domains, safety, camp);
    final allowed = <String>{
      for (final advice in guidance.values)
        if (advice.allowedLabel != null) advice.allowedLabel!
    };
    final avoid = <String>{
      for (final advice in guidance.values)
        if (advice.avoidLabel != null) advice.avoidLabel!
    };
    final action = switch (limiter) {
      'brain' => const RecoveryAction(
          'early-bed',
          'Prepare for a quiet evening',
          'Head-impact concern is the priority. Follow the safety guidance and avoid further contact.',
          600),
      'sleep' || 'mind' => RecoveryAction(
          'breathing',
          '10 min breathing down-regulation',
          '${domainLabels[limiter]} needs attention today.',
          600),
      'body' when domains['body']!.status == 'CAUTION' => const RecoveryAction(
          'mobility',
          '10 min gentle mobility',
          'Body soreness is present today. Avoid painful movement.',
          600),
      'fuel' => const RecoveryAction(
          'early-bed',
          'Plan a regular recovery meal',
          'Fuel or hydration signals need attention. Follow your usual safe nutrition plan.',
          600),
      _ => const RecoveryAction('early-bed', 'Prepare for an earlier bedtime',
          'Protect recovery before tomorrow.', 600),
    };
    final assessed =
        domains.values.where((e) => e.status != 'INSUFFICIENT_DATA').length;
    return Assessment(
      camp: camp,
      domains: domains,
      safety: safety,
      limiter: limiter,
      reason: limiter != null
          ? domains[limiter]!.reasons.join(' · ')
          : assessed < 4
              ? 'Learning your baseline'
              : 'No primary limiter from the available data',
      allowed: allowed.toList(),
      avoid: avoid.toList(),
      trainingGuidance: guidance,
      action: action,
      baselines: baselines,
      hasCurrentWearable: [sleepWear, hrvWear, rhrWear]
          .any((sample) => sample?.date == data.currentDay),
    );
  }
}

class FeedbackInsight {
  const FeedbackInsight(this.label, this.detail);
  final String label;
  final String detail;
}

class FeedbackService {
  FeedbackInsight insight(AthleteData data, String actionId) {
    final records = data.actions
        .where((e) => e.id == actionId && e.nextDay != null)
        .toList();
    if (records.length < 3) {
      if (records.isEmpty) {
        return const FeedbackInsight('Not Enough Data',
            'Complete this action and check in on another morning to see an observation.');
      }
      final next = records.last.nextDay!;
      final details = <String>[];
      final hrv = numberOrNull(next['hrvDelta']);
      final sleep = numberOrNull(next['sleepDelta']);
      final rhr = numberOrNull(next['restingHrDelta']);
      if (hrv != null) {
        details.add('HRV ${hrv >= 0 ? '+' : ''}${hrv.toStringAsFixed(0)} ms');
      }
      if (sleep != null) {
        details.add(
            'sleep ${sleep >= 0 ? '+' : ''}${sleep.toStringAsFixed(0)} min');
      }
      if (rhr != null) {
        details.add(
            'resting HR ${rhr >= 0 ? '+' : ''}${rhr.toStringAsFixed(0)} bpm');
      }
      if (next['mood'] is String) details.add('mood ${next['mood']}');
      final targetDelta = numberOrNull(next['targetScoreDelta']);
      if (targetDelta != null && records.last.targetDomain != null) {
        details.add(
            '${domainLabels[records.last.targetDomain]} ${targetDelta >= 0 ? '+' : ''}${targetDelta.toStringAsFixed(0)} points');
      }
      final targetDomain = records.last.targetDomain ?? 'sleep';
      final domain = next['domains'] is Map
          ? (next['domains'] as Map)[targetDomain]
          : null;
      if (domain is String) {
        details.add(
            '${domainLabels[targetDomain]} ${domain.toLowerCase().replaceAll('_', ' ')}');
      }
      return FeedbackInsight('Not Enough Data',
          'Next morning: ${details.isEmpty ? 'wearable data unavailable' : details.join(' · ')}. More observations are needed; this does not show cause.');
    }
    final target = records.last.targetDomain;
    final values = records
        .where((e) => e.targetDomain == target)
        .map((e) => numberOrNull(e.nextDay?['targetScoreDelta']))
        .whereType<double>()
        .toList();
    if (values.length < 3) {
      return const FeedbackInsight('Not Enough Data',
          'At least three comparable next-day domain scores are needed.');
    }
    final average = values.reduce((a, b) => a + b) / values.length;
    return FeedbackInsight(
        average > 5 ? 'Possible Benefit' : 'No Clear Pattern',
        'Across ${values.length} observations, the targeted domain changed by ${average >= 0 ? '+' : ''}${average.toStringAsFixed(1)} points the next morning on average. This is an association, not proof of cause.');
  }
}
