import 'package:circuit_designer/draggable_footprints.dart';
import 'package:circuit_designer/line_traces.dart';
import 'package:flutter/material.dart';

class FootPrintPainter extends CustomPainter {
  final List<DraggableFootprints> component;
  final double scale;

  final List<Line> lines;
  final Offset? currentPoint;
  final Offset? startPoint;
  final bool isTracing;

  FootPrintPainter(this.component, this.scale, this.isTracing, this.lines,
      this.currentPoint, this.startPoint);

  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;

    final padPaint = Paint()
      ..color = Colors.yellowAccent.shade700
      ..style = PaintingStyle.fill;

    final outerPadPaint = Paint()..color = Colors.yellowAccent.shade700;
    final innerPadPaint = Paint()..color = Colors.black;

    // * For Drawing Wires
    for (var draggableComp in component) {
      // Use the draggable component's position (unscaled)
      final position = draggableComp.position;

      for (int i = 0; i < draggableComp.component.wire.length; i++) {
        final x1 = getMeasurementInPixels(
            double.parse(draggableComp.component.wire[i].x1));
        final y1 = getMeasurementInPixels(
            double.parse(draggableComp.component.wire[i].y1));
        final x2 = getMeasurementInPixels(
            double.parse(draggableComp.component.wire[i].x2));
        final y2 = getMeasurementInPixels(
            double.parse(draggableComp.component.wire[i].y2));

        // Offset wires by the unscaled position but scale the wire length
        canvas.drawLine(
          Offset((position.dx * scale) + (x1), (position.dy * scale) + (y1)),
          Offset((position.dx * scale) + (x2), (position.dy * scale) + (y2)),
          wirePaint,
        );
      }

      // * For Drawing SMDs

      for (int i = 0; i < draggableComp.component.smd.length; i++) {
        final x = getMeasurementInPixels(
            double.parse(draggableComp.component.smd[i].x));
        final y = getMeasurementInPixels(
            double.parse(draggableComp.component.smd[i].y));
        final dx = getMeasurementInPixels(
            double.parse(draggableComp.component.smd[i].dx));
        final dy = getMeasurementInPixels(
            double.parse(draggableComp.component.smd[i].dy));

        // Offset SMDs by the unscaled position and scale the rectangle dimensions
        Rect rect = Rect.fromLTWH(
            (position.dx * scale) + (x), (position.dy * scale) + (y), dx, dy);
        canvas.drawRect(rect, padPaint);
      }

      // * For Drawing Pads

      for (int i = 0; i < draggableComp.component.pad.length; i++) {
        final x = getMeasurementInPixels(
            double.parse(draggableComp.component.pad[i].x));
        final y = getMeasurementInPixels(
            double.parse(draggableComp.component.pad[i].y));
        final diameter = getMeasurementInPixels(
            double.parse(draggableComp.component.pad[i].drill));

        // Offset pads by the unscaled position and scale the diameter
        canvas.drawCircle(
          Offset((position.dx * scale) + (x), (position.dy * scale) + (y)),
          diameter, // Scale the diameter
          outerPadPaint,
        );
        canvas.drawCircle(
          Offset((position.dx * scale) + (x), (position.dy * scale) + (y)),
          (diameter / 2), // Scale the inner circle too
          innerPadPaint,
        );
      }
    }

    final double thresholdDistance =
        10.0 * scale; // Define a distance threshold

    final paint = Paint()
      ..color = Colors.yellowAccent.shade700
      ..strokeWidth = 3.0 * scale
      ..style = PaintingStyle.stroke;

    if (lines.isNotEmpty) {
      Path path = Path();

      // Start drawing from the first point of the first line
      path.moveTo(lines[0].start.dx * scale, lines[0].start.dy * scale);

      for (int i = 0; i < lines.length; i++) {
        Offset start = lines[i].start * scale;
        Offset end = lines[i].end * scale;

        if (i > 0) {
          Offset previousEnd = lines[i - 1].end * scale;

          // Calculate the distance between the end of the previous line and the start of the current one
          double distance = (start - previousEnd).distance;

          if (distance < thresholdDistance) {
            // If the distance is smaller than the threshold, connect the points
            // Calculate control points for cubic Bezier (you can customize these)
            Offset controlPoint1 = start; // First control point
            Offset controlPoint2 = end; // Second control point

            // Draw a cubic Bezier curve to the next point
            path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
                controlPoint2.dy, end.dx, end.dy);
          } else {
            // If the distance is greater than the threshold, move to the next point without connecting
            path.moveTo(start.dx, start.dy);
            path.lineTo(end.dx, end.dy);
          }
        } else {
          // Just move to the first point for the first line
          path.lineTo(end.dx, end.dy);
        }
      }

      // Draw the final path as a single connected line
      canvas.drawPath(path, paint);
    }

// If there's a start point and the user is currently drawing, draw the temporary line
    if (startPoint != null && currentPoint != null) {
      // Scale the start and current positions based on the zoom level
      Offset scaledStart = startPoint! * scale;
      Offset scaledCurrent = currentPoint! * scale;

      // Now draw the scaled line
      canvas.drawLine(scaledStart, scaledCurrent, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint to reflect updates in position
  }

  double getMeasurementInPixels(double num) {
    double ppi = 96.0;
    return (num / 25.4) *
        ppi *
        scale; // Do not scale here, scaling is handled in paint
  }
}
