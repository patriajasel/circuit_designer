import 'dart:math';

import 'package:circuit_designer/data_footprints.dart';
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
  final bool displayOutline;

  FootPrintPainter(this.component, this.scale, this.displayOutline, this.lines,
      this.currentPoint, this.startPoint);

  bool isLineIntersect = false;
  bool isLineEqual = false;

  Offset? previousLeftStart;
  Offset? previousLeftEnd;
  Offset? previousRightStart;
  Offset? previousRightEnd;

  Offset? padOffset;

  double lengthChange = 0.1;

  List<Outlines> outlines = [];
  List<ConnectingLines> connectingLines = [];

  @override
  void paint(Canvas canvas, Size size) {
    if (!displayOutline) {
      // Outer circle paint indicator
      final circlePaint = Paint()
        ..color = Colors.red
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
            ..color = Colors.black
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
          ..color = Colors.black
          ..strokeWidth = 1.0 * scale
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
        ..color = Colors.grey
        ..style = PaintingStyle.stroke;

      final padPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      final outerPadPaint = Paint()..color = Colors.black;
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
          canvas.drawRect(rect, padPaint);
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
      }
    } else {
      if (component.isNotEmpty) {
        int points = 50;
        Paint paint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke;

        for (var draggableComponent in component) {
          for (var pad in draggableComponent.component.pad) {
            Offset position = draggableComponent.position * scale;
            final double centerX = (pad.x * scale) + (position.dx);
            final double centerY = (pad.y * scale) + (position.dy);
            final double radius = pad.drill * scale;

            Path circlePath = Path();
            circlePath.moveTo(
                centerX + radius, centerY); // Start path at first circle point

            for (int i = 0; i < points; i++) {
              double angle = (i * 2 * pi) / points;
              double x = centerX + radius * cos(angle);
              double y = centerY + radius * sin(angle);

              circlePath.lineTo(x, y); // Draw the circle

              // Debug: Circle point coordinates
            }

            circlePath.close();
            canvas.drawPath(
                circlePath, paint); // Draw the entire path, including lines
          }
        }
      }

      if (lines.isNotEmpty) {
        for (var line in lines) {
          // Looping through all of the lines
          print("Line #${lines.indexOf(line)}: ${line.startConnected}");
          print("Line #${lines.indexOf(line)}: ${line.endConnected}");

          Offset endLine = line.end * scale;
          Offset startLine = line.start * scale;
          double lineThickness = (line.thickness / 2) * scale;

          if (line.startConnected && !line.endConnected) {
            Pad? pad = checkForPads(line.start);

            Outlines outline = getOutlines(
                padOffset!, pad!.drill * scale, lineThickness, endLine, false);

            outlines.add(outline);
          } else if (!line.startConnected && !line.endConnected) {
            Outlines outline =
                getLines(startLine / scale, endLine / scale, lineThickness);

            outlines.add(outline);
          } else if (line.endConnected && !line.startConnected) {
            Pad? pad = checkForPads(line.end);

            Outlines outline = getOutlines(
                padOffset!, pad!.drill * scale, lineThickness, startLine, true);

            outlines.add(outline);

            connectingLines
                .add(ConnectingLines(connectingLines: List.from(outlines)));
            outlines.clear();
          } else if (line.startConnected && line.endConnected) {
            print("Both are connected");
            Pad? pad1 = checkForPads(line.start);
            Outlines outline1 = getOutlines(
                padOffset!, pad1!.drill * scale, lineThickness, endLine, false);

            Pad? pad2 = checkForPads(line.end);
            Outlines outline2 = getOutlines(padOffset!, pad2!.drill * scale,
                lineThickness, startLine, true);

            Outlines finalOutline = Outlines(
                leftStartPoint: outline1.leftStartPoint,
                leftEndPoint: outline2.leftEndPoint,
                rightStartPoint: outline1.rightStartPoint,
                rightEndPoint: outline2.rightEndPoint,
                centerStartPoint: outline1.centerStartPoint,
                centerEndPoint: outline2.centerEndPoint);

            outlines.add(finalOutline);

            connectingLines
                .add(ConnectingLines(connectingLines: List.from(outlines)));
            outlines.clear();
          }
        }
      }

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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  double getMeasurementInPixels(double num) {
    return num * scale;
  }

  Offset calculateCircleEdgePoint(
      Offset padOffset, double padRadius, double angle) {
    return Offset(padOffset.dx + padRadius * cos(angle),
        padOffset.dy + padRadius * sin(angle));
  }

  Outlines getOutlines(Offset padCenter, double padRadius, double lineThickness,
      Offset notConnectedPoint, bool isEnd) {
    double dx = notConnectedPoint.dx - (padCenter.dx * scale);
    double dy = notConnectedPoint.dy - (padCenter.dy * scale);
    double angle = atan2(dy, dx);

    // Center Line Values
    Offset centerLineStart =
        calculateCircleEdgePoint(padCenter * scale, padRadius, angle);

    // Left Line Values
    Offset leftLineStart = calculateCircleEdgePoint(
        padCenter * scale, padRadius, angle + (lineThickness / padRadius));

    Offset leftLineEnd = Offset(
        notConnectedPoint.dx + (leftLineStart.dx - centerLineStart.dx),
        notConnectedPoint.dy + (leftLineStart.dy - centerLineStart.dy));

    // Right Line Values
    Offset rightLineStart = calculateCircleEdgePoint(
        padCenter * scale, padRadius, angle - (lineThickness / padRadius));

    Offset rightLineEnd = Offset(
        notConnectedPoint.dx + (rightLineStart.dx - centerLineStart.dx),
        notConnectedPoint.dy + (rightLineStart.dy - centerLineStart.dy));

    if (isEnd) {
      return Outlines(
          leftStartPoint: rightLineEnd,
          leftEndPoint: rightLineStart,
          rightStartPoint: leftLineEnd,
          rightEndPoint: leftLineStart,
          centerStartPoint: notConnectedPoint,
          centerEndPoint: centerLineStart);
    }

    return Outlines(
        centerStartPoint: centerLineStart,
        centerEndPoint: notConnectedPoint,
        leftStartPoint: leftLineStart,
        leftEndPoint: leftLineEnd,
        rightStartPoint: rightLineStart,
        rightEndPoint: rightLineEnd);
  }

  Outlines getLines(Offset startLine, Offset endLine, double lineThickness) {
    double dx = endLine.dx * scale - startLine.dx * scale;
    double dy = endLine.dy * scale - startLine.dy * scale;
    double angle = atan2(dy, dx);

    // Left line
    Offset leftStart = Offset(
      startLine.dx * scale + lineThickness * cos(angle + pi / 2),
      startLine.dy * scale + lineThickness * sin(angle + pi / 2),
    );
    Offset leftEnd = Offset(
      endLine.dx * scale + lineThickness * cos(angle + pi / 2),
      endLine.dy * scale + lineThickness * sin(angle + pi / 2),
    );

    // Right line
    Offset rightStart = Offset(
      startLine.dx * scale + lineThickness * cos(angle - pi / 2),
      startLine.dy * scale + lineThickness * sin(angle - pi / 2),
    );
    Offset rightEnd = Offset(
      endLine.dx * scale + lineThickness * cos(angle - pi / 2),
      endLine.dy * scale + lineThickness * sin(angle - pi / 2),
    );

    return Outlines(
        leftStartPoint: leftStart,
        leftEndPoint: leftEnd,
        rightStartPoint: rightStart,
        rightEndPoint: rightEnd,
        centerStartPoint: startLine * scale,
        centerEndPoint: endLine * scale);
  }

  Offset? findIntersectionOfLines(Offset p1, Offset p2, Offset p3, Offset p4) {
    double a1 = p2.dy - p1.dy;
    double b1 = p1.dx - p2.dx;
    double c1 = a1 * p1.dx + b1 * p1.dy;

    double a2 = p4.dy - p3.dy;
    double b2 = p3.dx - p4.dx;
    double c2 = a2 * p3.dx + b2 * p3.dy;

    double denominator = a1 * b2 - a2 * b1;

    if (denominator == 0) {
      return null;
    }

    double intersectX = (b2 * c1 - b1 * c2) / denominator;
    double intersectY = (a1 * c2 - a2 * c1) / denominator;

    return Offset(intersectX, intersectY);
  }

  Pad? checkForPads(Offset offset) {
    for (var comp in component) {
      for (var pad in comp.component.pad) {
        padOffset = Offset(pad.x, pad.y) + comp.position;
        if (offset == padOffset) {
          return pad;
        }
      }
    }
    return null;
  }
}
