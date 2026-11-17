import 'package:flutter/material.dart' hide Text;

import 'app_text.dart';
import 'components.dart';
import 'design.dart';

/// One continuous surface for the three quick nutrition answers.
class NutritionCheckForm extends StatelessWidget {
  const NutritionCheckForm({
    super.key,
    required this.meal,
    required this.protein,
    required this.carbs,
    required this.onMeal,
    required this.onProtein,
    required this.onCarbs,
  });

  final String? meal;
  final String? protein;
  final String? carbs;
  final ValueChanged<String> onMeal;
  final ValueChanged<String> onProtein;
  final ValueChanged<String> onCarbs;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _BinaryQuestion(
            icon: Icons.restaurant_outlined,
            title: 'Post-training meal?',
            hint: 'Did you eat after your session?',
            value: meal,
            onChanged: onMeal,
          ),
          const Divider(height: 1, color: AppColors.line),
          _BinaryQuestion(
            icon: Icons.egg_alt_outlined,
            title: 'Protein completed?',
            hint: 'Did you meet your usual plan?',
            value: protein,
            onChanged: onProtein,
          ),
          const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _QuestionHeading(
                  icon: Icons.grain_outlined,
                  title: 'Carbs today',
                  hint: 'Choose what best fits today'),
              const SizedBox(height: 23),
              _CarbScale(value: carbs, onChanged: onCarbs),
            ]),
          ),
        ]),
      );
}

class _QuestionHeading extends StatelessWidget {
  const _QuestionHeading(
      {required this.icon, required this.title, required this.hint});

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
              color: AppColors.background, shape: BoxShape.circle),
          child: Icon(icon, size: 19, color: AppColors.teal),
        ),
        const SizedBox(width: 11),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text(hint,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      ]);
}

class _BinaryQuestion extends StatelessWidget {
  const _BinaryQuestion({
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String hint;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _QuestionHeading(icon: icon, title: title, hint: hint),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 49),
            child: Row(children: [
              _answer('Yes'),
              const SizedBox(width: 28),
              _answer('No'),
            ]),
          ),
        ]),
      );

  Widget _answer(String option) {
    final selected = value == option;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => onChanged(option),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.teal : AppColors.muted,
                size: 22),
            const SizedBox(width: 7),
            Text(option,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.ink : AppColors.muted)),
          ]),
        ),
      ),
    );
  }
}

class _CarbScale extends StatelessWidget {
  const _CarbScale({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned(
          left: 45,
          right: 45,
          top: 17,
          child: Divider(color: AppColors.line, thickness: 3, height: 3),
        ),
        Row(children: [
          for (final option in const ['Low', 'Medium', 'High'])
            Expanded(
              child: Semantics(
                selected: value == option,
                button: true,
                child: InkWell(
                  onTap: () => onChanged(option),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(children: [
                    SizedBox(
                      height: 37,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: value == option ? 28 : 18,
                          height: value == option ? 28 : 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                value == option ? AppColors.lime : Colors.white,
                            border: Border.all(
                                color: value == option
                                    ? AppColors.lime
                                    : AppColors.teal,
                                width: 2),
                          ),
                          child: value == option
                              ? const Icon(Icons.check,
                                  size: 17, color: AppColors.ink)
                              : null,
                        ),
                      ),
                    ),
                    Text(option,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: value == option
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: value == option
                                ? AppColors.ink
                                : AppColors.muted)),
                  ]),
                ),
              ),
            ),
        ]),
      ]);
}
