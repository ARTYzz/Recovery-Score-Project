import 'package:flutter/material.dart';

import 'design.dart';

/// Draws a compact front/back anatomical figure directly with Flutter paths.
/// This is an illustration for locating soreness, not a diagnostic diagram.
class AnatomyFigurePainter extends CustomPainter {
  AnatomyFigurePainter({required this.back});

  final bool back;

  static final Color _skin = Color.lerp(Colors.white, AppColors.amber, .22)!;
  static final Color _muscle = Color.lerp(_skin, AppColors.red, .47)!;
  static final Color _muscleLight = Color.lerp(_skin, AppColors.red, .24)!;
  static final Color _shade = Color.lerp(_skin, AppColors.red, .65)!;
  static final Color _line = AppColors.ink.withValues(alpha: .48);

  final Paint _base = Paint()..color = _skin;
  final Paint _fiber = Paint()..color = _muscle;
  final Paint _light = Paint()..color = _muscleLight;
  final Paint _edge = Paint()
    ..color = _line
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.15
    ..strokeJoin = StrokeJoin.round;
  final Paint _detail = Paint()
    ..color = _shade
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round;

  void _shape(Canvas canvas, Path path, Paint paint, {bool outline = true}) {
    canvas.drawPath(path, paint);
    if (outline) canvas.drawPath(path, _edge);
  }

