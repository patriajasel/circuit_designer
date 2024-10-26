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
    // Circle paint indicator
    final circlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // inner circle indicator
    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (lines.isNotEmpty) {
      Path path = Path();

      // Start drawing from the first point of the first line
      path.moveTo(lines[0].start.dx * scale, lines[0].start.dy * scale);

      for (int i = 0; i < lines.length; i++) {
        // Create a new Paint object for each line to set the dynamic thickness
        final linePaint = Paint()
          ..color = Colors.black
          ..strokeWidth = lines[i].thickness * scale // Use the line's thickness
          ..style = PaintingStyle.stroke;

        print("Line Thickness: ${lines[i].thickness}");

        Offset start = lines[i].start * scale;
        Offset end = lines[i].end * scale;

        if (i > 0) {
          Offset previousEnd = lines[i - 1].end * scale;

          if (start == previousEnd) {
            // If the lines are connected, draw a smooth curve
            Offset controlPoint1 = start;
            Offset controlPoint2 = end;

            path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
                controlPoint2.dy, end.dx, end.dy);
          } else {
            // Move to the next point without connecting if lines are not connected
            path.moveTo(start.dx, start.dy);
            path.lineTo(end.dx, end.dy);
          }
        } else {
          // For the first line, just move to the first point and lineTo the end
          path.lineTo(end.dx, end.dy);
        }

        // Draw the current path (line) with the corresponding thickness
        canvas.drawPath(path, linePaint);

        // Now draw the circles, but only if the corresponding line is selected
      }
    }

    for (var line in lines) {
      if (line.isSelected == true) {
        // Draw a circle at the start of the line if it's selected
        canvas.drawCircle(line.start * scale, 0.6 * scale, circlePaint);
        canvas.drawCircle(line.start * scale, 0.3 * scale, innerCirclePaint);

        // Draw a circle at the end of the line if it's selected
        canvas.drawCircle(line.end * scale, 0.6 * scale, circlePaint);
        canvas.drawCircle(line.end * scale, 0.3 * scale, innerCirclePaint);
      }
    }

// If there's a start point and the user is currently drawing, draw the temporary line
    if (startPoint != null && currentPoint != null) {
      // Create a Paint object for the temporary line with a default thickness
      final tempLinePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.0 * scale // Default thickness for the temporary line
        ..style = PaintingStyle.stroke;

      // Scale the start and current positions based on the zoom level
      Offset scaledStart = startPoint! * scale;
      Offset scaledCurrent = currentPoint! * scale;

      // Draw the temporary line first
      canvas.drawLine(scaledStart, scaledCurrent, tempLinePaint);

      // Draw the circles on top of the temporary lines
      canvas.drawCircle(startPoint! * scale, 0.6 * scale, circlePaint);
      canvas.drawCircle(startPoint! * scale, 0.3 * scale, innerCirclePaint);
      canvas.drawCircle(currentPoint! * scale, 0.6 * scale, circlePaint);
      canvas.drawCircle(currentPoint! * scale, 0.3 * scale, innerCirclePaint);
    }

    final wirePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke;

    final padPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final outerPadPaint = Paint()..color = Colors.black;
    final innerPadPaint = Paint()..color = Colors.white;

    // * For Drawing Wires
    for (var draggableComp in component) {
      // Use the draggable component's position (unscaled)
      final position = draggableComp.position;

      for (int i = 0; i < draggableComp.component.wire.length; i++) {
        final x1 = getMeasurementInPixels(draggableComp.component.wire[i].x1);
        final y1 = getMeasurementInPixels(draggableComp.component.wire[i].y1);
        final x2 = getMeasurementInPixels(draggableComp.component.wire[i].x2);
        final y2 = getMeasurementInPixels(draggableComp.component.wire[i].y2);

        // Offset wires by the unscaled position but scale the wire length
        canvas.drawLine(
          Offset((position.dx * scale) + (x1), (position.dy * scale) + (y1)),
          Offset((position.dx * scale) + (x2), (position.dy * scale) + (y2)),
          wirePaint,
        );
      }

      // * For Drawing SMDs

      for (int i = 0; i < draggableComp.component.smd.length; i++) {
        final x = getMeasurementInPixels(draggableComp.component.smd[i].x);
        final y = getMeasurementInPixels(draggableComp.component.smd[i].y);
        final dx = getMeasurementInPixels(draggableComp.component.smd[i].dx);
        final dy = getMeasurementInPixels(draggableComp.component.smd[i].dy);

        // Offset SMDs by the unscaled position and scale the rectangle dimensions
        Rect rect = Rect.fromCenter(
            center:
                Offset((position.dx * scale) + x, (position.dy * scale) + y),
            width: dx,
            height: dy);
        canvas.drawRect(rect, padPaint);
      }

      // * For Drawing Pads

      for (int i = 0; i < draggableComp.component.pad.length; i++) {
        final x = getMeasurementInPixels(draggableComp.component.pad[i].x);
        final y = getMeasurementInPixels(draggableComp.component.pad[i].y);
        final diameter =
            getMeasurementInPixels(draggableComp.component.pad[i].drill);

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
    } // Define a distance threshold
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint to reflect updates in position
  }

  double getMeasurementInPixels(double num) {
    return num * scale;
  }
}
