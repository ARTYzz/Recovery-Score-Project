import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/boxer_controller.dart';
import '../../domain/recovery_engine.dart';
import '../components.dart';
import '../design.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    final data = controller.data!;
    final result = controller.assessment!;
    final overview = RecoveryOverview.fromAssessment(result);
    final sleepBaseline = result.baselines['sleep']!;
    final hrvBaseline = result.baselines['hrv']!;
    final baselineReady = sleepBaseline.ready || hrvBaseline.ready;
    final baselineDays = sleepBaseline.count > hrvBaseline.count
        ? sleepBaseline.count
        : hrvBaseline.count;
    final wearable = data.latestWearable;
    final sleep = data.latestSleepSample;
    final hrv = data.latestMetricSample((sample) => sample.hrv);
    final restingHr = data.latestMetricSample((sample) => sample.restingHr);
    final actionDoneToday =
        data.actions.any((action) => action.date == data.currentDay);
    final observedActions =
        data.actions.where((action) => action.nextDay != null).toList();
    final observed = observedActions.isEmpty ? null : observedActions.last;
    final todayTraining = data.sessions
        .where((session) => session.date == data.currentDay)
        .toList();
    final name = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][data.currentDate.weekday - 1];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: Theme.of(context).textTheme.headlineLarge),
          Text(
              '${result.camp.daysOut ?? '—'} days out · ${result.camp.phase.replaceAll('_', ' ').toLowerCase()}',
              style: const TextStyle(color: AppColors.muted)),
          if (data.mockOnly || todayTraining.isNotEmpty)
            Text(
                '${data.mockOnly ? 'DEMO DATA · local and synthetic' : 'LOCAL DATA'}${todayTraining.isEmpty ? '' : ' · ${todayTraining.length} session${todayTraining.length == 1 ? '' : 's'} saved'}',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w800))
        ])),
        IconButton.filledTonal(
            onPressed: () => controller.navigate('settings'),
            icon: const Icon(Icons.settings_outlined),
            style: IconButton.styleFrom(backgroundColor: Colors.white))
      ]),
      const SizedBox(height: 12),
      ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: result.camp.daysOut == null
                  ? 0
                  : (1 - result.camp.daysOut!.clamp(0, 56) / 56),
              minHeight: 6,
              color: AppColors.lime,
              backgroundColor: AppColors.line)),
      const SizedBox(height: 7),
      const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [SectionLabel('Camp start'), SectionLabel('Fight night')]),
      const SizedBox(height: 10),
      Text(
          "●  TODAY'S BRAKE · ${(result.limiter == null ? 'LEARNING BASELINE' : domainLabels[result.limiter]!).toUpperCase()}",
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .5)),
      const SizedBox(height: 10),
      Center(
          child: SizedBox(
              width: 116,
              height: 116,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                    child: CircularProgressIndicator(
                        value: overview.score == null
                            ? result.observedCount / 6
                            : overview.score! / 100,
                        strokeWidth: 9,
                        color: overview.tone == 'safety'
                            ? AppColors.red
                            : overview.tone == 'low'
                                ? AppColors.amber
                                : AppColors.lime,
                        backgroundColor: AppColors.line)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      overview.score?.toString() ?? '${result.observedCount}/6',
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1)),
                  Text(overview.label,
                      style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12))
                ])
              ]))),
      if (overview.score == null) ...[
        const SizedBox(height: 4),
        Center(
            child: Text(
                '${result.observedCount} domains have data · ${result.assessedCount} assessed',
                style: const TextStyle(fontSize: 10, color: AppColors.muted))),
        const SizedBox(height: 2),
        Center(
            child: Text(
                baselineReady
                    ? 'Recovery score pending · more domain data needed'
                    : 'Recovery score pending · baseline $baselineDays/7 days',
                style: const TextStyle(fontSize: 10, color: AppColors.muted))),
      ],
      const SizedBox(height: 8),
      AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            const Icon(Icons.bedtime_outlined, color: AppColors.teal),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Last sleep',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  Text(
                      sleep?.sleepMinutes == null
                          ? 'Unavailable'
                          : '${sleep!.sleepMinutes! ~/ 60} h ${sleep.sleepMinutes! % 60} min',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800))
                ])),
            if (sleep?.sleepMinutes != null)
              Text(
                  result.domains['sleep']!.status == 'INSUFFICIENT_DATA'
                      ? 'Learning baseline'
                      : 'Auto loaded',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted))
          ])),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
            child: MetricTile(
                'Last HRV', hrv?.hrv?.round().toString() ?? 'Unavailable',
                unit: hrv?.hrv == null ? '' : ' ms')),
        const SizedBox(width: 8),
        Expanded(
            child: MetricTile('Last HR',
                restingHr?.restingHr?.round().toString() ?? 'Unavailable',
                unit: restingHr?.restingHr == null ? '' : ' bpm'))
      ]),
      const SizedBox(height: 10),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: InkWell(
            onTap: () => controller.navigate('guidance'),
            child: Row(children: [
              Expanded(
                  child: Text(
                      result.trainingGuidance['Sparring']?.status == 'AVOID'
                          ? 'Skip sparring today'
                          : 'Review training guidance',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800))),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ])),
      ),
      const SizedBox(height: 10),
      AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.check, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'TRAIN  ${result.allowed.isEmpty ? 'Awaiting more data' : result.allowed.join(' · ')}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)))
            ]),
            const Divider(height: 14),
            Row(children: [
              const Icon(Icons.block, color: AppColors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'SKIP  ${result.avoid.isEmpty ? 'No specific restriction' : result.avoid.join(' · ')}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)))
            ]),
          ])),
      const SizedBox(height: 10),
      GridView.count(
          crossAxisCount: 3,
          mainAxisExtent: 98,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final key in domainKeys)
              _DomainMiniCard(domainLabels[key]!, result.domains[key]!.status,
                  detail: key == 'sleep' &&
                          result.domains[key]!.status == 'INSUFFICIENT_DATA' &&
                          (sleep?.sleepMinutes != null || hrv?.hrv != null)
                      ? [
                          if (sleep?.sleepMinutes != null)
                            '${sleep!.sleepMinutes! ~/ 60}h ${sleep.sleepMinutes! % 60}m',
                          if (sleep?.sleepMinutes == null && hrv?.hrv != null)
                            'HRV ${hrv!.hrv!.round()}ms'
                        ].join()
                      : null,
                  baselineDays: key == 'sleep'
                      ? [
                          result.baselines['sleep']!.count,
                          result.baselines['hrv']!.count
                        ].reduce((a, b) => a > b ? a : b)
                      : null)
          ]),
      const SizedBox(height: 10),
      InkWell(
          onTap: () async {
            if (actionDoneToday && data.mockOnly) {
              try {
                await controller.advanceMockDay();
              } catch (error) {
                controller.showError(error);
              }
            } else {
              controller.navigate('tonight');
            }
          },
          child: AppCard(
              color: const Color(0xfff3fbd9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      SectionLabel(actionDoneToday
                          ? 'Recovery action completed'
                          : 'One thing tonight'),
                      Text(
                          actionDoneToday && data.mockOnly
                              ? 'Continue to next morning · Demo'
                              : result.action.title,
                          style: const TextStyle(fontWeight: FontWeight.w800))
                    ])),
                CircleAvatar(
                    backgroundColor: AppColors.lime,
                    child: Icon(
                        actionDoneToday
                            ? Icons.arrow_forward
                            : Icons.play_arrow,
                        color: AppColors.ink)),
              ]))),
      const SizedBox(height: 12),
      if (todayTraining.isNotEmpty) ...[
        AppCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionLabel('Training saved today'),
          const SizedBox(height: 7),
          for (final session in todayTraining.reversed.take(2))
            Text(
                '${session.type} · ${session.type == 'Sparring' ? '${session.rounds} rounds' : '${session.duration} min'}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          TextButton(
              onPressed: () => controller.navigate('training'),
              child: const Text('Log another session →'))
        ])),
        const SizedBox(height: 12),
      ],
      if (observed != null) ...[
        AppCard(
            color: const Color(0xffedf8f2),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionLabel('Next-morning check'),
              const SizedBox(height: 7),
              Text(controller.feedback.insight(data, observed.id).label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17)),
              Text(controller.feedback.insight(data, observed.id).detail,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted))
            ])),
        const SizedBox(height: 12),
      ],
      if (result.safety.isNotEmpty) ...[
        AppCard(
            color: const Color(0xffffecea),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Safety first',
                  style: TextStyle(
                      color: AppColors.red,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(result.safety.map((e) => e.message).join(' ')),
              TextButton(
                  onPressed: () => controller.navigate('brain'),
                  child: const Text('Review safety details →'))
            ])),
        const SizedBox(height: 13)
      ],
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel("Today's primary limiter"),
        const SizedBox(height: 7),
        Text(
            result.limiter == null
                ? 'Learning your baseline'
                : domainLabels[result.limiter]!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(result.reason, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 14),
        const SectionLabel('You can train'),
        Text(result.allowed.isEmpty
            ? 'Insufficient data to suggest training'
            : result.allowed.join(' · ')),
        const SizedBox(height: 12),
        const SectionLabel('Avoid today'),
        Text(
            result.avoid.isEmpty
                ? 'No specific restriction from available data'
                : result.avoid.join(' · '),
            style: const TextStyle(color: AppColors.red))
      ])),
      const SizedBox(height: 13),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Connected data'),
        const SizedBox(height: 8),
        Text(
            'Health: ${wearable == null ? 'Unavailable' : '${wearable.source} · ${wearable.mode}'}'),
        Text('FightCamp: ${data.connections['fightcamp'] ?? 'Unavailable'}'),
        const SizedBox(height: 8),
        TextButton(
            onPressed: () => controller.navigate('fightcamp'),
            child: const Text('View FightCamp performance →'))
      ])),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
            child: OutlinedButton(
                onPressed: () => controller.navigate('training'),
                child: const Text('Log training'))),
        const SizedBox(width: 8),
        Expanded(
            child: OutlinedButton(
                onPressed: () => controller.navigate('trends'),
                child: const Text('View trends')))
      ]),
    ]);
  }
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    final observations = controller.data!.actions
        .where((action) => action.nextDay != null)
        .toList();
    final action = observations.isEmpty ? null : observations.last;
    final insight = action == null
        ? const FeedbackInsight('Not Enough Data',
            'Complete a recovery action and check in the next morning to see an observation.')
        : controller.feedback.insight(controller.data!, action.id);
    final title = switch (action?.id) {
      'breathing' => 'Breathing down-regulation',
      'mobility' => 'Gentle mobility',
      'early-bed' => 'Earlier bedtime',
      _ => 'Recovery action'
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
          title: 'Next Morning',
          subtitle: 'Your recovery follow-up',
          onBack: () => controller.navigate('today')),
      const SizedBox(height: 24),
      const SectionLabel('Last night'),
      const SizedBox(height: 9),
      AppCard(
          child: Row(children: [
        const Icon(Icons.check_circle_outline, color: AppColors.teal),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))
      ])),
      const SizedBox(height: 16),
      const SectionLabel('What changed this morning'),
      const SizedBox(height: 9),
      AppCard(
          color: const Color(0xffedf8f2),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(insight.label,
                style:
                    const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 11),
            Text(insight.detail,
                style: const TextStyle(fontSize: 14, height: 1.45))
          ])),
      const SizedBox(height: 18),
      const Text(
          'A single morning can show a change, not what caused it. Keep checking in to learn your pattern.',
          style: TextStyle(color: AppColors.muted, fontSize: 12)),
      const SizedBox(height: 30),
      PrimaryButton('See today’s recovery',
          onPressed: () => controller.navigate('today')),
    ]);
  }
}

