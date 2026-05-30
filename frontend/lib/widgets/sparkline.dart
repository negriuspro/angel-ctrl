import 'dart:math';

import 'package:flutter/material.dart';

class SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color fillColor;

  SparklinePainter(
      {required this.values, required this.color, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce(max).clamp(1.0, double.infinity);
    final stepX = size.width / max(1, values.length - 1);
    final path = Path();
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    path.moveTo(0, size.height - (values[0] / maxVal) * size.height);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(
          i * stepX, size.height - (values[i] / maxVal) * size.height);
    }

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path);
    fillPath.lineTo((values.length - 1) * stepX, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter old) => old.values != values;
}
