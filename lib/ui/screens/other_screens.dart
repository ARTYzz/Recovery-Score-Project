import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Text;
import '../app_text.dart';
import '../../app/boxer_controller.dart';
import '../../data/athlete_backup.dart';
import '../../domain/athlete_data.dart';
import '../../domain/health_source.dart';
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
    final last = weights.isEmpty ? data.currentWeight : weights.last.weight;
    final recentAssessments =
        data.assessments.reversed.take(7).toList().reversed.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Camp', style: Theme.of(context).textTheme.headlineLarge),
          Text(
              '${CampClock.formatted(data.profile?.fightDate)} · ${data.profile?.targetWeight == null ? 'No target weight set' : 'Target ${data.profile!.targetWeight!.toStringAsFixed(1)} kg'}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13))
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
            child: Text(
                camp.daysOut == null
                    ? 'No fight set'
                    : '${camp.daysOut} days out',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)))
      ]),
      const SizedBox(height: 25),
      if (camp.daysOut == null) ...[
        AppCard(
            color: const Color(0xfff3fbd9),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('No upcoming fight scheduled',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              const Text(
                  'Recovery tracking continues. Add a fight date when your next bout is confirmed.',
                  style: TextStyle(color: AppColors.muted)),
              if (data.profile?.pastFightPlans.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                    'Last scheduled date: ${CampClock.formatted(data.profile!.pastFightPlans.last.date)}',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
              const SizedBox(height: 10),
              TextButton.icon(
                  onPressed: () => widget.controller.navigate('edit-profile'),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Set next fight date')),
            ])),
      ] else ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final phase in ['BASE', 'BUILD', 'PEAK', 'TAPER'])
            Text(phase,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color:
                        phase == camp.phase ? AppColors.ink : AppColors.muted))
        ]),
        const SizedBox(height: 6),
        Row(children: [
          for (final phase in ['BASE', 'BUILD', 'PEAK', 'TAPER'])
            Expanded(
                child: Container(
                    height: 9,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                        color: phase == camp.phase
                            ? AppColors.lime
                            : AppColors.line,
                        borderRadius: BorderRadius.circular(3))))
        ]),
        const SizedBox(height: 12),
        Text(
            'Current phase: ${camp.phase.replaceAll('_', ' ')}. Recovery guidance uses the data available today.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      ],
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
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(camp.daysOut == null ? 'first log' : 'camp start',
              style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          const Text('today',
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

class LanguageSelector extends StatelessWidget {
  const LanguageSelector(this.controller, {super.key});
  final BoxerController controller;

  @override
  Widget build(BuildContext context) => AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Language'),
        const SizedBox(height: 8),
        const Text('Choose the language used in the app.',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 12),
        SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'th', label: Text('ไทย')),
            ],
            selected: {
              controller.languageCode
            },
            onSelectionChanged: (selection) =>
                controller.setLanguage(selection.first)),
      ]));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen(this.controller, {super.key});
  final BoxerController controller;

  Future<String?> _backupPassphrase(BuildContext context,
      {required String title}) async {
    var entered = '';
    return showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: Text(title),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'Use at least 8 characters. Keep this passphrase: the backup cannot be opened without it.'),
                const SizedBox(height: 12),
                TextField(
                    onChanged: (value) => entered = value,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: AppCopy.of(context, 'Backup passphrase')))
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(dialog, entered),
                    child: const Text('Continue'))
              ],
            ));
  }

  void _message(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _export(BuildContext context) async {
    final passphrase =
        await _backupPassphrase(context, title: 'Create encrypted backup');
    if (passphrase == null || !context.mounted) return;
    try {
      final bytes = await controller.exportBackup(passphrase);
      final day = DateTime.now().toIso8601String().substring(0, 10);
      final location = await FilePicker.saveFile(
          fileName: 'boxer-recovery-$day.brbackup',
          bytes: bytes,
          mimeType: 'application/octet-stream',
          dialogTitle: 'Save encrypted backup');
      if (!context.mounted) return;
      if (location != null) {
        _message(context,
            'Encrypted backup saved. Keep the file and passphrase safe.');
      }
    } catch (_) {
      if (!context.mounted) return;
      _message(context,
          'Backup could not be saved. Check the passphrase and try again.');
    }
  }

  Future<void> _restore(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(
          type: FileType.custom, allowedExtensions: ['brbackup']);
      if (file == null || !context.mounted) return;
      if ((file.lengthSync() ?? 0) > AthleteBackup.maxBytes) {
        throw const FormatException('Backup file is too large.');
      }
      final passphrase =
          await _backupPassphrase(context, title: 'Open encrypted backup');
      if (passphrase == null || !context.mounted) return;
      final restored =
          await controller.decodeBackup(await file.readAsBytes(), passphrase);
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                title: const Text('Replace local data?'),
                content: Text(
                    'Restore ${restored.profile?.name ?? 'athlete'} with ${restored.checkins.length} check-ins and ${restored.sessions.length} training logs? This replaces the current local account. Health permissions must be connected again on this device.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Restore'))
                ],
              ));
      if (confirmed != true) return;
      await controller.restoreBackup(restored);
      if (!context.mounted) return;
      _message(context, 'Backup restored. Review your health connection.');
    } catch (_) {
      if (!context.mounted) return;
      _message(context,
          'Restore failed. Check the backup file and passphrase. Current data was kept.');
    }
  }

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
        Text('Fight: ${CampClock.formatted(data.profile?.fightDate)}'),
        Text(
            'Current weight: ${data.currentWeight == null ? 'Unavailable' : '${data.currentWeight!.toStringAsFixed(1)} kg'}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        Text(
            'Height: ${data.profile?.heightCm == null ? 'Unavailable' : '${data.profile!.heightCm!.toStringAsFixed(1)} cm'} · Target: ${data.profile?.targetWeight == null ? 'Not set' : '${data.profile!.targetWeight!.toStringAsFixed(1)} kg'}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 8),
        TextButton.icon(
            onPressed: () => controller.navigate('edit-profile'),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Edit profile'))
      ])),
      const SizedBox(height: 15),
      LanguageSelector(controller),
      const SizedBox(height: 15),
      AppCard(
          child: Column(children: [
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.watch_outlined),
            title: const Text('Connected sources'),
            subtitle: Text(data.connections['apple'] == 'CONNECTED'
                ? '${data.activeHealthSourceLabel ?? 'Apple Health'} · live data'
                : 'Health data sources and permissions'),
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
                'Privacy: ${data.privacyAcceptedAt == null ? 'Not accepted' : 'Accepted'} · Health: ${data.connections['apple'] == 'CONNECTED' ? 'Apple Health live' : 'Not connected'}'))
      ])),
      const SizedBox(height: 15),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Data backup'),
        const SizedBox(height: 7),
        const Text(
            'Backups are encrypted files you save yourself. Nothing is uploaded by the app.',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 8),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export encrypted backup'),
            onTap: () => _export(context)),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Restore from backup'),
            onTap: () => _restore(context)),
      ])),
      const SizedBox(height: 15),
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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen(this.controller, {super.key});
  final BoxerController controller;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final name = TextEditingController();
  final currentWeight = TextEditingController();
  final heightCm = TextEditingController();
  final targetWeight = TextEditingController();
  DateTime? fightDate;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.data!.profile!;
    name.text = profile.name;
    currentWeight.text = profile.currentWeight?.toString() ??
        widget.controller.data!.latestCheckIn?.weight?.toString() ??
        '';
    heightCm.text = profile.heightCm?.toString() ?? '';
    targetWeight.text = profile.targetWeight?.toString() ?? '';
    fightDate = parsedDay(profile.fightDate);
  }

  @override
  void dispose() {
    name.dispose();
    currentWeight.dispose();
    heightCm.dispose();
    targetWeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
              title: 'Edit Profile',
              onBack: () => widget.controller.navigate('settings')),
          const SizedBox(height: 20),
          const FieldTitle('Display name'),
          TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration:
                  InputDecoration(hintText: AppCopy.of(context, 'Your name'))),
          const SizedBox(height: 20),
          const FieldTitle('Next fight date',
              helper: 'Optional. Set it when your next fight is confirmed.'),
          OutlinedButton.icon(
              onPressed: () async {
                final tomorrow = DateTime.now().add(const Duration(days: 1));
                final selected = await showDatePicker(
                    context: context,
                    initialDate:
                        fightDate != null && fightDate!.isAfter(DateTime.now())
                            ? fightDate!
                            : tomorrow,
                    firstDate: tomorrow,
                    lastDate: DateTime.now().add(const Duration(days: 730)));
                if (selected != null) setState(() => fightDate = selected);
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(fightDate == null
                  ? 'No fight scheduled · Choose date'
                  : CampClock.formatted(localDay(fightDate)))),
          if (fightDate != null)
            TextButton(
                onPressed: () => setState(() {
                      fightDate = null;
                      targetWeight.clear();
                    }),
                child: const Text('Remove scheduled fight')),
          const SizedBox(height: 20),
          ProfileMeasurementsFields(
              currentWeight: currentWeight,
              heightCm: heightCm,
              targetWeight: targetWeight),
          const SizedBox(height: 20),
          PrimaryButton('Save profile', onPressed: () async {
            try {
              await widget.controller.updateProfile(AthleteProfile(
                  name: name.text.trim(),
                  fightDate: fightDate == null ? null : localDay(fightDate),
                  currentWeight: profileMeasurement(
                      currentWeight.text, 'current weight in kg'),
                  heightCm: profileMeasurement(heightCm.text, 'height in cm'),
                  targetWeight: profileMeasurement(
                      targetWeight.text, 'target weight in kg')));
            } catch (e) {
              widget.controller.showError(e);
            }
          }),
        ],
      );
}

