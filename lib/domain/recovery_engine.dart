import 'dart:math' as math;

import 'athlete_data.dart';

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
  const Baseline(this.value, this.count, this.ready);
  final double? value;
  final int count;
  final bool ready;
}

class PersonalBaseline {
  PersonalBaseline(this.data);
  final AthleteData data;

  Baseline wearable(double? Function(WearableSample) read) {
    final source = data.latestMetricSample(read)?.source;
    final daily = <String, double>{};
    for (final sample in data.wearables) {
      if (source != null && sample.source != source) continue;
      final value = read(sample);
      if (value != null) daily[sample.date] = value;
    }
    final values = daily.values.toList().reversed.take(10).toList();
    return Baseline(
        values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length,
        values.length,
        values.length >= 7);
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
    final values = daily.values.toList().reversed.take(10).toList();
    return Baseline(
        values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length,
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
    final recent = RecentTraining(data, 7);
    final flags = <SafetyFlag>[];
    if (check?.headSymptoms == true) {
      flags.add(const SafetyFlag('HEAD_SYMPTOMS', 'brain',
          'New symptoms after head contact. Avoid sparring and other head-impact training. Seek qualified medical evaluation.'));
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
    if (RecentTraining(data, 2).sessions.any((e) =>
        e.type == 'Sparring' &&
        e.contact != 'None' &&
        e.soreness.contains('Head') &&
        e.painSeverity != 'Sore')) {
      flags.add(const SafetyFlag('HEAD_PAIN', 'brain',
          'Head pain was reported after contact. Avoid sparring and head-impact activity, and seek qualified medical evaluation.'));
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
          currentDay.difference(priorDay).inDays <= 2 &&
          current.weight != null &&
          prior.weight != null &&
          (current.weight! - prior.weight!).abs() >= 1.5) {
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
  bool get upperSoreness => ['Shoulders', 'Arms', 'Neck', 'Back'].any(hasArea);
  bool get lowerSoreness => ['Legs', 'Back'].any(hasArea);
  bool get painful => sessions.any((e) =>
      e.soreness.isNotEmpty &&
      (e.painSeverity == 'Painful' || e.painSeverity == 'Severe'));
}

class DomainResult {
  const DomainResult(this.status, this.reasons);
  final String status;
  final List<String> reasons;
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
            data.latestCheckIn!.soreness.any((area) =>
                ['Shoulders', 'Arms', 'Neck', 'Back'].contains(area)));
    final lowerPain = recent.lowerSoreness ||
        (data.latestCheckIn?.date == data.currentDay &&
            data.latestCheckIn!.soreness
                .any((area) => ['Legs', 'Back'].contains(area)));
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
    final headConcern = safety.any(
        (flag) => flag.code == 'HEAD_SYMPTOMS' || flag.code == 'HEAD_PAIN');
    final headLoad = safety.any((flag) => flag.code == 'HEAD_LOAD');
    final hydrationConcern = safety.any(
        (flag) => flag.code == 'HYDRATION' || flag.code == 'WEIGHT_CHANGE');
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
        camp.phase == 'FIGHT_WEEK') {
      advice['Sparring'] = TrainingAdvice(
          'AVOID',
          'Avoid sparring today',
          headLoad
              ? 'Repeated heavy head contact was logged in the last 7 days.'
              : camp.phase == 'FIGHT_WEEK'
                  ? 'Fight-week plan favours avoiding sparring.'
                  : domains['brain']!.reasons.join(' · '),
          avoidLabel: 'Sparring');
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
    } else if (headLoad ||
        hydrationConcern ||
        (hardTechnical && longTechnical) ||
        domains['body']!.status == 'CAUTION') {
      advice['Boxing / Technical'] = TrainingAdvice(
          'MODIFIED',
          'Keep technical work light',
          headLoad
              ? 'Keep drills strictly no-contact after repeated head contact.'
              : hydrationConcern
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
        (lowerPain && longConditioning)) {
      advice['Conditioning'] = TrainingAdvice(
          'MODIFIED',
          'Easy aerobic work only',
          hardConditioning && longConditioning
              ? 'A long hard conditioning session was logged recently; skip another interval session.'
              : hydrationConcern
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
        domains['sleep']!.status == 'RESTRICTED') {
      advice['Strength'] = TrainingAdvice(
          'MODIFIED',
          'Skip heavy lifting today',
          upperPain || lowerPain
              ? 'Soreness was reported; avoid loading the sore area.'
              : hydrationConcern
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
      required this.baselines});
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

  int get assessedCount =>
      domains.values.where((e) => e.status != 'INSUFFICIENT_DATA').length;
  // A raw wearable reading counts as present on the dashboard, even while
  // Sleep & Heart still needs a personal baseline for training guidance.
  int get observedCount =>
      assessedCount +
      (domains['sleep']?.status == 'INSUFFICIENT_DATA' &&
              ((baselines['sleep']?.count ?? 0) > 0 ||
                  (baselines['hrv']?.count ?? 0) > 0 ||
                  (baselines['restingHr']?.count ?? 0) > 0)
          ? 1
          : 0);
  Map<String, dynamic> snapshot(String day) => {
        'date': day,
        'limiter': limiter,
        'domains': domains.map((key, value) => MapEntry(key, value.status)),
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
        soreAreas.any((area) =>
            ['Shoulders', 'Arms', 'Neck', 'Back', 'Legs'].contains(area));
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

    const rank = {
      'INSUFFICIENT_DATA': 0,
      'READY': 1,
      'CAUTION': 2,
      'RESTRICTED': 3
    };
    const tiePriority = {
      'brain': 6,
      'body': 5,
      'sleep': 4,
      'fuel': 3,
      'power': 2,
      'mind': 1
    };
    String? limiter = safety.isNotEmpty ? safety.first.domain : null;
    if (limiter == null) {
      for (final key in domainKeys) {
        final status = domains[key]!.status;
        if ((rank[status] ?? 0) >= 2 &&
            (limiter == null ||
                rank[status]! > rank[domains[limiter]!.status]! ||
                (rank[status] == rank[domains[limiter]!.status] &&
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
    final sleepStatus = domains['sleep']!.status;
    final action = ['CAUTION', 'RESTRICTED'].contains(sleepStatus)
        ? const RecoveryAction('breathing', '10 min breathing down-regulation',
            'Sleep & Heart needs attention today.', 600)
        : domains['body']!.status == 'RESTRICTED'
            ? const RecoveryAction(
                'early-bed',
                'Prepare for an earlier bedtime',
                'Body pain or heavy load was reported; avoid adding more load tonight.',
                600)
            : domains['body']!.status == 'CAUTION'
                ? const RecoveryAction('mobility', '10 min gentle mobility',
                    'Body soreness is present today.', 600)
                : const RecoveryAction(
                    'early-bed',
                    'Prepare for an earlier bedtime',
                    'Protect recovery before tomorrow.',
                    600);
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
      baselines: {
        'hrv': hrv,
        'restingHr': rhr,
        'sleep': sleep,
        'punch': punchBaseline
      },
    );
  }
}

class RecoveryOverview {
  const RecoveryOverview(this.score, this.label, this.tone, this.explanation);
  final int? score;
  final String label;
  final String tone;
  final String explanation;

  factory RecoveryOverview.fromAssessment(Assessment assessment) {
    final assessed = assessment.assessedCount;
    final baselineReady = assessment.baselines['hrv']!.ready ||
        assessment.baselines['sleep']!.ready;
    final hasSafety = assessment.safety.isNotEmpty;
    if (assessed < 4 || !baselineReady) {
      return RecoveryOverview(
          null,
          hasSafety ? 'SAFETY' : 'LEARNING',
          hasSafety ? 'safety' : 'learning',
          hasSafety
              ? 'Safety concern reported. Review restrictions below.'
              : '$assessed of 6 domains assessed · Learning your baseline');
    }
    const points = {'READY': 90, 'CAUTION': 55, 'RESTRICTED': 20};
    final raw = (assessment.domains.values
                .fold<int>(0, (sum, e) => sum + (points[e.status] ?? 0)) /
            assessed)
        .round();
    final restricted =
        assessment.domains.values.any((e) => e.status == 'RESTRICTED');
    final score = hasSafety
        ? math.min(raw, 29)
        : restricted
            ? math.min(raw, 39)
            : raw;
    final tone = hasSafety
        ? 'safety'
        : score < 40
            ? 'low'
            : score < 70
                ? 'caution'
                : 'ready';
    return RecoveryOverview(
        score,
        hasSafety
            ? 'SAFETY'
            : tone == 'low'
                ? 'LOW'
                : tone == 'caution'
                    ? 'CAUTION'
                    : 'READY',
        tone,
        '$assessed of 6 domains assessed · See each domain below');
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
      final domain =
          next['domains'] is Map ? (next['domains'] as Map)['sleep'] : null;
      if (domain is String) {
        details
            .add('Sleep & Heart ${domain.toLowerCase().replaceAll('_', ' ')}');
      }
      return FeedbackInsight('Not Enough Data',
          'Next morning: ${details.isEmpty ? 'wearable data unavailable' : details.join(' · ')}. More observations are needed; this does not show cause.');
    }
    final values = records
        .map((e) => numberOrNull(e.nextDay?['hrvDelta']))
        .whereType<double>()
        .toList();
    if (values.isEmpty) {
      return const FeedbackInsight(
          'Not Enough Data', 'Following-day HRV is unavailable.');
    }
    final average = values.reduce((a, b) => a + b) / values.length;
    return FeedbackInsight(
        average > 4 ? 'Possible Benefit' : 'No Clear Pattern',
        'Across ${records.length} observations, following-day HRV differed by ${average.toStringAsFixed(1)} ms on average. This is an association, not proof of cause.');
  }
}
