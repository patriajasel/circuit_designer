import 'package:circuit_designer/draggable_footprints.dart';
import 'package:flutter/material.dart';

class FootPrintPainter extends CustomPainter {
  final List<DraggableFootprints> component;
  final double scale;

  FootPrintPainter(this.component, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    // * Calculate the center of the canvas
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final wirePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;
    
    // * For Drawing Wires
    for (var comp in component) {
      for (int i = 0; i < comp.component.wire.length; i++) {
        final x1 = getMeasurementInPixels(double.parse(comp.component.wire[i].x1));
        final y1 = getMeasurementInPixels(double.parse(comp.component.wire[i].y1));
        final x2 = getMeasurementInPixels(double.parse(comp.component.wire[i].x2));
        final y2 = getMeasurementInPixels(double.parse(comp.component.wire[i].y2));

        // Offset wires by the canvas center
        canvas.drawLine(Offset(centerX + x1, centerY + y1),
            Offset(centerX + x2, centerY + y2), wirePaint);
      }
    }

    // * For Drawing Pads
    final outerPadPaint = Paint()..color = Colors.green;
    final innerPadPaint = Paint()..color = Colors.red;

    for (var comp in component) {
      for (int i = 0; i < comp.component.pad.length; i++) {
        final x = getMeasurementInPixels(double.parse(comp.component.pad[i].x));
        final y = getMeasurementInPixels(double.parse(comp.component.pad[i].y));
        final diameter =
            getMeasurementInPixels(double.parse(comp.component.pad[i].drill));

        // Offset pads by the canvas center
        canvas.drawCircle(
            Offset(centerX + x, centerY + y), diameter, outerPadPaint);
        canvas.drawCircle(
          Offset(centerX + x, centerY + y),
          diameter / 2,
          innerPadPaint,
        );
      }
    }

    // * For Drawing SMDs
    final padPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    for (var comp in component) {
      for (int i = 0; i < comp.component.smd.length; i++) {
        final x = getMeasurementInPixels(double.parse(comp.component.smd[i].x));
        final y = getMeasurementInPixels(double.parse(comp.component.smd[i].y));
        final dx = getMeasurementInPixels(double.parse(comp.component.smd[i].dx));
        final dy = getMeasurementInPixels(double.parse(comp.component.smd[i].dy));

        // Offset SMDs by the canvas center
        Rect rect = Rect.fromLTWH(centerX + x, centerY + y, dx, dy);
        canvas.drawRect(
          rect,
          padPaint,
        );
      }
    }

    
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  double getMeasurementInPixels(double num) {
    double ppi = 96.0;
    double pixels = (num / 25.4) * ppi;

    return pixels * scale;
  }
}
