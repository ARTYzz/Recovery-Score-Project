import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/boxer_controller.dart';
import '../../domain/recovery_engine.dart';
import '../../domain/trends_dashboard.dart';
import '../components.dart';
import '../design.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen(this.controller, {super.key});
  final BoxerController controller;

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  TrendPeriod period = TrendPeriod.week;
  DateTime anchor = DateTime.now();
  String selectedDomain = 'sleep';

  @override
  Widget build(BuildContext context) {
    final window = TrendWindow(period, anchor);
    final dashboard = TrendsDashboard.fromData(widget.controller.data!, window);
    final hasHealth = ['Sleep', 'HRV', 'Resting HR', 'Heart rate']
        .any((name) => dashboard.metrics[name]!.observedBuckets > 0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
          title: 'Trends',
          subtitle: 'Your recorded history',
          onBack: () => widget.controller.navigate('today')),
      const SizedBox(height: 18),
      _periodSelector(),
      const SizedBox(height: 14),
      Row(children: [
        IconButton.filledTonal(
            tooltip: 'Previous ${period.name}',
            onPressed: () => setState(() => anchor = window.shifted(-1).anchor),
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(backgroundColor: Colors.white)),
        Expanded(
            child: Column(children: [
          Text(_windowLabel(window),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          Text(
              switch (period) {
                TrendPeriod.day => 'Daily record',
                TrendPeriod.week => 'Daily readings · calendar week',
                TrendPeriod.month => 'Daily readings · calendar month',
                TrendPeriod.year => 'Monthly averages · calendar year',
              },
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ])),
        IconButton.filledTonal(
            tooltip: 'Next ${period.name}',
            onPressed: window.includesToday
                ? null
                : () => setState(() => anchor = window.shifted(1).anchor),
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(backgroundColor: Colors.white)),
      ]),
      const SizedBox(height: 14),
      if (!hasHealth) ...[
        AppCard(
            color: const Color(0xffeef8f4),
            child: Text(
                'No health readings in this ${period.name}. Sleep, HRV and heart metrics appear here after a successful HealthKit sync. Missing data is Unavailable.',
                style: const TextStyle(fontSize: 12, color: AppColors.ink))),
        const SizedBox(height: 14),
      ],
      const SectionLabel('Sleep & heart'),
      const SizedBox(height: 9),
      _metricCard(dashboard, 'Sleep', 'hours', AppColors.teal,
          (value) => '${value.toStringAsFixed(1)} h'),
      _metricCard(dashboard, 'HRV', 'ms', const Color(0xff7d8edb),
          (value) => '${value.round()} ms'),
      _metricCard(dashboard, 'Resting HR', 'bpm', AppColors.red,
          (value) => '${value.round()} bpm'),
      _metricCard(dashboard, 'Heart rate', 'bpm', AppColors.amber,
          (value) => '${value.round()} bpm'),
      const SizedBox(height: 4),
      const SectionLabel('Training load'),
      const SizedBox(height: 9),
      _trainingCard(dashboard),
      const SizedBox(height: 8),
      _sessionHistory(dashboard),
      const SizedBox(height: 9),
      _metricCard(dashboard, 'Watch workout', 'min', AppColors.teal,
          (value) => '${value.round()} min',
          note:
              'Wearable workout duration is shown separately because its boxing type is unknown.'),
      const SizedBox(height: 17),
      const SectionLabel('Weight & punch performance'),
      const SizedBox(height: 9),
      _metricCard(dashboard, 'Weight', 'kg', AppColors.amber,
          (value) => '${value.toStringAsFixed(1)} kg'),
      _metricCard(dashboard, 'FightCamp punches', 'punches', AppColors.lime,
          (value) => '${value.round()} punches',
          note: 'FightCamp is demo data; no real account is connected.'),
      const SizedBox(height: 4),
      const SectionLabel('Recovery domains'),
      const SizedBox(height: 9),
      _domainCard(dashboard),
      const SizedBox(height: 12),
      _historySummary(dashboard),
    ]);
  }

  Widget _periodSelector() => Row(children: [
        for (final choice in TrendPeriod.values)
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: OutlinedButton(
                      onPressed: () => setState(() {
                            period = choice;
                          }),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          foregroundColor: AppColors.ink,
                          backgroundColor:
                              period == choice ? AppColors.lime : Colors.white,
                          side: BorderSide(
                              color: period == choice
                                  ? AppColors.lime
                                  : AppColors.line),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13))),
                      child: Text(
                          choice.name[0].toUpperCase() +
                              choice.name.substring(1),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)))))
      ]);

  Widget _metricCard(TrendsDashboard dashboard, String name, String unit,
      Color color, String Function(double) format,
      {String? note}) {
    final series = dashboard.metrics[name]!;
    return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: AppCard(
            padding: const EdgeInsets.all(15),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: SectionLabel(name)),
                Text(
                    series.latest == null
                        ? 'Unavailable'
                        : format(series.latest!),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: series.latest == null
                            ? AppColors.muted
                            : AppColors.ink)),
              ]),
              const SizedBox(height: 3),
              Text(
                  '${series.observedBuckets} of ${series.values.length} periods with data · $unit',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 11),
              _LineChart(series.values,
                  dashboard.window.buckets.map((e) => e.label).toList(), color),
              if (note != null) ...[
                const SizedBox(height: 7),
                Text(note,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ])));
  }

  Widget _trainingCard(TrendsDashboard dashboard) {
    final total =
        dashboard.trainingSessions.values.fold<int>(0, (a, b) => a + b);
    return AppCard(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: SectionLabel('Minutes by training type')),
            Text('$total sessions',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 13),
          _TrainingChart(dashboard.trainingMinutes,
              dashboard.window.buckets.map((e) => e.label).toList()),
          const SizedBox(height: 12),
          for (final type in trainingTypes)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          color: _trainingColor(type), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(type, style: const TextStyle(fontSize: 12))),
                  Text(
                      '${dashboard.trainingSessions[type]} sessions · ${dashboard.trainingMinutes[type]!.fold<int>(0, (a, b) => a + b)} min',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800)),
                ])),
          if (total == 0)
            const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text('No training sessions logged in this period.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted))),
        ]));
  }

  Widget _sessionHistory(TrendsDashboard dashboard) {
    final sessions = widget.controller.data!.sessions
        .where((session) => dashboard.window.buckets
            .any((bucket) => bucket.contains(session.date)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (sessions.isEmpty) return const SizedBox.shrink();
    return AppCard(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionLabel('Sessions in this period'),
          if (sessions.length > 8)
            Text(
                'Latest 8 of ${sessions.length} · choose a shorter period for more detail',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 8),
          for (final session in sessions.take(8)) ...[
            const Divider(height: 14),
            Row(children: [
              Expanded(
                  child: Text(session.type,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800))),
              Text(_shortDay(session.date),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
            Text(
                '${session.duration} min · ${session.intensity}${session.type == 'Sparring' ? ' · ${session.rounds} rounds · ${session.contact} contact' : ''}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ]));
  }

  Widget _domainCard(TrendsDashboard dashboard) {
    final series = dashboard.domainScores[selectedDomain]!;
    return AppCard(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Each domain has its own score. No overall average.',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 11),
          Wrap(spacing: 5, runSpacing: 5, children: [
            for (final key in domainKeys)
              ChoiceChip(
                  label: Text(domainLabels[key]!,
                      style: const TextStyle(fontSize: 10)),
                  selected: selectedDomain == key,
                  onSelected: (_) => setState(() => selectedDomain = key),
                  selectedColor: AppColors.lime,
                  side: const BorderSide(color: AppColors.line),
                  visualDensity: VisualDensity.compact),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(child: SectionLabel(domainLabels[selectedDomain]!)),
            Text(
                series.latest == null
                    ? 'Unavailable'
                    : '${series.latest!.round()}/100',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 9),
          _LineChart(
              series.values,
              dashboard.window.buckets.map((e) => e.label).toList(),
              AppColors.teal),
          const SizedBox(height: 5),
          const Text(
              'Past scores appear after check-ins or logs. Missing days stay blank.',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ]));
  }

  Widget _historySummary(TrendsDashboard dashboard) => AppCard(
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Recovery history'),
        const SizedBox(height: 8),
        Text('${dashboard.completedActions} actions completed',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (dashboard.limiters.isEmpty)
          const Text('No primary limiter recorded in this period.',
              style: TextStyle(fontSize: 11, color: AppColors.muted))
        else
          for (final entry in dashboard.limiters.entries)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                    '${domainLabels[entry.key]} · ${entry.value} day${entry.value == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12))),
      ]));
}

class _LineChart extends StatelessWidget {
  const _LineChart(this.values, this.labels, this.color);
  final List<double?> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
            height: 92,
            width: double.infinity,
            child: CustomPaint(painter: _LineChartPainter(values, color))),
        const SizedBox(height: 5),
        _ChartLabels(labels),
      ]);
}

class _ChartLabels extends StatelessWidget {
  const _ChartLabels(this.labels);
  final List<String> labels;
  @override
  Widget build(BuildContext context) {
    if (labels.length == 1) {
      return Center(
          child: Text(labels.single,
              style: const TextStyle(fontSize: 10, color: AppColors.muted)));
    }
    final indices = labels.length <= 12
        ? List.generate(labels.length, (i) => i)
        : <int>{
            0,
            labels.length ~/ 4,
            labels.length ~/ 2,
            labels.length * 3 ~/ 4,
            labels.length - 1
          }.toList()
      ..sort();
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      for (final index in indices)
        Text(labels[index],
            style: const TextStyle(fontSize: 10, color: AppColors.muted)),
    ]);
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter(this.values, this.color);
  final List<double?> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = 4 + i * (size.height - 8) / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final observed = values.whereType<double>().toList();
    if (observed.isEmpty) return;
    final low = observed.reduce(math.min);
    final high = observed.reduce(math.max);
    final pad = math.max((high - low) * .15, high == low ? 1.0 : .01);
    final min = low - pad;
    final max = high + pad;
    Offset point(int i, double value) => Offset(
        values.length == 1
            ? size.width / 2
            : i * size.width / (values.length - 1),
        size.height - 5 - (value - min) / (max - min) * (size.height - 10));
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) continue;
      final current = point(i, value);
      if (i > 0 && values[i - 1] != null) {
        canvas.drawLine(point(i - 1, values[i - 1]!), current, stroke);
      }
      canvas.drawCircle(current, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.values != values || old.color != color;
}

class _TrainingChart extends StatelessWidget {
  const _TrainingChart(this.minutes, this.labels);
  final Map<String, List<int>> minutes;
  final List<String> labels;
  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
            height: 92,
            width: double.infinity,
            child: CustomPaint(painter: _TrainingChartPainter(minutes))),
        const SizedBox(height: 5),
        _ChartLabels(labels),
      ]);
}

