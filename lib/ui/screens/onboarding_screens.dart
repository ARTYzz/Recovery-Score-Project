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
        const SizedBox(height: 15),
        Center(
            child: TextButton(
                onPressed: () async {
                  try {
                    await widget.controller.tryDemo();
                  } catch (e) {
                    widget.controller.showError(e);
                  }
                },
                child: const Text('Try synthetic demo'))),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('HEALTH DATA · STEP 2'),
      const SizedBox(height: 10),
      Text('Your data is ready.',
          style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      const Text(
          'The prototype loads clearly labelled health demo data automatically. The full mobile app will request device permission before reading real data.',
          style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 20),
      AppCard(
          color: const Color(0xfff3fbd9),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DEMO HEALTH DATA CONNECTED',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6)),
            const SizedBox(height: 7),
            Text(
                sleep?.sleepMinutes == null
                    ? 'Sleep unavailable'
                    : 'Sleep ${sleep!.sleepMinutes! ~/ 60} h ${sleep.sleepMinutes! % 60} min',
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const Text('HRV · Resting HR · Workout',
                style: TextStyle(color: AppColors.muted))
          ])),
      const SizedBox(height: 16),
      const FieldTitle('Ready in this prototype'),
      _sourceCard(Icons.favorite_outline, 'Apple Health',
          'Demo connected automatically · no Apple account linked'),
      const SizedBox(height: 9),
      _sourceCard(Icons.monitor_heart_outlined, 'Health Connect',
          'Demo connected automatically · no Android permission granted'),
      const SizedBox(height: 18),
      const FieldTitle('Real-device connection in the full app'),
      _sourceCard(Icons.watch_outlined, 'Smartwatch',
          'Connect through the phone’s health platform after permission'),
      const SizedBox(height: 9),
      _sourceCard(Icons.scale_outlined, 'Smart scale',
          'Device connection planned · enter morning weight manually now'),
      const SizedBox(height: 16),
      const Text('No real watch or scale data is being read in this prototype.',
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
          'Apple Health and Health Connect demo sources are ready automatically. No real health account is connected.',
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
