import 'package:circuit_designer/calculate_outlines.dart';
import 'package:circuit_designer/draggable_footprints.dart';
import 'package:circuit_designer/line_traces.dart';
import 'package:circuit_designer/outline_carve.dart';
import 'package:flutter/material.dart';

class FootPrintPainter extends CustomPainter {
  final List<DraggableFootprints> component;
  final double scale;

  final List<Line> lines;
  final Offset? currentPoint;
  final Offset? startPoint;
  final Function(
          List<Arc>, List<ConnectingLines>, List<SMDOutline>, List<GCodeLines>)
      passLists;

  FootPrintPainter(this.component, this.scale, this.lines, this.currentPoint,
      this.startPoint, this.passLists);

  @override
  void paint(Canvas canvas, Size size) {
    // Outer circle paint indicator
    final circlePaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    // Inner circle paint indicator
    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // This section is for generating line traces if line is not currently empty
    if (lines.isNotEmpty) {
      Path path = Path();

      // Setting the coordinate for the start point of the line
      path.moveTo(lines[0].start.dx * scale, lines[0].start.dy * scale);

      for (int i = 0; i < lines.length; i++) {
        // line paint
        final linePaint = Paint()
          ..color = Colors.lightGreenAccent.shade700
          ..strokeWidth = lines[i].thickness * scale
          ..style = PaintingStyle.stroke;

        Offset start = lines[i].start * scale;
        Offset end = lines[i].end * scale;

        if (i > 0) {
          Offset previousEnd = lines[i - 1].end * scale;

          // This section is for connecting the line's if the end point of the previous line is equal to the start point of the new line
          if (start == previousEnd) {
            Offset controlPoint1 = start;
            Offset controlPoint2 = end;

            path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
                controlPoint2.dy, end.dx, end.dy);
          } else {
            // Generating the line if the end point of the previous line is not equal to the start point of the new line.
            path.moveTo(start.dx, start.dy);
            path.lineTo(end.dx, end.dy);
          }
        } else {
          // Setting the coordinate for the ending point of the line
          path.lineTo(end.dx, end.dy);
        }

        // Drawing the line in the canvas
        canvas.drawPath(path, linePaint);
      }
    }

    // This section is for displaying the selection indicators for dragging the line
    for (var line in lines) {
      if (line.isSelected == true) {
        // Draw the circle indicators of a line if it is selected
        canvas.drawCircle(line.start * scale, 0.6 * scale, circlePaint);
        canvas.drawCircle(line.start * scale, 0.3 * scale, innerCirclePaint);

        canvas.drawCircle(line.end * scale, 0.6 * scale, circlePaint);
        canvas.drawCircle(line.end * scale, 0.3 * scale, innerCirclePaint);
      }
    }

    // This section is for drawing a temporary line if the user haven't tap the end point yet
    if (startPoint != null && currentPoint != null) {
      // Line paint for the temporary line
      final tempLinePaint = Paint()
        ..color = Colors.lightGreenAccent.shade700
        ..strokeWidth = 1.5 * scale
        ..style = PaintingStyle.stroke;

      Offset scaledStart = startPoint! * scale;
      Offset scaledCurrent = currentPoint! * scale;

      // Drawing the temporary line
      canvas.drawLine(scaledStart, scaledCurrent, tempLinePaint);

      // Drawing the circle indicators
      canvas.drawCircle(scaledStart, 0.6 * scale, circlePaint);
      canvas.drawCircle(scaledStart, 0.3 * scale, innerCirclePaint);
      canvas.drawCircle(scaledCurrent, 0.6 * scale, circlePaint);
      canvas.drawCircle(scaledCurrent, 0.3 * scale, innerCirclePaint);
    }

    // This is for drawing the component footprints

    final wirePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke;

    final smdPaint = Paint()
      ..color = Colors.lightGreenAccent.shade700
      ..style = PaintingStyle.fill;

    final outerPadPaint = Paint()..color = Colors.lightGreenAccent.shade700;
    final innerPadPaint = Paint()..color = Colors.white;