class _DomainMiniCard extends StatelessWidget {
  const _DomainMiniCard(this.label, this.status,
      {this.detail, this.baselineDays});
  final String label;
  final String status;
  final String? detail;
  final int? baselineDays;
  @override
  Widget build(BuildContext context) {
    final learning = status == 'INSUFFICIENT_DATA' && detail != null;
    final color = status == 'READY'
        ? AppColors.lime
        : status == 'CAUTION'
            ? AppColors.amber
            : status == 'RESTRICTED'
                ? AppColors.red
                : learning
                    ? AppColors.teal
                    : AppColors.muted;
    return AppCard(
        padding: const EdgeInsets.all(8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                  label == 'Brain'
                      ? Icons.psychology_outlined
                      : label == 'Fuel & Weight'
                          ? Icons.water_drop_outlined
                          : label == 'Sleep & Heart'
                              ? Icons.nights_stay_outlined
                              : label == 'Power & Speed'
                                  ? Icons.bolt_outlined
                                  : label == 'Body'
                                      ? Icons.accessibility_new_outlined
                                      : Icons.auto_awesome_outlined,
                  size: 16,
                  color: AppColors.muted),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800)),
              if (learning) ...[
                Text(detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700)),
                Text('Baseline ${baselineDays ?? 0}/7',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 9, color: AppColors.muted)),
              ],
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: status == 'READY'
                          ? .85
                          : status == 'CAUTION'
                              ? .55
                              : status == 'RESTRICTED'
                                  ? .2
                                  : learning
                                      ? ((baselineDays ?? 0) / 7).clamp(0, 1)
                                      : 0,
                      minHeight: 4,
                      backgroundColor: AppColors.line,
                      color: color)),
            ]));
  }
}