class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    final data = controller.data!;
    final lastHealthRead = controller.appleHealth.lastReadSummary;
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final imported = data.wearables
        .where((sample) => HealthSource.isImported(sample.source))
        .toList();
    final sourceKeys = imported.map((sample) => sample.source).toSet().toList();
    String sourceLabel(String source) {
      final sample = imported.lastWhere((sample) => sample.source == source);
      return HealthSource.label(source,
          name: sample.sourceName, id: sample.sourceId);
    }

    sourceKeys.sort((a, b) => sourceLabel(a).compareTo(sourceLabel(b)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
          title: 'Connected Sources',
          onBack: () => controller.navigate('settings')),
      const SizedBox(height: 12),
      Text(
          controller.appleHealth.supported
              ? 'Sources with readable records in Apple Health appear here automatically. Select one source for recovery scoring and trends. A source may be an app or a device.'
              : 'Live Apple Health reading requires an iPhone. No wearable data is simulated on this device.',
          style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 18),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Apple Health',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 6),
        Text(
            data.connections['apple'] == 'CONNECTED'
                ? '${controller.appleHealth.lastReadSummary?.importedRecords == 0 ? 'Saved history' : 'Imported'} · ${imported.length} source-day records. Missing metrics stay Unavailable.'
                : 'Not connected · Apple Health permission and readable records required.',
            style: const TextStyle(color: AppColors.muted)),
        if (data.connections['apple'] == 'CONNECTED') ...[
          const SizedBox(height: 12),
          const Text('Source used for recovery assessment',
              style: TextStyle(fontWeight: FontWeight.w700)),
          for (final source in sourceKeys)
            ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(data.activeHealthSource == source
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                title: Text(sourceLabel(source)),
                subtitle: Text(
                    '${imported.where((sample) => sample.source == source).length} day(s) imported · ${controller.appleHealth.lastReadSummary?.countFor(source) ?? 0} record(s) in last read\nSource ID: ${imported.lastWhere((sample) => sample.source == source).sourceId ?? 'Not provided'}'),
                onTap: () => controller.selectHealthSource(source)),
        ],
        if (lastHealthRead != null) ...[
          const SizedBox(height: 8),
          Text(
              'Last HealthKit read ${twoDigits(lastHealthRead.checkedAt.day)}/${twoDigits(lastHealthRead.checkedAt.month)} ${twoDigits(lastHealthRead.checkedAt.hour)}:${twoDigits(lastHealthRead.checkedAt.minute)} · ${lastHealthRead.returnedRecords} records in 14 days',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              'Readable source-days: Sleep ${lastHealthRead.sleepDays} · HRV ${lastHealthRead.hrvDays} · Resting HR ${lastHealthRead.restingHrDays} · Heart Rate ${lastHealthRead.heartRateDays}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          if (lastHealthRead.sleepDays == 0 &&
              lastHealthRead.hrvDays == 0 &&
              lastHealthRead.restingHrDays == 0 &&
              lastHealthRead.heartRateDays == 0)
            const Text(
                'This read has no values for the Today health cards. Check the corresponding categories in Apple Health and their Data Sources & Access.',
                style: TextStyle(color: AppColors.amber, fontSize: 12)),
          if (lastHealthRead.sleepDays == 0 && lastHealthRead.inBedRecords > 0)
            const Text(
                'HealthKit returned time in bed, but no asleep-time samples. Time in bed is not shown as sleep.',
                style: TextStyle(color: AppColors.amber, fontSize: 12)),
          if (lastHealthRead.failedTypes.isNotEmpty)
            Text(
                'Some HealthKit categories could not be read: ${lastHealthRead.failedTypes.map((type) => type.name).join(', ')}',
                style: const TextStyle(color: AppColors.amber, fontSize: 12)),
          if (lastHealthRead.importedRecords == 0)
            const Text(
                'Last sync returned no records with an identifiable source. Saved history is unchanged; check Apple Health data and read access.',
                style: TextStyle(color: AppColors.amber, fontSize: 12)),
          Text(lastHealthRead.hrvExplanation(data.activeHealthSource),
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
        const SizedBox(height: 8),
        if (controller.appleHealth.supported &&
            data.connections['apple'] == 'CONNECTED') ...[
          TextButton(
              onPressed: controller.busy ? null : controller.syncAppleHealth,
              child: const Text('Sync now')),
          TextButton(
              onPressed:
                  controller.busy ? null : controller.disconnectAppleHealth,
              child: const Text('Disconnect and clear imported data')),
        ] else if (controller.appleHealth.supported)
          TextButton(
              onPressed: controller.busy ? null : controller.connectAppleHealth,
              child: const Text('Connect Apple Health')),
      ])),
      const SizedBox(height: 10),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('FightCamp',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        Text(
            data.connections['fightcamp'] == 'MOCK_CONNECTED'
                ? 'Mock source · synthetic punch data only'
                : 'Not loaded yet',
            style: const TextStyle(color: AppColors.muted)),
      ])),
      const SizedBox(height: 10),
      const Text(
          'To revoke Apple Health read permission, use the iPhone Health app. Disconnect here clears locally imported records.',
          style: TextStyle(color: AppColors.muted, fontSize: 12)),
    ]);
  }
}
