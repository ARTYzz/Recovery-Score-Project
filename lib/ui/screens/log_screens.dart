import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/boxer_controller.dart';
import '../../domain/athlete_data.dart';
import '../../domain/food_journal.dart';
import '../components.dart';
import '../design.dart';

class MorningScreen extends StatefulWidget {
  const MorningScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  State<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends State<MorningScreen> {
  double? weight;
  int urine = 2;
  String mood = 'OK';
  bool symptoms = false;
  @override
  void initState() {
    super.initState();
    weight = widget.controller.data?.latestCheckIn?.weight;
  }

  Future<void> _chooseWeight() async {
    var kilograms = weight?.floor() ?? 70;
    var tenth =
        weight == null ? 0 : ((weight! - kilograms) * 10).round().clamp(0, 9);
    await showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
            child: SizedBox(
                height: 290,
                child: Column(children: [
                  const SizedBox(height: 14),
                  const Text('Morning weight (kg)',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Expanded(
                      child: Row(children: [
                    Expanded(
                        child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                                initialItem: kilograms - 30),
                            itemExtent: 36,
                            onSelectedItemChanged: (index) =>
                                kilograms = index + 30,
                            children: [
                          for (var kg = 30; kg <= 200; kg++)
                            Center(child: Text('$kg'))
                        ])),
                    const Text('.',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    Expanded(
                        child: CupertinoPicker(
                            scrollController:
                                FixedExtentScrollController(initialItem: tenth),
                            itemExtent: 36,
                            onSelectedItemChanged: (index) => tenth = index,
                            children: [
                          for (var digit = 0; digit < 10; digit++)
                            Center(child: Text('$digit'))
                        ])),
                    const Padding(
                        padding: EdgeInsets.only(right: 22), child: Text('kg')),
                  ])),
                  TextButton(
                      onPressed: () {
                        setState(() => weight = kilograms + tenth / 10);
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Use this weight')),
                ]))));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data;
    final sleep = data?.latestSleepSample;
    final hrv = data?.latestMetricSample((sample) => sample.hrv);
    final restingHr = data?.latestMetricSample((sample) => sample.restingHr);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader(title: 'Morning Check-in', subtitle: 'About 20 seconds'),
      const SizedBox(height: 22),
      const FieldTitle('Watch data'),
      AppCard(
          child: Column(children: [
        StatusPill('Sleep',
            sleep?.sleepMinutes == null ? 'INSUFFICIENT_DATA' : 'READY'),
        const SizedBox(height: 8),
        Text(
            sleep?.sleepMinutes == null
                ? 'Unavailable'
                : '${sleep!.sleepMinutes! ~/ 60} h ${sleep.sleepMinutes! % 60} min',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('HRV: ${hrv?.hrv?.round().toString() ?? 'Unavailable'}'),
          Text(
              'Resting HR: ${restingHr?.restingHr?.round().toString() ?? 'Unavailable'}')
        ])
      ])),
      const SizedBox(height: 24),
      const FieldTitle('Morning weight'),
      AppCard(
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
            onPressed: () => weight == null
                ? _chooseWeight()
                : setState(() => weight = (weight! - .1).clamp(30, 200)),
            icon: const Icon(Icons.remove_circle_outline)),
        TextButton(
            onPressed: _chooseWeight,
            child: Text(
                weight == null
                    ? 'Set weight'
                    : '${weight!.toStringAsFixed(1)} kg',
                style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink))),
        IconButton(
            onPressed: () => weight == null
                ? _chooseWeight()
                : setState(() => weight = (weight! + .1).clamp(30, 200)),
            icon: const Icon(Icons.add_circle_outline))
      ])),
      const SizedBox(height: 24),
      const FieldTitle('Urine colour'),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var i = 1; i <= 5; i++)
          InkWell(
            onTap: () => setState(() => urine = i),
            child: Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                  color: [
                    const Color(0xfffff3a0),
                    const Color(0xfff6d95d),
                    const Color(0xffe9bb42),
                    const Color(0xffce9631),
                    const Color(0xffab702c)
                  ][i - 1],
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: urine == i ? AppColors.ink : Colors.white,
                      width: urine == i ? 3 : 1)),
              child: Center(
                  child: Text('$i',
                      style: const TextStyle(fontWeight: FontWeight.w800))),
            ),
          ),
      ]),
      const SizedBox(height: 24),
      const FieldTitle('How do you feel?'),
      ChoiceGroup(
          options: const ['Good', 'OK', 'Flat', 'Low'],
          value: mood,
          onChanged: (v) => setState(() => mood = v)),
      const SizedBox(height: 20),
      SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: symptoms,
          onChanged: (v) => setState(() => symptoms = v),
          title: const Text('New symptoms after head contact?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
      const SizedBox(height: 25),
      PrimaryButton('Save check-in', onPressed: () async {
        try {
          await widget.controller.saveMorning(MorningCheckIn(
              date: widget.controller.data!.currentDay,
              weight: weight,
              urine: urine,
              mood: mood,
              headSymptoms: symptoms));
        } catch (e) {
          widget.controller.showError(e);
        }
      }),
    ]);
  }
}