class TrainingGuidanceScreen extends StatelessWidget {
  const TrainingGuidanceScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    final result = controller.assessment!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
          title: 'Training Today',
          subtitle: 'Guidance for each session type',
          onBack: () => controller.navigate('today')),
      const SizedBox(height: 20),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Primary limiter'),
        const SizedBox(height: 8),
        Text(
            result.limiter == null
                ? 'Learning your baseline'
                : domainLabels[result.limiter]!,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(result.reason, style: const TextStyle(color: AppColors.muted))
      ])),
      const SizedBox(height: 14),
      if (result.safety.isNotEmpty) ...[
        AppCard(
            color: const Color(0xffffecea),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Safety warning overrides readiness',
                  style: TextStyle(
                      color: AppColors.red, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text(result.safety.map((flag) => flag.message).join(' '))
            ])),
        const SizedBox(height: 14)
      ],
      const FieldTitle('Four training types'),
      for (final load in [
        'Sparring',
        'Boxing / Technical',
        'Conditioning',
        'Strength'
      ]) ...[
        Builder(builder: (context) {
          final advice = result.trainingGuidance[load]!;
          final color = advice.status == 'AVOID'
              ? AppColors.red
              : advice.status == 'MODIFIED'
                  ? AppColors.amber
                  : advice.status == 'AVAILABLE'
                      ? AppColors.teal
                      : AppColors.muted;
          return AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(load,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800))),
                      Text(
                          advice.status == 'AVOID'
                              ? 'Avoid'
                              : advice.status == 'MODIFIED'
                                  ? 'Modify'
                                  : advice.status == 'AVAILABLE'
                                      ? 'Can train'
                                      : 'No data',
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w800))
                    ]),
                    const SizedBox(height: 6),
                    Text(advice.title,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(advice.reason,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12))
                  ]));
        }),
        const SizedBox(height: 9)
      ],
      const SizedBox(height: 12),
      PrimaryButton('Log after training',
          onPressed: () => controller.navigate('training')),
    ]);
  }
}

