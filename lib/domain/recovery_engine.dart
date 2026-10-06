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
    final source = data.latestWearable?.source;
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
    final check = data.latestCheckIn;
    final flags = <SafetyFlag>[];
    if (check?.headSymptoms == true) {
      flags.add(const SafetyFlag('HEAD_SYMPTOMS', 'brain',
          'New symptoms after head contact. Avoid sparring and other head-impact training. Seek qualified medical evaluation.'));
    }
    if (data.sessions.reversed
            .take(7)
            .where((e) => e.type == 'Sparring' && e.contact == 'Heavy')
            .length >=
        2) {
      flags.add(const SafetyFlag('HEAD_LOAD', 'brain',
          'Repeated heavy head contact reported recently. Avoid further head-impact training and consider qualified evaluation.'));
    }
    if (check?.painSeverity == 'Severe') {
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

class Assessment {
  Assessment(
      {required this.camp,
      required this.domains,
      required this.safety,
      required this.limiter,
      required this.reason,
      required this.allowed,
      required this.avoid,
      required this.action,
      required this.baselines});
  final CampState camp;
  final Map<String, DomainResult> domains;
  final List<SafetyFlag> safety;
  final String? limiter;
  final String reason;
  final List<String> allowed;
  final List<String> avoid;
  final RecoveryAction action;
  final Map<String, Baseline> baselines;

  int get assessedCount =>
      domains.values.where((e) => e.status != 'INSUFFICIENT_DATA').length;
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
    final wear = data.latestWearable;
    final check = data.latestCheckIn;
    final nutrition = data.latestNutrition;
    final training = data.latestTraining;
    final punch = data.connections['fightcamp'] == 'MOCK_CONNECTED' ||
            data.connections['fightcamp'] == 'CONNECTED'
        ? data.latestFightCamp
        : null;
    final camp = CampClock.fromProfile(data.profile, data.currentDate);
    final domains = {
      for (final key in domainKeys)
        key: const DomainResult('INSUFFICIENT_DATA', <String>[])
    };

    if (wear?.sleepMinutes != null ||
        wear?.hrv != null ||
        wear?.restingHr != null) {
      final reasons = <String>[];
      if (sleep.ready &&
          wear?.sleepMinutes != null &&
          wear!.sleepMinutes! < sleep.value! * 0.85) {
        reasons.add('Sleep below your baseline');
      }
      if (hrv.ready && wear?.hrv != null && wear!.hrv! < hrv.value! * 0.85) {
        reasons.add('HRV below your baseline');
      }
      if (rhr.ready &&
          wear?.restingHr != null &&
          wear!.restingHr! > rhr.value! * 1.1) {
        reasons.add('Resting HR above your baseline');
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
      domains['fuel'] =
          DomainResult(reasons.isEmpty ? 'READY' : 'CAUTION', reasons);
    }
    if (training != null || check?.headSymptoms == true) {
      final reasons = <String>[];
      if (training?.type == 'Sparring') {
        reasons.add('${training!.rounds} sparring rounds reported');
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
    if (check?.soreness.isNotEmpty == true ||
        training?.soreness.isNotEmpty == true) {
      final soreness = check?.soreness.isNotEmpty == true
          ? check!.soreness
          : training!.soreness;
      domains['body'] = DomainResult(
          check?.painSeverity == 'Severe' ? 'RESTRICTED' : 'CAUTION',
          ['Soreness reported: ${soreness.join(', ')}']);
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
    String? limiter = safety.isNotEmpty ? safety.first.domain : null;
    if (limiter == null) {
      for (final key in domainKeys) {
        final status = domains[key]!.status;
        if ((rank[status] ?? 0) >= 2 &&
            (limiter == null ||
                rank[status]! > rank[domains[limiter]!.status]!)) {
          limiter = key;
        }
      }
    }
    final allowed = <String>{'Boxing / Technical', 'Conditioning', 'Strength'};
    final avoid = <String>{};
    if (domains['brain']!.status == 'RESTRICTED') {
      avoid.add('Sparring');
    } else if (domains['brain']!.status == 'CAUTION') {
      avoid.add('Hard sparring');
    } else if (domains['brain']!.status == 'READY') {
      allowed.add('Sparring');
    }
    if (domains['sleep']!.status == 'RESTRICTED') {
      avoid.add('Hard conditioning');
    }
    if (domains['body']!.status == 'RESTRICTED') {
      avoid.add('Strength for affected area');
    }
    if (camp.phase == 'FIGHT_WEEK') avoid.add('Sparring');
    if (safety.isNotEmpty) allowed.remove('Sparring');
    if (domains.values.where((e) => e.status != 'INSUFFICIENT_DATA').length <
            4 &&
        safety.isEmpty) {
      allowed.clear();
      avoid.clear();
    }
    final sleepStatus = domains['sleep']!.status;
    final action = ['CAUTION', 'RESTRICTED'].contains(sleepStatus)
        ? const RecoveryAction('breathing', '10 min breathing down-regulation',
            'Sleep & Heart needs attention today.', 600)
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
