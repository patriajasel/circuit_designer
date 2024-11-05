import 'dart:math';

import 'package:circuit_designer/data_footprints.dart';
import 'package:circuit_designer/draggable_footprints.dart';
import 'package:circuit_designer/footprints_arcs.dart';
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
  final Function(List<Arc>, List<ConnectingLines>) passLists;

  FootPrintPainter(this.component, this.scale, this.displayOutline, this.lines,
      this.currentPoint, this.startPoint, this.passLists);

  bool isLineIntersect = false;
  bool isLineEqual = false;

  Offset? previousLeftStart;
  Offset? previousLeftEnd;
  Offset? previousRightStart;
  Offset? previousRightEnd;

  Offset? padOffset;
  Offset? smdOffset;

  double lengthChange = 0.1;

  List<Outlines> outlines = [];
  List<ConnectingLines> connectingLines = [];
  List<Arc> arcs = [];
  List<SMDOutline> smds = [];

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
          ..strokeWidth = 2.0 * scale
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
      if (lines.isNotEmpty) {
        for (var line in lines) {
          // Looping through all of the lines

          Offset endLine = line.end * scale;
          Offset startLine = line.start * scale;
          double lineThickness = (line.thickness / 2) * scale;

          if (line.startConnected && !line.endConnected) {
            Pad? pad = checkForPads(line.start);
            Smd? smd = checkForSMD(line.start);

            if (pad != null && smd == null) {
              Outlines outline = getPadOutlines(
                  padOffset!, pad.drill * scale, lineThickness, endLine, false);

              Arc arc = Arc(
                  startPoint: outline.leftStartPoint,
                  endPoint: outline.rightStartPoint,
                  centerPoint: padOffset! * scale,
                  radius: pad.drill * scale);

              arcs.add(arc);
              outlines.add(outline);
            } else if (smd != null && pad != null) {
              // This means that the component is either a square pad or a rectangle pad
              Outlines? smdLine = getSMDLines(smd, startLine / scale,
                  endLine / scale, lineThickness, canvas, false);

              outlines.add(smdLine!);

              SMDOutline? smdOutline = getSMDOutline(
                  smdLine.leftStartPoint, smdLine.rightStartPoint, smd);

              smds.add(smdOutline!);

              Arc smdArc = Arc(
                  startPoint: Offset.zero,
                  endPoint: Offset.zero,
                  centerPoint: Offset(pad.x, pad.y) + smdOffset!,
                  radius: pad.drill);
              arcs.add(smdArc);
            } else if (smd != null && pad == null) {
              Outlines? smdLine = getSMDLines(smd, startLine / scale,
                  endLine / scale, lineThickness, canvas, false);

              outlines.add(smdLine!);

              SMDOutline? smdOutline = getSMDOutline(
                  smdLine.leftStartPoint, smdLine.rightStartPoint, smd);

              smds.add(smdOutline!);
            }
          } else if (!line.startConnected && !line.endConnected) {
            Outlines outline =
                getLines(startLine / scale, endLine / scale, lineThickness);

            outlines.add(outline);
          } else if (line.endConnected && !line.startConnected) {
            Pad? pad = checkForPads(line.end);
            Smd? smd = checkForSMD(line.end);
            if (pad != null && smd == null) {
              Outlines outline = getPadOutlines(padOffset!, pad.drill * scale,
                  lineThickness, startLine, true);

              Arc arc = Arc(
                  startPoint: outline.rightEndPoint,
                  endPoint: outline.leftEndPoint,
                  centerPoint: padOffset! * scale,
                  radius: pad.drill * scale);

              outlines.add(outline);
              arcs.add(arc);
            } else if (smd != null && pad != null) {
              Outlines? smdOutline = getSMDLines(smd, endLine / scale,
                  startLine / scale, lineThickness, canvas, true);

              outlines.add(smdOutline!);

              Arc smdArc = Arc(
                  startPoint: Offset.zero,
                  endPoint: Offset.zero,
                  centerPoint: Offset(pad.x, pad.y) + smdOffset!,
                  radius: pad.drill);
              arcs.add(smdArc);
            } else if (smd != null && pad == null) {
              Outlines? smdLine = getSMDLines(smd, startLine / scale,
                  endLine / scale, lineThickness, canvas, true);

              outlines.add(smdLine!);

              SMDOutline? smdOutline = getSMDOutline(
                  smdLine.leftStartPoint, smdLine.rightStartPoint, smd);

              smds.add(smdOutline!);
            }

            connectingLines
                .add(ConnectingLines(connectingLines: List.from(outlines)));
            outlines.clear();
          } else if (line.startConnected && line.endConnected) {
            Pad? pad1 = checkForPads(line.start);
            Outlines outline1 = getPadOutlines(
                padOffset!, pad1!.drill * scale, lineThickness, endLine, false);

            Arc arc1 = Arc(
                startPoint: outline1.leftStartPoint,
                endPoint: outline1.rightStartPoint,
                centerPoint: padOffset! * scale,
                radius: pad1.drill * scale);
            arcs.add(arc1);

            Pad? pad2 = checkForPads(line.end);
            Outlines outline2 = getPadOutlines(padOffset!, pad2!.drill * scale,
                lineThickness, startLine, true);

            Arc arc2 = Arc(
                startPoint: outline2.rightEndPoint,
                endPoint: outline2.leftEndPoint,
                centerPoint: padOffset! * scale,
                radius: pad2.drill * scale);
            arcs.add(arc2);

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

      passLists(arcs, connectingLines);
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

  Outlines getPadOutlines(Offset padCenter, double padRadius,
      double lineThickness, Offset notConnectedPoint, bool isEnd) {
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

  checkForSMD(Offset offset) {
    for (var comp in component) {
      for (var smd in comp.component.smd) {
        smdOffset = Offset(smd.x, smd.y) + comp.position;
        if (offset == smdOffset) {
          return smd;
        }
      }
    }
  }

  double getLineAngle(Offset start, Offset end) {
    // Calculate the differences in x and y coordinates
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;

    // Use atan2 to calculate the angle in radians
    double angleInRadians = atan2(dy, dx);

    // Optionally convert the angle to degrees if needed
    double angleInDegrees = angleInRadians * (180 / pi);

    return angleInDegrees;
  }

  Outlines? getSMDLines(Smd smd, Offset connected, Offset notConnected,
      double lineThickness, Canvas canvas, bool isEnd) {
    double smdHeight = smd.dx / 2;
    double smdWidth = smd.dy / 2;
    Offset smdCenter = Offset(smd.x, smd.y);

    // Corners of the SMD
    Offset topLeft =
        Offset(smdCenter.dx - smdWidth, smdCenter.dy - smdHeight) + smdOffset!;
    Offset topRight =
        Offset(smdCenter.dx + smdWidth, smdCenter.dy - smdHeight) + smdOffset!;
    Offset bottomLeft =
        Offset(smdCenter.dx - smdWidth, smdCenter.dy + smdHeight) + smdOffset!;
    Offset bottomRight =
        Offset(smdCenter.dx + smdWidth, smdCenter.dy + smdHeight) + smdOffset!;

    double lineAngle = getLineAngle(connected, notConnected);

    // Helper function to return the outline for the given points
    Outlines getOutlines(Offset leftStart, Offset leftEnd, Offset rightStart,
        Offset rightEnd, Offset centerStart, Offset centerEnd) {
      return isEnd
          ? Outlines(
              leftStartPoint: rightEnd,
              leftEndPoint: rightStart,
              rightStartPoint: leftEnd,
              rightEndPoint: leftStart,
              centerStartPoint: centerStart,
              centerEndPoint: notConnected,
            )
          : Outlines(
              leftStartPoint: leftStart,
              leftEndPoint: leftEnd,
              rightStartPoint: rightStart,
              rightEndPoint: rightEnd,
              centerStartPoint: centerStart,
              centerEndPoint: notConnected,
            );
    }

    // Based on the angle, adjust the start and end points
    switch (lineAngle.toInt()) {
      case 0:
        // Horizontal line (angle = 0 degrees)
        Offset centerLine = Offset(topRight.dx, connected.dy) * scale;
        Offset leftLineStart =
            Offset(topRight.dx * scale, (connected.dy * scale) + lineThickness);
        Offset rightLineStart =
            Offset(topRight.dx * scale, (connected.dy * scale) - lineThickness);
        Offset leftLineEnd = Offset(notConnected.dx, leftLineStart.dy);
        Offset rightLineEnd = Offset(notConnected.dx, rightLineStart.dy);

        return getOutlines(leftLineStart, leftLineEnd, rightLineStart,
            rightLineEnd, centerLine, notConnected);

      case 90:
        // Vertical line (angle = 90 degrees)
        Offset centerLine = Offset(connected.dx, bottomRight.dy) * scale;
        Offset leftLineStart = Offset(
            (connected.dx * scale) - lineThickness, bottomRight.dy * scale);
        Offset rightLineStart = Offset(
            (connected.dx * scale) + lineThickness, bottomRight.dy * scale);
        Offset leftLineEnd = Offset(leftLineStart.dx, notConnected.dy * scale);
        Offset rightLineEnd =
            Offset(rightLineStart.dx, notConnected.dy * scale);

        return getOutlines(leftLineStart, leftLineEnd, rightLineStart,
            rightLineEnd, centerLine, notConnected);

      case 180:
        // Horizontal line (angle = 180 degrees, opposite direction)
        Offset centerLine = Offset(bottomLeft.dx, connected.dy) * scale;
        Offset leftLineStart = Offset(
            bottomLeft.dx * scale, (connected.dy * scale) - lineThickness);
        Offset rightLineStart = Offset(
            bottomLeft.dx * scale, (connected.dy * scale) + lineThickness);
        Offset leftLineEnd = Offset(notConnected.dx * scale, leftLineStart.dy);
        Offset rightLineEnd =
            Offset(notConnected.dx * scale, rightLineStart.dy);

        return getOutlines(leftLineStart, leftLineEnd, rightLineStart,
            rightLineEnd, centerLine, notConnected);

      case -90:
        // Vertical line (angle = -90 degrees, opposite direction)
        Offset centerLine = Offset(connected.dx, topLeft.dy) * scale;
        Offset leftLineStart =
            Offset((connected.dx * scale) + lineThickness, topLeft.dy * scale);
        Offset rightLineStart =
            Offset((connected.dx * scale) - lineThickness, topLeft.dy * scale);
        Offset leftLineEnd = Offset(leftLineStart.dx, notConnected.dy * scale);
        Offset rightLineEnd =
            Offset(rightLineStart.dx, notConnected.dy * scale);

        return getOutlines(leftLineStart, leftLineEnd, rightLineStart,
            rightLineEnd, centerLine, notConnected);

      default:
        return null; // Handle any unsupported angles
    }
  }

  SMDOutline? getSMDOutline(Offset leftStart, Offset rightStart, Smd smd) {
    double smdHeight = smd.dx / 2;
    double smdWidth = smd.dy / 2;
    Offset smdCenter = Offset(smd.x, smd.y);

    // Corners of the SMD
    Offset topLeft =
        Offset(smdCenter.dx - smdWidth, smdCenter.dy - smdHeight) + smdOffset!;
    Offset topRight =
        Offset(smdCenter.dx + smdWidth, smdCenter.dy - smdHeight) + smdOffset!;
    Offset bottomLeft =
        Offset(smdCenter.dx - smdWidth, smdCenter.dy + smdHeight) + smdOffset!;
    Offset bottomRight =
        Offset(smdCenter.dx + smdWidth, smdCenter.dy + smdHeight) + smdOffset!;

    return SMDOutline(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
        connectedLeftLine: leftStart,
        connectedRightLine: rightStart);
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
}