class TrainingScreen extends StatefulWidget {
  const TrainingScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  String type = 'Sparring';
  String intensity = 'Moderate';
  String contact = 'Light';
  int rounds = 4;
  int duration = 30;
  final soreness = <String>{};
  String painSeverity = 'Sore';

  void _toggleSoreness(String area) => setState(() {
        if (!soreness.add(area)) soreness.remove(area);
      });
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(
            title: 'After Training',
            subtitle: 'Log this session in about 30 seconds',
            onBack: () => widget.controller.navigate('today')),
        const SizedBox(height: 22),
        const FieldTitle('Training type'),
        ChoiceGroup(options: const [
          'Sparring',
          'Boxing / Technical',
          'Conditioning',
          'Strength'
        ], value: type, onChanged: (v) => setState(() => type = v)),
        const SizedBox(height: 22),
        if (type == 'Sparring') ...[
          const FieldTitle('Rounds'),
          AppCard(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                IconButton(
                    onPressed: () =>
                        setState(() => rounds = (rounds - 1).clamp(1, 20)),
                    icon: const Icon(Icons.remove_circle_outline)),
                Text('$rounds rounds',
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                IconButton(
                    onPressed: () =>
                        setState(() => rounds = (rounds + 1).clamp(1, 20)),
                    icon: const Icon(Icons.add_circle_outline))
              ])),
          const SizedBox(height: 18),
          const FieldTitle('Head contact'),
          ChoiceGroup(
              options: const ['None', 'Light', 'Moderate', 'Heavy'],
              value: contact,
              onChanged: (v) => setState(() => contact = v)),
          const SizedBox(height: 22)
        ] else ...[
          const FieldTitle('Duration'),
          ChoiceGroup(
              options: const [20, 30, 45, 60, 90],
              value: duration,
              onChanged: (v) => setState(() => duration = v)),
          const SizedBox(height: 22)
        ],
        const FieldTitle('Intensity'),
        ChoiceGroup(
            options: const ['Easy', 'Moderate', 'Hard'],
            value: intensity,
            onChanged: (v) => setState(() => intensity = v)),
        const SizedBox(height: 22),
        const FieldTitle('Soreness / pain'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final area in [
            'Head',
            'Neck',
            'Shoulders',
            'Arms',
            'Back',
            'Legs'
          ])
            Semantics(
                label: area,
                button: true,
                selected: soreness.contains(area),
                onTap: () => _toggleSoreness(area),
                child: ExcludeSemantics(
                    child: FilterChip(
                        label: Text(area),
                        selected: soreness.contains(area),
                        onSelected: (_) => _toggleSoreness(area))))
        ]),
        if (soreness.isNotEmpty) ...[
          const SizedBox(height: 18),
          const FieldTitle('How does it feel?'),
          ChoiceGroup(
              options: const ['Sore', 'Painful', 'Severe'],
              value: painSeverity,
              onChanged: (v) => setState(() => painSeverity = v)),
        ],
        const SizedBox(height: 28),
        PrimaryButton('Save training', onPressed: () async {
          try {
            await widget.controller.saveTraining(TrainingSession(
                date: widget.controller.data!.currentDay,
                type: type,
                duration: type == 'Sparring' ? rounds * 3 : duration,
                intensity: intensity,
                rounds: type == 'Sparring' ? rounds : 0,
                contact: contact,
                soreness: soreness.toList(),
                painSeverity: soreness.isEmpty ? 'None' : painSeverity));
          } catch (e) {
            widget.controller.showError(e);
          }
        }),
      ]);
}

