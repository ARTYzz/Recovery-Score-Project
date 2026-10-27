import 'package:flutter/material.dart';
import '../../app/boxer_controller.dart';
import '../../domain/recovery_engine.dart';
import '../components.dart';
import '../design.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final name = TextEditingController();
  final pass = TextEditingController();
  final weight = TextEditingController();
  DateTime? fightDate;
  bool accepted = false;
  @override
  void dispose() {
    name.dispose();
    pass.dispose();
    weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 10),
        const SectionLabel('BOXER RECOVERY'),
        const SizedBox(height: 8),
        Text('Own your recovery.',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text(
            'Set up your athlete profile to begin learning your baseline.',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 24),
        const FieldTitle('Display name'),
        TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Your name')),
        const SizedBox(height: 20),
        const FieldTitle('Next fight date'),
        OutlinedButton.icon(
            onPressed: () async {
              final result = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 42)),
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 730)));
              if (result != null) setState(() => fightDate = result);
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(fightDate == null
                ? 'Choose date'
                : CampClock.formatted(fightDate!.toIso8601String()))),
        const SizedBox(height: 20),
        const FieldTitle('Official weigh-in weight (kg)',
            helper:
                'Optional. Used only for weight trend and safety monitoring.'),
        TextField(
            controller: weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Optional')),
        const SizedBox(height: 20),
        const FieldTitle('Local passphrase'),
        TextField(
            controller: pass,
            obscureText: true,
            decoration:
                const InputDecoration(hintText: 'At least 8 characters')),
        const SizedBox(height: 12),
        CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: accepted,
            onChanged: (value) => setState(() => accepted = value == true),
            title: const Text('I accept the Privacy Notice',
                style: TextStyle(fontSize: 14)),
            controlAffinity: ListTileControlAffinity.leading),
        const SizedBox(height: 20),
        PrimaryButton('Create profile', onPressed: () async {
          try {
            await widget.controller.createProfile(
                name: name.text,
                fightDate: fightDate == null
                    ? ''
                    : '${fightDate!.year}-${fightDate!.month.toString().padLeft(2, '0')}-${fightDate!.day.toString().padLeft(2, '0')}',
                passphrase: pass.text,
                privacyAccepted: accepted,
                officialWeight: double.tryParse(weight.text));
          } catch (e) {
            widget.controller.showError(e);
          }
        }),
      ]);
}

class UnlockScreen extends StatefulWidget {
  const UnlockScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final pass = TextEditingController();
  @override
  void dispose() {
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 110),
        const SectionLabel('WELCOME BACK'),
        const SizedBox(height: 10),
        Text('Boxer Recovery',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        const Text('Unlock your locally encrypted athlete data.',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 28),
        TextField(
            controller: pass,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Local passphrase')),
        const SizedBox(height: 20),
        PrimaryButton('Unlock', onPressed: () async {
          try {
            await widget.controller.unlock(pass.text);
          } catch (e) {
            widget.controller.showError(e);
          }
        })
      ]);
}