  void _mirror(Canvas canvas, void Function() draw) {
    draw();
    canvas.save();
    canvas.translate(280, 0);
    canvas.scale(-1, 1);
    draw();
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 280, size.height / 350);
    _mirror(canvas, () => _leg(canvas));
    _mirror(canvas, () => _arm(canvas));
    _torso(canvas);
    _neckAndHead(canvas);
    _mirror(canvas, () => _hand(canvas));
    canvas.restore();
  }

  void _leg(Canvas canvas) {
    final leg = Path()
      ..moveTo(113, 187)
      ..cubicTo(105, 213, 105, 233, 108, 256)
      ..cubicTo(108, 274, 106, 300, 106, 317)
      ..quadraticBezierTo(103, 323, 99, 331)
      ..quadraticBezierTo(98, 337, 106, 339)
      ..lineTo(123, 339)
      ..quadraticBezierTo(130, 336, 128, 330)
      ..lineTo(124, 315)
      ..cubicTo(128, 290, 137, 261, 139, 237)
      ..lineTo(141, 201)
      ..close();
    _shape(canvas, leg, _base);
    final thigh = Path()
      ..moveTo(111, 204)
      ..quadraticBezierTo(116, 197, 136, 207)
      ..lineTo(132, 245)
      ..quadraticBezierTo(121, 259, 109, 248)
      ..close();
    _shape(canvas, thigh, _fiber, outline: false);
    final lower = Path()
      ..moveTo(110, 260)
      ..quadraticBezierTo(119, 266, 129, 256)
      ..quadraticBezierTo(124, 292, 115, 312)
      ..quadraticBezierTo(108, 300, 110, 260)
      ..close();
    _shape(canvas, lower, _light, outline: false);
    canvas.drawLine(const Offset(123, 212), const Offset(117, 248), _detail);
    canvas.drawLine(const Offset(111, 254), const Offset(129, 254), _detail);
    canvas.drawLine(const Offset(111, 272), const Offset(116, 304), _detail);
    canvas.drawLine(const Offset(118, 318), const Offset(123, 334), _detail);
    canvas.drawLine(const Offset(104, 330), const Offset(126, 330), _detail);
    for (var toe = 0; toe < 3; toe++) {
      canvas.drawLine(
          Offset(103 + toe * 6, 335), Offset(103 + toe * 6, 339), _detail);
    }
  }

  void _arm(Canvas canvas) {
    final arm = Path()
      ..moveTo(109, 86)
      ..quadraticBezierTo(91, 81, 81, 99)
      ..cubicTo(75, 114, 72, 132, 69, 145)
      ..cubicTo(61, 161, 56, 185, 51, 205)
      ..lineTo(63, 209)
      ..cubicTo(72, 185, 82, 164, 85, 149)
      ..quadraticBezierTo(99, 125, 111, 109)
      ..close();
    _shape(canvas, arm, _base);
    final deltoid = Path()
      ..moveTo(105, 88)
      ..quadraticBezierTo(85, 87, 81, 107)
      ..quadraticBezierTo(84, 118, 93, 123)
      ..quadraticBezierTo(105, 106, 105, 88)
      ..close();
    _shape(canvas, deltoid, _fiber, outline: false);
    final upper = Path()
      ..moveTo(83, 120)
      ..quadraticBezierTo(89, 126, 93, 127)
      ..quadraticBezierTo(77, 151, 68, 156)
      ..quadraticBezierTo(70, 135, 83, 120)
      ..close();
    _shape(canvas, upper, _light, outline: false);
    final forearm = Path()
      ..moveTo(67, 159)
      ..quadraticBezierTo(78, 160, 82, 158)
      ..quadraticBezierTo(69, 189, 60, 203)
      ..quadraticBezierTo(58, 187, 67, 159)
      ..close();
    _shape(canvas, forearm, _fiber, outline: false);
    canvas.drawLine(const Offset(72, 164), const Offset(59, 196), _detail);
    canvas.drawLine(const Offset(79, 168), const Offset(63, 200), _detail);
    canvas.drawLine(const Offset(70, 150), const Offset(83, 151), _detail);
    canvas.drawLine(const Offset(52, 202), const Offset(63, 206), _detail);
  }

  void _torso(Canvas canvas) {
    final torso = Path()
      ..moveTo(110, 82)
      ..quadraticBezierTo(140, 74, 170, 82)
      ..quadraticBezierTo(174, 105, 167, 131)
      ..quadraticBezierTo(161, 151, 163, 173)
      ..quadraticBezierTo(170, 188, 165, 201)
      ..quadraticBezierTo(154, 211, 140, 212)
      ..quadraticBezierTo(126, 211, 115, 201)
      ..quadraticBezierTo(110, 188, 117, 173)
      ..quadraticBezierTo(119, 151, 113, 131)
      ..quadraticBezierTo(106, 105, 110, 82)
      ..close();
    _shape(canvas, torso, _base);
    if (back) {
      _backMuscles(canvas);
    } else {
      _frontMuscles(canvas);
    }
  }

  void _frontMuscles(Canvas canvas) {
    _mirror(canvas, () {
      final chest = Path()
        ..moveTo(139, 88)
        ..quadraticBezierTo(122, 80, 109, 91)
        ..quadraticBezierTo(108, 111, 120, 123)
        ..quadraticBezierTo(134, 125, 139, 112)
        ..close();
      _shape(canvas, chest, _fiber, outline: false);
      final oblique = Path()
        ..moveTo(114, 126)
        ..quadraticBezierTo(124, 139, 122, 168)
        ..lineTo(133, 178)
        ..quadraticBezierTo(117, 169, 114, 126)
        ..close();
      _shape(canvas, oblique, _light, outline: false);
      canvas.drawLine(const Offset(115, 101), const Offset(136, 106), _detail);
      canvas.drawLine(const Offset(120, 112), const Offset(135, 116), _detail);
      canvas.drawLine(const Offset(119, 136), const Offset(132, 146), _detail);
      canvas.drawLine(const Offset(122, 154), const Offset(131, 161), _detail);
    });
    canvas.drawLine(const Offset(140, 87), const Offset(140, 124), _detail);
    for (final y in [137.0, 152.0, 167.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(127, y, 12, 13), const Radius.circular(3)),
          _fiber);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(141, y, 12, 13), const Radius.circular(3)),
          _fiber);
    }
    canvas.drawLine(const Offset(140, 132), const Offset(140, 182), _detail);
    canvas.drawLine(const Offset(123, 184), const Offset(140, 207), _detail);
    canvas.drawLine(const Offset(157, 184), const Offset(140, 207), _detail);
    canvas.drawCircle(const Offset(140, 184), 1.7, _detail);
  }

  void _backMuscles(Canvas canvas) {
    _mirror(canvas, () {
      final trapezius = Path()
        ..moveTo(136, 80)
        ..quadraticBezierTo(122, 85, 109, 91)
        ..quadraticBezierTo(115, 113, 137, 127)
        ..close();
      _shape(canvas, trapezius, _fiber, outline: false);
      final lat = Path()
        ..moveTo(111, 117)
        ..quadraticBezierTo(121, 132, 137, 130)
        ..lineTo(136, 168)
        ..quadraticBezierTo(120, 162, 118, 151)
        ..close();
      _shape(canvas, lat, _light, outline: false);
      final glute = Path()
        ..moveTo(119, 178)
        ..quadraticBezierTo(136, 177, 139, 195)
        ..quadraticBezierTo(129, 210, 115, 198)
        ..close();
      _shape(canvas, glute, _fiber, outline: false);
      canvas.drawLine(const Offset(116, 97), const Offset(134, 116), _detail);
      canvas.drawLine(const Offset(115, 128), const Offset(136, 142), _detail);
      canvas.drawLine(const Offset(120, 168), const Offset(135, 174), _detail);
    });
    canvas.drawLine(const Offset(140, 80), const Offset(140, 197), _detail);
    for (var y = 93.0; y < 175; y += 11) {
      canvas.drawCircle(Offset(140, y), 1.6, _detail);
    }
  }

  void _neckAndHead(Canvas canvas) {
    final neck = Path()
      ..moveTo(131, 58)
      ..lineTo(131, 81)
      ..quadraticBezierTo(140, 90, 149, 81)
      ..lineTo(149, 58)
      ..close();
    _shape(canvas, neck, _base);
    _mirror(canvas, () {
      final neckMuscle = Path()
        ..moveTo(132, 62)
        ..quadraticBezierTo(129, 75, 118, 85)
        ..lineTo(135, 81)
        ..close();
      _shape(canvas, neckMuscle, _light, outline: false);
    });
    final head = Path()
      ..moveTo(140, 13)
      ..cubicTo(124, 13, 118, 22, 119, 37)
      ..quadraticBezierTo(116, 40, 119, 48)
      ..quadraticBezierTo(121, 50, 123, 48)
      ..quadraticBezierTo(126, 61, 140, 66)
      ..quadraticBezierTo(154, 61, 157, 48)
      ..quadraticBezierTo(159, 50, 161, 48)
      ..quadraticBezierTo(164, 40, 161, 37)
      ..cubicTo(162, 22, 156, 13, 140, 13)
      ..close();
    _shape(canvas, head, _base);
    if (back) {
      _mirror(canvas, () {
        canvas.drawArc(
            const Rect.fromLTWH(122, 19, 18, 35), 0.2, 1.8, false, _detail);
        canvas.drawLine(const Offset(129, 42), const Offset(135, 61), _detail);
      });
    } else {
      _mirror(canvas, () {
        canvas.drawArc(
            const Rect.fromLTWH(126, 35, 11, 6), 0.2, 2.7, false, _detail);
        canvas.drawLine(const Offset(127, 33), const Offset(136, 34), _detail);
        canvas.drawLine(const Offset(132, 50), const Offset(140, 52), _detail);
      });
      canvas.drawLine(const Offset(140, 37), const Offset(140, 49), _detail);
      canvas.drawLine(const Offset(134, 57), const Offset(146, 57), _detail);
    }
  }

  void _hand(Canvas canvas) {
    final palm = Path()
      ..moveTo(51, 202)
      ..quadraticBezierTo(45, 203, 44, 213)
      ..lineTo(45, 224)
      ..quadraticBezierTo(51, 229, 58, 222)
      ..lineTo(63, 209)
      ..close();
    _shape(canvas, palm, _base);
    final fingers = Paint()
      ..color = _skin
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final fingerEdge = Paint()
      ..color = _line
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = 45.0 + i * 4.1;
      final tip = 228.0 + (i == 1 || i == 2 ? 5 : 1);
      canvas.drawLine(Offset(x, 216), Offset(x - 1, tip), fingerEdge);
      canvas.drawLine(Offset(x, 216), Offset(x - 1, tip), fingers);
    }
    canvas.drawLine(const Offset(57, 207), const Offset(67, 215), fingerEdge);
    canvas.drawLine(const Offset(57, 207), const Offset(67, 215), fingers);
    canvas.drawLine(const Offset(46, 210), const Offset(57, 211), _detail);
  }

  @override
  bool shouldRepaint(AnatomyFigurePainter oldDelegate) =>
      oldDelegate.back != back;
}