class FightCampScreen extends StatelessWidget {
  const FightCampScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    final data = controller.data!;
    final latest = data.latestFightCamp;
    final baseline = controller.assessment!.baselines['punch']!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
          title: 'FightCamp',
          subtitle: 'Prototype / Mock source',
          onBack: () => controller.navigate('today')),
      const SizedBox(height: 22),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Latest session'),
        const SizedBox(height: 10),
        Text(latest?.count?.toString() ?? 'Unavailable',
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800)),
        const Text('punches', style: TextStyle(color: AppColors.muted)),
        const Divider(),
        Text('Rounds: ${latest?.rounds?.toString() ?? 'Unavailable'}'),
        Text('Speed: ${latest?.speed?.toStringAsFixed(1) ?? 'Unavailable'}'),
        Text('Output: ${latest?.output?.toString() ?? 'Unavailable'}'),
        const SizedBox(height: 8),
        Text(
            'Personal baseline: ${baseline.value?.round().toString() ?? 'Learning'} (${baseline.count} days)',
            style: const TextStyle(color: AppColors.muted))
      ])),
      const SizedBox(height: 16),
      const AppCard(
          color: Color(0xfff3fbd9),
          child: Text(
              'FightCamp data is synthetic for the prototype. No undocumented API or real connection is used. Punch count informs Power & Speed when a personal baseline is available.'))
    ]);
  }
}

