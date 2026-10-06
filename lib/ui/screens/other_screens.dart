import 'package:flutter/material.dart';
import '../../app/boxer_controller.dart';
import '../../domain/recovery_engine.dart';
import '../components.dart';
import '../design.dart';

class CampScreen extends StatefulWidget {
  const CampScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  State<CampScreen> createState() => _CampScreenState();
}

class _CampScreenState extends State<CampScreen> {
  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data!;
    final camp = CampClock.fromProfile(data.profile, data.currentDate);
    final weights = data.checkins.where((e) => e.weight != null).toList();
    final last = weights.isEmpty ? null : weights.last.weight;
    final recentAssessments =
        data.assessments.reversed.take(7).toList().reversed.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Camp', style: Theme.of(context).textTheme.headlineLarge),
          Text(
              '${CampClock.formatted(data.profile?.fightDate)} · ${data.profile?.officialWeighInWeight == null ? 'No weigh-in weight set' : '${data.profile!.officialWeighInWeight!.toStringAsFixed(1)} kg'}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13))
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
            child: Text('${camp.daysOut ?? '—'} days out',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)))
      ]),
      const SizedBox(height: 25),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (final phase in ['BASE', 'BUILD', 'PEAK', 'TAPER'])
          Text(phase,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: phase == camp.phase ? AppColors.ink : AppColors.muted))
      ]),
      const SizedBox(height: 6),
      Row(children: [
        for (final phase in ['BASE', 'BUILD', 'PEAK', 'TAPER'])
          Expanded(
              child: Container(
                  height: 9,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                      color:
                          phase == camp.phase ? AppColors.lime : AppColors.line,
                      borderRadius: BorderRadius.circular(3))))
      ]),
      const SizedBox(height: 12),
      Text(
          'Current phase: ${camp.phase.replaceAll('_', ' ')}. Recovery guidance uses the data available today.',
          style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      const SizedBox(height: 19),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const SectionLabel('Weight trend'),
          Text(last == null ? 'Unavailable' : '${last.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))
        ]),
        Text('${weights.length} recorded days · Monitoring only',
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 21),
        SizedBox(
            height: 105,
            child: CustomPaint(
                size: const Size(double.infinity, 105),
                painter: _TrendPainter(weights.map((e) => e.weight!).toList(),
                    const Color(0xff5576df)))),
        const SizedBox(height: 8),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('camp start',
              style: TextStyle(color: AppColors.muted, fontSize: 10)),
          Text('today',
              style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w800))
        ])
      ])),
      const SizedBox(height: 16),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Recovery trend & safety'),
        const SizedBox(height: 8),
        Text('${data.assessments.length} assessments recorded',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        if (recentAssessments.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Sleep & Heart · recent days',
              style: TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 8),
          Row(children: [
            for (final snapshot in recentAssessments)
              Expanded(
                  child: Container(
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                          color: switch (
                              (snapshot['domains'] as Map?)?['sleep']) {
                            'READY' => AppColors.teal,
                            'CAUTION' => AppColors.amber,
                            'RESTRICTED' => AppColors.red,
                            _ => AppColors.line
                          },
                          borderRadius: BorderRadius.circular(4))))
          ]),
        ],
        const SizedBox(height: 9),
        Text(
            'Recent limiter: ${widget.controller.assessment?.limiter == null ? 'Learning baseline' : domainLabels[widget.controller.assessment!.limiter]}'),
        const SizedBox(height: 9),
        const Text(
            'Weight data supports safety monitoring. Seek qualified support for weight or hydration concerns.',
            style: TextStyle(fontSize: 12, color: AppColors.muted))
      ])),
      const SizedBox(height: 16),
      OutlinedButton(
          onPressed: () => widget.controller.navigate('trends'),
          child: const Text('View all trends'))
    ]);
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = i * size.height / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b) - .5;
    final max = values.reduce((a, b) => a > b ? a : b) + .5;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(i * size.width / (values.length - 1),
          size.height - (values[i] - min) / (max - min) * size.height);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.values != values;
}

