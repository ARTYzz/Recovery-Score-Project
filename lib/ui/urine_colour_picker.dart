import 'package:flutter/material.dart' hide Text;

import '../domain/urine_colour.dart';
import 'app_text.dart';
import 'components.dart';
import 'design.dart';

class UrineColourOption {
  const UrineColourOption(this.colour, this.swatch, this.label, this.meaning);

  final UrineColour colour;
  final Color swatch;
  final String label;
  final String meaning;
}

const urineColourOptions = <UrineColourOption>[
  UrineColourOption(UrineColour.yellow, Color(0xfff5dc53), 'Yellow',
      'Usually within the normal range. A deeper yellow may mean you need more fluids.'),
  UrineColourOption(UrineColour.red, Color(0xffc43c42), 'Red',
      'Food or medicines can change urine red, but it may also be blood. If blood is possible, seek medical advice promptly.'),
  UrineColourOption(UrineColour.purple, Color(0xffb78fe4), 'Purple',
      'Uncommon. It can occur with a urinary catheter or other factors. Seek advice if unexplained or persistent.'),
  UrineColourOption(UrineColour.brown, Color(0xffaa622d), 'Brown',
      'Food, medicines, or concentrated urine can appear brown. Dark brown or possible blood should be checked promptly.'),
  UrineColourOption(UrineColour.cloudyGrey, Color(0xffd5d9db), 'Cloudy grey',
      'Cloudy or milky urine can have several causes. Seek advice if it persists or comes with other symptoms.'),
  UrineColourOption(UrineColour.orange, Color(0xffffa13e), 'Orange',
      'Vitamins, food, medicines, or concentrated urine can look orange. Seek advice if unexplained or persistent.'),
  UrineColourOption(UrineColour.tealGreen, Color(0xff31b7ae), 'Teal / green',
      'Food dyes or medicines can change urine blue-green. Seek advice if unexplained or persistent.'),
];

class UrineColourPicker extends StatelessWidget {
  const UrineColourPicker(
      {super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = urineColourOptions.firstWhere(
        (option) => option.colour.code == value,
        orElse: () => urineColourOptions.first);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: SectionLabel('Urine colour')),
        IconButton(
            tooltip: AppCopy.of(context, 'What do the urine colours mean?'),
            onPressed: () => _showGuide(context),
            icon: const Icon(Icons.help_outline_rounded, size: 22),
            color: AppColors.muted),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        for (final option in urineColourOptions)
          Expanded(
              child: Semantics(
                  button: true,
                  selected: value == option.colour.code,
                  label: AppCopy.of(context, option.label),
                  child: Tooltip(
                      message: AppCopy.of(context, option.label),
                      child: InkWell(
                          key: ValueKey('urine-${option.colour.name}'),
                          customBorder: const CircleBorder(),
                          onTap: () => onChanged(option.colour.code),
                          child: Center(
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      color: option.swatch,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: value == option.colour.code
                                              ? AppColors.ink
                                              : AppColors.line,
                                          width: value == option.colour.code
                                              ? 3
                                              : 1)),
                                  child: value == option.colour.code
                                      ? Icon(Icons.check_rounded,
                                          size: 22,
                                          color: option.colour ==
                                                      UrineColour.red ||
                                                  option.colour ==
                                                      UrineColour.brown
                                              ? Colors.white
                                              : AppColors.ink)
                                      : null))))))
      ]),
      const SizedBox(height: 10),
      Row(children: [
        const Text('Selected colour: ',
            style: TextStyle(color: AppColors.muted, fontSize: 13)),
        Text(selected.label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
    ]);
  }

  void _showGuide(BuildContext context) {
    showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              scrollable: true,
              title: const Text('Urine colour guide'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final option in urineColourOptions) ...[
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 3),
                                decoration: BoxDecoration(
                                    color: option.swatch,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.line))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(option.label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Text(option.meaning,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted)),
                                ]))
                          ]),
                      const SizedBox(height: 14),
                    ],
                    const Text(
                        'Colour alone cannot diagnose dehydration, infection, or another condition.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'))
              ],
            ));
  }
}