    // For Drawing Wires
    for (var draggableComp in component) {
      final position = draggableComp.position * scale;

      for (int i = 0; i < draggableComp.component.wire.length; i++) {
        final x1 = getMeasurementInPixels(draggableComp.component.wire[i].x1);
        final y1 = getMeasurementInPixels(draggableComp.component.wire[i].y1);
        final x2 = getMeasurementInPixels(draggableComp.component.wire[i].x2);
        final y2 = getMeasurementInPixels(draggableComp.component.wire[i].y2);

        // Drawing the wires
        canvas.drawLine(
          Offset((position.dx) + (x1), (position.dy) + (y1)),
          Offset((position.dx) + (x2), (position.dy) + (y2)),
          wirePaint,
        );
      }

      // For Drawing SMDs

      for (int i = 0; i < draggableComp.component.smd.length; i++) {
        final x = getMeasurementInPixels(draggableComp.component.smd[i].x);
        final y = getMeasurementInPixels(draggableComp.component.smd[i].y);
        final dx = getMeasurementInPixels(draggableComp.component.smd[i].dx);
        final dy = getMeasurementInPixels(draggableComp.component.smd[i].dy);

        // Drawing the SMDs
        Rect rect = Rect.fromCenter(
            center: Offset((position.dx) + x, (position.dy) + y),
            width: dx,
            height: dy);
        canvas.drawRect(rect, smdPaint);
      }

      // For Drawing Pads

      for (int i = 0; i < draggableComp.component.pad.length; i++) {
        final x = getMeasurementInPixels(draggableComp.component.pad[i].x);
        final y = getMeasurementInPixels(draggableComp.component.pad[i].y);
        final diameter =
            getMeasurementInPixels(draggableComp.component.pad[i].drill);

        // Drawing the Pads
        canvas.drawCircle(
          Offset((position.dx) + (x), (position.dy) + (y)),
          diameter,
          outerPadPaint,
        );
        canvas.drawCircle(
          Offset((position.dx) + (x), (position.dy) + (y)),
          (diameter / 2),
          innerPadPaint,
        );
      }

      OutlineCalculations(
              footprints: component,
              lines: lines,
              scale: scale,
              passLists: passLists)
          .calculateOutlines();
    }

    // Moving this code to another painter for displaying outlines.

    /*
      
      if (connectingLines.isNotEmpty) {
        Paint linePaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke;

        for (var connectedLines in connectingLines) {
          for (int i = 0; i < connectedLines.connectingLines.length; i++) {
            Offset currentLeftStart =
                connectedLines.connectingLines[i].leftStartPoint / scale;
            Offset currentLeftEnd =
                connectedLines.connectingLines[i].leftEndPoint / scale;
            Offset currentRightStart =
                connectedLines.connectingLines[i].rightStartPoint / scale;
            Offset currentRightEnd =
                connectedLines.connectingLines[i].rightEndPoint / scale;

            if (previousRightEnd != null &&
                previousRightStart != null &&
                previousLeftEnd != null &&
                previousLeftStart != null) {
              Offset? rightAdjustedOffset = findIntersectionOfLines(
                  previousRightStart!,
                  previousRightEnd!,
                  currentRightStart,
                  currentRightEnd);

              if (rightAdjustedOffset != null) {
                connectedLines.connectingLines[i].rightStartPoint =
                    rightAdjustedOffset * scale;

                connectedLines.connectingLines[i - 1].rightEndPoint =
                    rightAdjustedOffset * scale;
              }

              Offset? leftAdjustedOffset = findIntersectionOfLines(
                  previousLeftStart!,
                  previousLeftEnd!,
                  currentLeftStart,
                  currentLeftEnd);

              if (leftAdjustedOffset != null) {
                connectedLines.connectingLines[i].leftStartPoint =
                    leftAdjustedOffset * scale;

                connectedLines.connectingLines[i - 1].leftEndPoint =
                    leftAdjustedOffset * scale;
              }
            }

            previousRightStart = currentRightStart;
            previousRightEnd = currentRightEnd;

            previousLeftStart = currentLeftStart;
            previousLeftEnd = currentLeftEnd;
          }

          previousLeftEnd = null;
          previousLeftStart = null;
          previousRightEnd = null;
          previousRightStart = null;
        }

        for (var connectedLines in connectingLines) {
          for (var connectingLines in connectedLines.connectingLines) {
            canvas.drawLine(connectingLines.leftStartPoint,
                connectingLines.leftEndPoint, linePaint);

            canvas.drawLine(connectingLines.rightStartPoint,
                connectingLines.rightEndPoint, linePaint);
          }
        }
      }

      if (arcs.isNotEmpty) {
        final paint = Paint()
          ..color = Colors.blue
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        for (var arc in arcs) {
          drawArc(arc.startPoint, arc.endPoint, arc.centerPoint, arc.radius,
              canvas);
          if (arc.startPoint == Offset.zero && arc.endPoint == Offset.zero) {
            canvas.drawCircle(
                arc.centerPoint * scale, (arc.radius * scale) / 2, paint);
          }
        }
      }

      if (smds.isNotEmpty) {
        for (var smd in smds) {
          drawSMDs(smd, canvas);
        }
      }

      
      */
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  double getMeasurementInPixels(double num) {
    return num * scale;
  }

