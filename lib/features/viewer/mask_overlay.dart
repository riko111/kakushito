import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaskStroke {
  final List<Offset> points;
  final int page;

  MaskStroke({required this.points, required this.page});
}

class MaskPainter extends CustomPainter {
  final List<MaskStroke> strokes;
  final bool maskEnabled;
  final Color maskColor;

  const MaskPainter(this.strokes, this.maskEnabled, this.maskColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          maskEnabled ? maskColor : Colors.yellowAccent.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 20.0;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    return oldDelegate.maskEnabled != maskEnabled ||
        oldDelegate.maskColor != maskColor ||
        !listEquals(oldDelegate.strokes, strokes);
  }
}

class MaskOverlay extends StatefulWidget {
  final List<MaskStroke> strokes;
  final bool maskEnabled;

  const MaskOverlay({super.key, required this.strokes, required this.maskEnabled});

  @override
  State<MaskOverlay> createState() => _MaskOverlayState();
}

class _MaskOverlayState extends State<MaskOverlay> {
  static const _maskColorKey = 'maskColor';
  Color _maskColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadMaskColor();
  }

  Future<void> _loadMaskColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_maskColorKey);
    if (value != null && mounted) {
      setState(() => _maskColor = Color(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MaskPainter(
        List<MaskStroke>.from(widget.strokes),
        widget.maskEnabled,
        _maskColor,
      ),
      size: Size.infinite,
    );
  }
}

