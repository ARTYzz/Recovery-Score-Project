import 'package:flutter/material.dart' hide Text;

import 'app_text.dart';
import 'components.dart';
import 'design.dart';

/// A tappable, schematic body map. Area names match TrainingSession.soreness.
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
            child: Container(
              width: 280,
              height: 350,
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18)),
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                return Stack(children: [
                  Positioned.fill(
                      child: CustomPaint(painter: _BodyPainter(back))),
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
                                  duration: const Duration(milliseconds: 150),
                                  width: widget.selected.contains(spot.area)
                                      ? 26
                                      : 18,
                                  height: widget.selected.contains(spot.area)
                                      ? 26
                                      : 18,
                                  decoration: BoxDecoration(
                                      color: widget.selected.contains(spot.area)
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

class _BodyPainter extends CustomPainter {
  const _BodyPainter(this.back);
  final bool back;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 280, size.height / 350);
    final fill = Paint()..color = const Color(0xffdce5e7);
    final outline = Paint()
      ..color = const Color(0xffa7b5ba)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final limb = Paint()
      ..color = fill.color
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round;
    final limbLine = Paint()
      ..color = outline.color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    void segment(Offset start, Offset end) {
      canvas.drawLine(start, end, limb);
      canvas.drawLine(start, end, limbLine);
    }

    segment(const Offset(105, 94), const Offset(74, 147));
    segment(const Offset(74, 147), const Offset(54, 205));
    segment(const Offset(175, 94), const Offset(206, 147));
    segment(const Offset(206, 147), const Offset(226, 205));
    segment(const Offset(124, 184), const Offset(119, 307));
    segment(const Offset(156, 184), const Offset(161, 307));
    final torso = Path()
      ..moveTo(109, 78)
      ..quadraticBezierTo(140, 71, 171, 78)
      ..lineTo(162, 148)
      ..lineTo(165, 190)
      ..quadraticBezierTo(140, 203, 115, 190)
      ..lineTo(118, 148)
      ..close();
    canvas.drawPath(torso, fill);
    canvas.drawPath(torso, outline);
    canvas.drawOval(const Rect.fromLTWH(41, 201, 23, 34), fill);
    canvas.drawOval(const Rect.fromLTWH(216, 201, 23, 34), fill);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(132, 57, 16, 24), const Radius.circular(6)),
        fill);
    canvas.drawOval(const Rect.fromLTWH(119, 16, 42, 52), fill);
    canvas.drawOval(const Rect.fromLTWH(119, 16, 42, 52), outline);
    if (back) {
      canvas.drawLine(const Offset(140, 90), const Offset(140, 177), limbLine);
      canvas.drawLine(const Offset(118, 96), const Offset(137, 125), limbLine);
      canvas.drawLine(const Offset(162, 96), const Offset(143, 125), limbLine);
      canvas.drawLine(const Offset(121, 163), const Offset(159, 163), limbLine);
    } else {
      canvas.drawLine(const Offset(140, 88), const Offset(140, 122), limbLine);
      canvas.drawArc(
          const Rect.fromLTWH(116, 93, 48, 37), 0.15, 2.75, false, limbLine);
      canvas.drawLine(const Offset(124, 137), const Offset(156, 137), limbLine);
      canvas.drawLine(const Offset(125, 151), const Offset(155, 151), limbLine);
      canvas.drawLine(const Offset(128, 165), const Offset(152, 165), limbLine);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodyPainter oldDelegate) => oldDelegate.back != back;
}