  // Moving this to another painter class
  /*
  void drawArc(
      Offset start, Offset end, Offset center, double radius, Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double startAngle = atan2(start.dy - center.dy, start.dx - center.dx);
    double endAngle = atan2(end.dy - center.dy, end.dx - center.dx);

    if (startAngle < 0) {
      startAngle += 2 * pi;
    }
    if (endAngle < 0) {
      endAngle += 2 * pi;
    }

    double sweepAngle = endAngle - startAngle;
    if (sweepAngle < 0) {
      sweepAngle += 2 * pi;
    }

    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    canvas.drawCircle(center, radius / 2, paint);
  }

  void drawSMDs(SMDOutline smdOutline, Canvas canvas) {
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    if (smdOutline.connectedLeftLine.dx / scale == smdOutline.bottomRight.dx &&
        smdOutline.connectedRightLine.dx / scale == smdOutline.topRight.dx) {
      //drawing the outline
      canvas.drawLine(smdOutline.connectedLeftLine,
          smdOutline.bottomRight * scale, linePaint);
      canvas.drawLine(smdOutline.bottomRight * scale,
          smdOutline.bottomLeft * scale, linePaint);
      canvas.drawLine(
          smdOutline.bottomLeft * scale, smdOutline.topLeft * scale, linePaint);
      canvas.drawLine(
          smdOutline.topLeft * scale, smdOutline.topRight * scale, linePaint);
      canvas.drawLine(smdOutline.topRight * scale,
          smdOutline.connectedRightLine, linePaint);
    } else if (smdOutline.connectedLeftLine.dx / scale ==
            smdOutline.topLeft.dx &&
        smdOutline.connectedRightLine.dx / scale == smdOutline.bottomLeft.dx) {
      // drawing the outline
      canvas.drawLine(
          smdOutline.connectedLeftLine, smdOutline.topLeft * scale, linePaint);
      canvas.drawLine(
          smdOutline.topLeft * scale, smdOutline.topRight * scale, linePaint);
      canvas.drawLine(smdOutline.topRight * scale,
          smdOutline.bottomRight * scale, linePaint);
      canvas.drawLine(smdOutline.bottomRight * scale,
          smdOutline.bottomLeft * scale, linePaint);
      canvas.drawLine(smdOutline.bottomLeft * scale,
          smdOutline.connectedRightLine, linePaint);
    } else if (smdOutline.connectedLeftLine.dy / scale ==
            smdOutline.bottomLeft.dy &&
        smdOutline.connectedRightLine.dy / scale == smdOutline.bottomRight.dy) {
      // drawing the outline
      canvas.drawLine(smdOutline.connectedLeftLine,
          smdOutline.bottomLeft * scale, linePaint);
      canvas.drawLine(
          smdOutline.bottomLeft * scale, smdOutline.topLeft * scale, linePaint);
      canvas.drawLine(
          smdOutline.topLeft * scale, smdOutline.topRight * scale, linePaint);
      canvas.drawLine(smdOutline.topRight * scale,
          smdOutline.bottomRight * scale, linePaint);
      canvas.drawLine(smdOutline.bottomRight * scale,
          smdOutline.connectedRightLine, linePaint);
    } else if (smdOutline.connectedLeftLine.dy / scale ==
            smdOutline.topRight.dy &&
        smdOutline.connectedRightLine.dy / scale == smdOutline.topLeft.dy) {
      // drawing the outline
      canvas.drawLine(
          smdOutline.connectedLeftLine, smdOutline.topRight * scale, linePaint);
      canvas.drawLine(smdOutline.topRight * scale,
          smdOutline.bottomRight * scale, linePaint);
      canvas.drawLine(smdOutline.bottomRight * scale,
          smdOutline.bottomLeft * scale, linePaint);
      canvas.drawLine(
          smdOutline.bottomLeft * scale, smdOutline.topLeft * scale, linePaint);
      canvas.drawLine(
          smdOutline.topLeft * scale, smdOutline.connectedRightLine, linePaint);
    }
  }
  */
}