class BrainScreen extends StatelessWidget {
  const BrainScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    final assessment = controller.assessment!;
    final brain = assessment.domains['brain']!;
    final recent = controller.data!.sessions.where((session) {
      final day = DateTime.tryParse(session.date);
      return session.type == 'Sparring' &&
          day != null &&
          controller.data!.currentDate.difference(day).inDays <= 28;
    }).toList();
    final rounds = recent.fold<int>(0, (sum, session) => sum + session.rounds);
    final contacts = List<int>.generate(14, (index) {
      final date =
          controller.data!.currentDate.subtract(Duration(days: 13 - index));
      return recent
          .where((session) =>
              session.date ==
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}')
          .fold<int>(0, (sum, session) => sum + session.rounds);
    });
    final headSafety =
        assessment.safety.where((flag) => flag.domain == 'brain').toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
          title: 'Brain',
          subtitle: 'Impact load & head clarity',
          onBack: () => controller.navigate('today')),
      const SizedBox(height: 20),
      AppCard(
          child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionLabel('28-day head contact'),
          const SizedBox(height: 8),
          RichText(
              text: TextSpan(children: [
            TextSpan(
                text: '$rounds',
                style: TextStyle(
                    color: headSafety.isEmpty ? AppColors.ink : AppColors.red,
                    fontSize: 31,
                    fontWeight: FontWeight.w800)),
            const TextSpan(
                text: ' reported rounds',
                style: TextStyle(color: AppColors.ink, fontSize: 14))
          ])),
          const SizedBox(height: 4),
          Text('${recent.length} sparring sessions in 28 days',
              style: const TextStyle(color: AppColors.muted, fontSize: 12))
        ])),
        Container(
            width: 59,
            height: 59,
            decoration: BoxDecoration(
                color: headSafety.isEmpty
                    ? const Color(0xffedf8f2)
                    : const Color(0xffffecea),
                borderRadius: BorderRadius.circular(18)),
            child: Icon(
                headSafety.isEmpty
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                color: headSafety.isEmpty ? AppColors.teal : AppColors.red))
      ])),
      const SizedBox(height: 13),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Last 14 days'),
        const SizedBox(height: 20),
        SizedBox(
            height: 82,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final count in contacts)
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                            height:
                                count == 0 ? 3 : (count * 11.0).clamp(8, 80),
                            decoration: BoxDecoration(
                                color: count >= 6
                                    ? AppColors.red
                                    : count > 0
                                        ? AppColors.teal
                                        : AppColors.line,
                                borderRadius: BorderRadius.circular(4)))))
            ])),
        const SizedBox(height: 8),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('14 days ago',
              style: TextStyle(color: AppColors.muted, fontSize: 10)),
          Text('today',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10))
        ])
      ])),
      const SizedBox(height: 18),
      AppCard(
          color: headSafety.isEmpty ? Colors.white : const Color(0xfffff5f3),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(headSafety.isEmpty ? 'CURRENT STATUS' : '⚠  FLAGGED',
                style: TextStyle(
                    color: headSafety.isEmpty ? AppColors.teal : AppColors.red,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
            const SizedBox(height: 10),
            Text(
                headSafety.isEmpty
                    ? 'Track head contact and symptoms.'
                    : 'Stop head-contact training and seek qualified evaluation.',
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800, height: 1.15)),
            const SizedBox(height: 10),
            Text(
                headSafety.isEmpty
                    ? (brain.reasons.isEmpty
                        ? 'No head-impact report yet.'
                        : brain.reasons.join(' · '))
                    : headSafety.map((flag) => flag.message).join(' '),
                style: const TextStyle(fontSize: 13)),
            const Divider(height: 25),
            const Text(
                'This app does not diagnose concussion or provide medical clearance.',
                style: TextStyle(color: AppColors.muted, fontSize: 12))
          ])),
    ]);
  }
}