class NutritionScreen extends StatefulWidget {
  const NutritionScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  String? meal;
  String? protein;
  String? carbs;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(
            title: 'Nutrition',
            subtitle: 'Quick check · 10–15 seconds',
            onBack: () => widget.controller.navigate('today')),
        const SizedBox(height: 22),
        const FieldTitle('Post-training meal?'),
        ChoiceGroup(
            options: const ['Yes', 'No'],
            value: meal,
            onChanged: (v) => setState(() => meal = v)),
        const SizedBox(height: 24),
        const FieldTitle('Protein completed?'),
        ChoiceGroup(
            options: const ['Yes', 'No'],
            value: protein,
            onChanged: (v) => setState(() => protein = v)),
        const SizedBox(height: 24),
        const FieldTitle('Carbs today'),
        ChoiceGroup(
            options: const ['Low', 'Medium', 'High'],
            value: carbs,
            onChanged: (v) => setState(() => carbs = v)),
        const SizedBox(height: 24),
        AppCard(
            color: const Color(0xfff1f8f4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Food photo journal',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const Text('Optional estimate. Confirm every entry yourself.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              TextButton(
                  onPressed: () => widget.controller.navigate('food-photo'),
                  child: const Text('Open food journal →'))
            ])),
        const SizedBox(height: 24),
        PrimaryButton('Save nutrition',
            onPressed: meal == null || protein == null || carbs == null
                ? null
                : () async {
                    try {
                      await widget.controller.saveNutrition(NutritionCheck(
                          date: widget.controller.data!.currentDay,
                          meal: meal!,
                          protein: protein!,
                          carbs: carbs!));
                    } catch (e) {
                      widget.controller.showError(e);
                    }
                  }),
      ]);
}

class FoodScreen extends StatefulWidget {
  const FoodScreen(this.controller, {super.key});
  final BoxerController controller;
  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  String? photo;
  String meal = 'Lunch';
  String foodKey = 'chickenRice';
  double portions = 1;
  final description = TextEditingController(text: 'Chicken, rice, greens');
  final kcal = TextEditingController(text: '640');
  final protein = TextEditingController(text: '52');
  final carbs = TextEditingController(text: '71');
  final fat = TextEditingController(text: '18');
  @override
  void dispose() {
    description.dispose();
    kcal.dispose();
    protein.dispose();
    carbs.dispose();
    fat.dispose();
    super.dispose();
  }

  void _applyEstimate() {
    final preset = FoodJournal.presets[foodKey]!;
    final estimate = FoodJournal().estimate(foodKey, portions);
    description.text = preset.name;
    kcal.text = estimate.kcal.toString();
    protein.text = estimate.protein.toString();
    carbs.text = estimate.carbs.toString();
    fat.text = estimate.fat.toString();
    setState(() {});
  }