class _TrainingChartPainter extends CustomPainter {
  const _TrainingChartPainter(this.minutes);
  final Map<String, List<int>> minutes;
  @override
  void paint(Canvas canvas, Size size) {
    final count = minutes.values.first.length;
    final totals = List.generate(
        count,
        (i) =>
            trainingTypes.fold<int>(0, (sum, type) => sum + minutes[type]![i]));
    final maxMinutes = math.max(1, totals.reduce(math.max));
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = 4 + i * (size.height - 8) / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final slot = size.width / count;
    final width = math.min(18.0, slot * .58);
    for (var i = 0; i < count; i++) {
      var bottom = size.height - 5;
      for (final type in trainingTypes) {
        final value = minutes[type]![i];
        if (value == 0) continue;
        final height = value / maxMinutes * (size.height - 10);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH((i + .5) * slot - width / 2, bottom - height,
                    width, height),
                const Radius.circular(2)),
            Paint()..color = _trainingColor(type));
        bottom -= height;
      }
    }
  }

  @override
  bool shouldRepaint(_TrainingChartPainter old) => old.minutes != minutes;
}

Color _trainingColor(String type) => switch (type) {
      'Sparring' => AppColors.red,
      'Boxing / Technical' => AppColors.teal,
      'Conditioning' => AppColors.amber,
      _ => const Color(0xff7d8edb),
    };

String _shortDay(String date) {
  final day = DateTime.tryParse(date);
  return day == null ? date : '${day.day}/${day.month}/${day.year}';
}

String _windowLabel(TrendWindow window) {
  final last = window.end.subtract(const Duration(days: 1));
  return switch (window.period) {
    TrendPeriod.day => _shortDay(window.start.toIso8601String()),
    TrendPeriod.week =>
      '${window.start.day}/${window.start.month} – ${last.day}/${last.month}/${last.year}',
    TrendPeriod.month => '${[
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
      ][window.start.month - 1]} ${window.start.year}',
    TrendPeriod.year => '${window.start.year}',
  };
}