class TonightScreen extends StatefulWidget {
  const TonightScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  State<TonightScreen> createState() => _TonightScreenState();
}

class _TonightScreenState extends State<TonightScreen> {
  Timer? timer;
  int? remaining;
  DateTime? started;
  bool running = false;
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void start() {
    setState(() {
      remaining ??= widget.controller.assessment!.action.seconds;
      started ??= DateTime.now();
      running = true;
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        remaining = (remaining! - 1).clamp(0, 99999);
        if (remaining == 0) {
          timer?.cancel();
          running = false;
        }
      });
    });
  }

  void pause() {
    timer?.cancel();
    setState(() => running = false);
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.controller.assessment!.action;
    final seconds = remaining ?? action.seconds;
    final insight =
        widget.controller.feedback.insight(widget.controller.data!, action.id);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(
            onPressed: () => widget.controller.navigate('today'),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.lime),
            style:
                IconButton.styleFrom(backgroundColor: const Color(0xff303137))),
        const SizedBox(width: 8),
        const Expanded(
            child: Text('Tonight',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800))),
        Text(TimeOfDay.now().format(context),
            style: const TextStyle(
                color: AppColors.teal, fontWeight: FontWeight.w800))
      ]),
      const SizedBox(height: 26),
      const Text('ONE THING, THEN SLEEP',
          style: TextStyle(
              color: AppColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1)),
      const SizedBox(height: 11),
      Text(action.title,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              height: 1.08)),
      const SizedBox(height: 12),
      Text(action.reason,
          style: const TextStyle(color: Color(0xff9eaaa9), fontSize: 15)),
      const SizedBox(height: 36),
      Center(
          child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                    child: CircularProgressIndicator(
                        value: seconds / action.seconds,
                        strokeWidth: 10,
                        color: AppColors.teal,
                        backgroundColor: const Color(0xff344944))),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 55,
                          fontWeight: FontWeight.w800)),
                  const Text('4 in · 8 out · nose only',
                      style: TextStyle(color: Color(0xff9eaaa9), fontSize: 12))
                ]),
              ]))),
      const SizedBox(height: 34),
      PrimaryButton(
          running
              ? 'Pause'
              : started == null
                  ? 'Start'
                  : 'Resume',
          onPressed: running ? pause : start,
          color: AppColors.teal),
      const SizedBox(height: 9),
      if (started != null)
        TextButton(
            onPressed: () async {
              timer?.cancel();
              await widget.controller.completeAction(started!);
            },
            child: const SizedBox(
                width: double.infinity,
                child: Center(
                    child: Text('Complete action',
                        style: TextStyle(color: Colors.white))))),
      const SizedBox(height: 30),
      const Text('DID IT ACTUALLY WORK?',
          style: TextStyle(
              color: AppColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1)),
      const SizedBox(height: 12),
      Text(insight.label,
          style: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      Text(insight.detail,
          style: const TextStyle(color: Color(0xff9eaaa9), fontSize: 13)),
    ]);
  }
}
