import 'package:flutter/material.dart' hide Text;

import 'app_text.dart';
import 'anatomy_figure_painter.dart';
import 'components.dart';
import 'design.dart';

/// A tappable body map. Area names match TrainingSession.soreness.
class BodyPainMap extends StatefulWidget {
  const BodyPainMap(
      {super.key, required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  State<BodyPainMap> createState() => _BodyPainMapState();
}

class _BodyPainMapState extends State<BodyPainMap> {
  bool back = false;

  static const frontSpots = <_BodySpot>[
    _BodySpot('Head', 0.50, 0.08),
    _BodySpot('Neck', 0.50, 0.20),
    _BodySpot('Shoulders', 0.34, 0.28),
    _BodySpot('Arms', 0.25, 0.40),
    _BodySpot('Wrists', 0.19, 0.57),
    _BodySpot('Hands', 0.18, 0.65),
    _BodySpot('Hips', 0.50, 0.54),
    _BodySpot('Legs', 0.42, 0.74),
    _BodySpot('Calves', 0.58, 0.88),
  ];
  static const backSpots = <_BodySpot>[
    _BodySpot('Head', 0.50, 0.08),
    _BodySpot('Neck', 0.50, 0.20),
    _BodySpot('Shoulders', 0.66, 0.28),
    _BodySpot('Back', 0.50, 0.38),
    _BodySpot('Lower back', 0.43, 0.48),
    _BodySpot('Arms', 0.75, 0.40),
    _BodySpot('Wrists', 0.81, 0.57),
    _BodySpot('Hands', 0.82, 0.65),
    _BodySpot('Hips', 0.58, 0.54),
    _BodySpot('Legs', 0.58, 0.74),
    _BodySpot('Calves', 0.42, 0.88),
  ];

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.accessibility_new_outlined,
                size: 21, color: AppColors.ink),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Where do you feel it?',
                    style: Theme.of(context).textTheme.titleMedium)),
            Text('${widget.selected.length} ${AppCopy.of(context, 'selected')}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 5),
          const Text('Tap one or more points on the body',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
                child: _viewButton(
                    'Front view', !back, () => setState(() => back = false))),
            const SizedBox(width: 8),
            Expanded(
                child: _viewButton(
                    'Back view', back, () => setState(() => back = true))),
          ]),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: AspectRatio(
                aspectRatio: 280 / 350,
                child: Container(
                  decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18)),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    return Stack(children: [
                      Positioned.fill(
                          child: CustomPaint(
                              painter: AnatomyFigurePainter(back: back))),
                      for (final spot in back ? backSpots : frontSpots)
                        Positioned(
                          left: width * spot.x - 22,
                          top: height * spot.y - 22,
                          child: Semantics(
                            label: AppCopy.of(context, spot.area),
                            button: true,
                            selected: widget.selected.contains(spot.area),
                            child: Tooltip(
                              message: AppCopy.of(context, spot.area),
                              child: InkWell(
                                key: ValueKey('body-${spot.area}'),
                                onTap: () => widget.onToggle(spot.area),
                                borderRadius: BorderRadius.circular(22),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      width: widget.selected.contains(spot.area)
                                          ? 26
                                          : 18,
                                      height:
                                          widget.selected.contains(spot.area)
                                              ? 26
                                              : 18,
                                      decoration: BoxDecoration(
                                          color: widget.selected
                                                  .contains(spot.area)
                                              ? AppColors.red
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: widget.selected
                                                      .contains(spot.area)
                                                  ? Colors.white
                                                  : AppColors.teal,
                                              width: 2.5),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Color(0x3322242b),
                                                blurRadius: 5)
                                          ]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]);
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.selected.isEmpty)
            const Center(
                child: Text('No pain or soreness selected',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)))
          else
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final area in widget.selected)
                InputChip(
                    label: Text(area),
                    onDeleted: () => widget.onToggle(area),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: const Color(0xffffeeee),
                    side: const BorderSide(color: Color(0xfff0c6c2))),
            ]),
        ]),
      );

  Widget _viewButton(String label, bool selected, VoidCallback onTap) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
            backgroundColor: selected ? AppColors.ink : Colors.white,
            foregroundColor: selected ? Colors.white : AppColors.ink,
            side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11))),
        child: Text(label),
      );
}

class _BodySpot {
  const _BodySpot(this.area, this.x, this.y);
  final String area;
  final double x;
  final double y;
}