class HealthPreviewScreen extends StatelessWidget {
  const HealthPreviewScreen(this.controller, {super.key});
  final BoxerController controller;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    final sleep = data?.latestSleepSample;
    final hrv = data?.latestMetricSample((sample) => sample.hrv);
    final restingHr = data?.latestMetricSample((sample) => sample.restingHr);
    final connected = data?.connections['apple'] == 'CONNECTED';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('HEALTH DATA · STEP 2'),
      const SizedBox(height: 10),
      Text('Connect health data.',
          style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      const Text(
          'On iPhone, allow read-only Apple Health access to import records shared by Huawei Health. Missing metrics stay Unavailable.',
          style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 20),
      AppCard(
          color: const Color(0xfff3fbd9),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                connected
                    ? 'HUAWEI VIA APPLE HEALTH · LIVE'
                    : 'NO HEALTH DATA CONNECTED',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6)),
            const SizedBox(height: 7),
            Text(
                sleep?.sleepMinutes == null
                    ? 'Sleep Unavailable'
                    : 'Sleep ${sleep!.sleepMinutes! ~/ 60} h ${sleep.sleepMinutes! % 60} min',
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            Text(
                'HRV ${hrv?.hrv?.round() ?? 'Unavailable'} · Resting HR ${restingHr?.restingHr?.round() ?? 'Unavailable'}',
                style: const TextStyle(color: AppColors.muted))
          ])),
      const SizedBox(height: 16),
      const FieldTitle('Sources'),
      _sourceCard(
          Icons.favorite_outline,
          'Apple Health',
          connected
              ? 'Huawei records imported from this iPhone'
              : 'Not connected · available on iPhone'),
      const SizedBox(height: 9),
      _sourceCard(Icons.sports_mma_outlined, 'FightCamp',
          'Synthetic punch history for this prototype only'),
      const SizedBox(height: 16),
      if (controller.huaweiHealth.supported && !connected) ...[
        PrimaryButton('Connect Apple Health',
            onPressed: controller.connectHuaweiHealth),
        const SizedBox(height: 12),
      ],
      if (!controller.huaweiHealth.supported)
        const Text(
            'Live Apple Health reading requires an iPhone. You can continue with unavailable metrics.',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
      const SizedBox(height: 26),
      PrimaryButton('Continue',
          onPressed: () async => controller.continueFromHealthPreview()),
    ]);
  }

  Widget _sourceCard(IconData icon, String title, String detail) => AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(children: [
        Icon(icon, color: AppColors.ink),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(detail,
              style: const TextStyle(color: AppColors.muted, fontSize: 12))
        ]))
      ]));
}

class BaselineIntroScreen extends StatelessWidget {
  const BaselineIntroScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    final camp = CampClock.fromProfile(controller.data?.profile);
    final data = controller.data;
    final sleep = data?.latestSleepSample;
    final hrv = data?.latestMetricSample((sample) => sample.hrv);
    final restingHr = data?.latestMetricSample((sample) => sample.restingHr);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('YOU ARE READY'),
      const SizedBox(height: 10),
      Text('Your camp starts here.',
          style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 20),
      AppCard(
          color: const Color(0xfff3fbd9),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${camp.daysOut ?? '—'} days out',
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            Text(
                '${camp.phase.replaceAll('_', ' ')} · ${CampClock.formatted(controller.data?.profile?.fightDate)}',
                style: const TextStyle(color: AppColors.muted))
          ])),
      const SizedBox(height: 16),
      const AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Learning your baseline — Day 1 of 7',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        SizedBox(height: 8),
        Text(
            'Your personal baseline improves as data arrives. Missing metrics stay Unavailable.',
            style: TextStyle(color: AppColors.muted))
      ])),
      const SizedBox(height: 22),
      const FieldTitle('Automatically tracked'),
      Text(
          'Sleep ${sleep?.sleepMinutes == null ? 'Unavailable' : '${sleep!.sleepMinutes! ~/ 60} h ${sleep.sleepMinutes! % 60} min'}  ·  HRV ${hrv?.hrv?.round().toString() ?? 'Unavailable'} ms'),
      Text(
          'Resting HR ${restingHr?.restingHr?.round().toString() ?? 'Unavailable'} bpm'),
      const SizedBox(height: 8),
      const Text(
          'Apple Health values appear after you grant access and matching records are available. FightCamp punch data is a labelled prototype source.',
          style: TextStyle(color: AppColors.muted, fontSize: 12)),
      const SizedBox(height: 18),
      const FieldTitle('Manual inputs'),
      const Text(
          'Morning weight  ·  Urine colour  ·  Mood  ·  Boxing training details'),
      const SizedBox(height: 30),
      PrimaryButton('Start', onPressed: () async {
        try {
          await controller.start();
        } catch (e) {
          controller.showError(e);
        }
      }),
    ]);
  }
}