  Future<void> pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
          source: source, maxWidth: 600, maxHeight: 600, imageQuality: 65);
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 1000000) {
          throw const FormatException('Please choose a smaller photo.');
        }
        setState(() => photo = base64Encode(bytes));
      }
    } catch (e) {
      widget.controller.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meals = widget.controller.data?.foodMeals
            .where((e) => e.date == widget.controller.data!.currentDay)
            .toList() ??
        [];
    final totals =
        FoodJournal().today(meals, widget.controller.data!.currentDay);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
          title: 'Food',
          subtitle: '${meals.length} meals logged',
          onBack: () => widget.controller.navigate('nutrition')),
      const SizedBox(height: 18),
      const FieldTitle('Snap your plate'),
      AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Column(children: [
            const Icon(Icons.camera_alt_outlined,
                color: AppColors.teal, size: 28),
            const SizedBox(height: 3),
            const Text('Add a food photo',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 1),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(
                  onPressed: () => pick(ImageSource.camera),
                  child: const Text('Camera')),
              TextButton(
                  onPressed: () => pick(ImageSource.gallery),
                  child: const Text('Gallery'))
            ]),
            if (photo != null) Image.memory(base64Decode(photo!), height: 140)
          ])),
      const SizedBox(height: 10),
      for (final item in meals) ...[
        AppCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${item.mealType} — ${item.time}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(item.description,
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          Text(
              '${item.kcal} kcal  ·  P ${item.protein}g  C ${item.carbs}g  F ${item.fat}g')
        ])),
        const SizedBox(height: 12)
      ],
      AppCard(
          color: const Color(0xfff1f8f4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionLabel('Today so far · user-confirmed estimates'),
            const SizedBox(height: 4),
            Text(meals.isEmpty ? 'No meals logged yet' : '${totals.kcal} kcal',
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            if (meals.isNotEmpty)
              Text(
                  'Protein ${totals.protein}g  ·  Carbs ${totals.carbs}g  ·  Fat ${totals.fat}g',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12))
          ])),
      const SizedBox(height: 11),
      const FieldTitle('Meal'),
      ChoiceGroup(
          options: const ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
          value: meal,
          onChanged: (v) => setState(() => meal = v)),
      const SizedBox(height: 10),
      const FieldTitle('Food and serving size'),
      Row(children: [
        Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
                key: ValueKey(foodKey),
                initialValue: foodKey,
                isExpanded: true,
                items: [
                  for (final entry in FoodJournal.presets.entries)
                    DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)))
                ],
                onChanged: (value) {
                  if (value != null) {
                    foodKey = value;
                    _applyEstimate();
                  }
                })),
        const SizedBox(width: 8),
        Expanded(
            flex: 2,
            child: DropdownButtonFormField<double>(
                key: ValueKey(portions),
                initialValue: portions,
                items: [
                  for (final amount in [.5, 1.0, 1.5, 2.0, 3.0, 4.0])
                    DropdownMenuItem(value: amount, child: Text('$amount×'))
                ],
                onChanged: (value) {
                  if (value != null) {
                    portions = value;
                    _applyEstimate();
                  }
                }))
      ]),
      if (foodKey == 'other') ...[
        const SizedBox(height: 12),
        TextField(
            controller: description,
            decoration: const InputDecoration(labelText: 'Description')),
      ],
      const SizedBox(height: 12),
      Row(children: [
        for (final field in [
          ('kcal', kcal),
          ('Protein', protein),
          ('Carbs', carbs),
          ('Fat', fat)
        ])
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextField(
                      controller: field.$2,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: field.$1,
                          contentPadding: const EdgeInsets.all(8)))))
      ]),
      const SizedBox(height: 12),
      const Text(
          'Preset estimate × servings. A photo is not analyzed automatically. Review and correct every number before saving.',
          style: TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 12),
      PrimaryButton('Save meal', onPressed: () async {
        try {
          final now = DateTime.now();
          int amount(TextEditingController field) {
            final value = int.tryParse(field.text);
            if (value == null || value < 0 || value > 5000) {
              throw const FormatException(
                  'Enter valid nutrient estimates before saving.');
            }
            return value;
          }

          await widget.controller.saveFoodMeal(FoodMeal(
              id: widget.controller.newMealId(),
              date: widget.controller.data!.currentDay,
              time:
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              mealType: meal,
              description: description.text.trim().isEmpty
                  ? FoodJournal.presets[foodKey]!.name
                  : description.text.trim(),
              foodKey: foodKey,
              portions: portions,
              kcal: amount(kcal),
              protein: amount(protein),
              carbs: amount(carbs),
              fat: amount(fat),
              photoBase64: photo));
          setState(() => photo = null);
        } catch (e) {
          widget.controller.showError(e);
        }
      }),
    ]);
  }
}