class TrendsScreen extends StatelessWidget {
  const TrendsScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    final data = controller.data!;
    final metrics = <(String, List<double>)>[
      ('HRV', data.wearables.map((e) => e.hrv).whereType<double>().toList()),
      (
        'Sleep',
        data.wearables
            .map((e) => e.sleepMinutes?.toDouble())
            .whereType<double>()
            .toList()
      ),
      (
        'Resting HR',
        data.wearables.map((e) => e.restingHr).whereType<double>().toList()
      ),
      (
        'Weight',
        data.checkins.map((e) => e.weight).whereType<double>().toList()
      ),
      (
        'FightCamp punches',
        data.fightCampSessions
            .map((e) => e.count?.toDouble())
            .whereType<double>()
            .toList()
      ),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
          title: 'History & Trends',
          onBack: () => controller.navigate('today')),
      const SizedBox(height: 20),
      for (final metric in metrics) ...[
        AppCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(metric.$1),
          const SizedBox(height: 8),
          Text(
              metric.$2.isEmpty
                  ? 'Unavailable'
                  : '${metric.$2.last.round()} latest · ${metric.$2.length} records',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SizedBox(
              height: 65,
              child: CustomPaint(
                  size: const Size(double.infinity, 65),
                  painter: _TrendPainter(metric.$2, AppColors.teal)))
        ])),
        const SizedBox(height: 12)
      ],
      const SectionLabel('Training load by type'),
      const SizedBox(height: 10),
      AppCard(
          child: Column(children: [
        for (final type in [
          'Sparring',
          'Boxing / Technical',
          'Conditioning',
          'Strength'
        ])
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(type),
                    Text(
                        '${data.sessions.where((e) => e.type == type).length} sessions')
                  ]))
      ])),
      const SizedBox(height: 15),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Recovery history'),
        const SizedBox(height: 8),
        Text(
            '${data.actions.length} actions completed · ${data.assessments.length} assessments'),
        const SizedBox(height: 8),
        for (final snapshot in data.assessments.reversed.take(7))
          Text(
              '${snapshot['date']}  ·  ${snapshot['limiter'] ?? 'Learning baseline'}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted))
      ]))
    ]);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    final data = controller.data!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Settings', onBack: () => controller.navigate('today')),
      const SizedBox(height: 20),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Athlete'),
        const SizedBox(height: 8),
        Text(data.profile?.name ?? 'Athlete',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text('Fight: ${CampClock.formatted(data.profile?.fightDate)}')
      ])),
      const SizedBox(height: 15),
      AppCard(
          child: Column(children: [
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.watch_outlined),
            title: const Text('Connected sources'),
            subtitle: const Text('Demo connections and permissions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => controller.navigate('connections')),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notifications'),
            value: data.notifications,
            onChanged: (_) => controller.toggleNotifications()),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy & consent'),
            subtitle: Text(
                'Privacy: ${data.privacyAcceptedAt == null ? 'Not accepted' : 'Accepted'} · Health sources: Demo only'))
      ])),
      const SizedBox(height: 15),
      if (data.mockOnly) ...[
        AppCard(
            color: const Color(0xfff3fbd9),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionLabel('Presentation demo'),
              const SizedBox(height: 6),
              const Text(
                  'Synthetic records are stored locally and survive a reload.',
                  style: TextStyle(fontSize: 12)),
              TextButton(
                  onPressed: () async {
                    final reset = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                                title: const Text('Restart demo?'),
                                content: const Text(
                                    'This clears only the current synthetic demo records and restores the starter dataset.'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text('Restart demo'))
                                ]));
                    if (reset == true) await controller.restartDemo();
                  },
                  child: const Text('Restart with fresh demo data'))
            ])),
        const SizedBox(height: 15),
      ],
      OutlinedButton(onPressed: controller.lock, child: const Text('Lock app')),
      const SizedBox(height: 10),
      OutlinedButton(
          onPressed: () async {
            final yes = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                        title: const Text('Delete local account?'),
                        content: const Text(
                            'This permanently deletes the local athlete data in this app.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete'))
                        ]));
            if (yes == true) await controller.deleteAccount();
          },
          child: const Text('Delete account and data',
              style: TextStyle(color: AppColors.red)))
    ]);
  }
}

class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    final data = controller.data!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
          title: 'Connected Sources',
          onBack: () => controller.navigate('settings')),
      const SizedBox(height: 12),
      const Text(
          'Apple Health and Health Connect demo data load automatically. No live wearable account or platform permission is connected.',
          style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 18),
      for (final kind in ['apple', 'android', 'fightcamp']) ...[
        AppCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              kind == 'apple'
                  ? 'Apple Health'
                  : kind == 'android'
                      ? 'Health Connect'
                      : 'FightCamp',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          Text(
              data.connections[kind] == 'MOCK_CONNECTED'
                  ? kind == 'fightcamp'
                      ? 'Demo connected automatically · synthetic punch data'
                      : 'Demo connected automatically · Sleep, HRV, Resting HR'
                  : data.connections[kind] == 'DISCONNECTED'
                      ? 'Demo disconnected · no data from this source'
                      : 'Unavailable · no live connection',
              style: const TextStyle(color: AppColors.muted)),
          if (kind != 'fightcamp')
            TextButton(
                onPressed: () => data.connections[kind] == 'MOCK_CONNECTED'
                    ? controller.disconnectDemo(kind)
                    : controller.connectDemo(kind),
                child: Text(data.connections[kind] == 'MOCK_CONNECTED'
                    ? 'Disconnect demo data'
                    : 'Restore demo data'))
        ])),
        const SizedBox(height: 10)
      ],
      if (data.healthAcceptedAt != null)
        OutlinedButton(
            onPressed: () => controller.revokeHealthConsent(),
            child: const Text(
                'Revoke health-data consent and clear source data',
                style: TextStyle(color: AppColors.red, fontSize: 12))),
    ]);
  }
}
