import 'dart:math';
import 'dart:ui';

import 'package:circuit_designer/data_footprints.dart';
import 'package:circuit_designer/draggable_footprints.dart';
import 'package:circuit_designer/line_traces.dart';
import 'package:circuit_designer/outline_carve.dart';
import 'package:flutter/material.dart';

class OutlineCalculations {
  final List<DraggableFootprints> footprints;
  final List<Line> lines;
  final double scale;
  final Function(
          List<Arc>, List<ConnectingLines>, List<SMDOutline>, List<GCodeLines>)
      passLists;

  Offset? previousLeftStart;
  Offset? previousLeftEnd;
  Offset? previousRightStart;
  Offset? previousRightEnd;

  bool isLineIntersect = false;
  bool isLineEqual = false;

  Offset? padOffset;
  Offset? smdOffset;

  List<ConnectingLines> connectingLines = [];
  List<Outlines> outlines = [];
  List<Arc> arcs = [];
  List<SMDOutline> smds = [];
  List<GCodeLines> smdGCode = [];

  OutlineCalculations(
      {required this.footprints,
      required this.lines,
      required this.scale,
      required this.passLists});

  // This method is for checking is a line is connected to a pad.
  Pad? checkForPads(Offset offset) {
    for (var comp in footprints) {
      for (var pad in comp.component.pad) {
        padOffset = Offset(pad.x, pad.y) + comp.position;
        if (offset == padOffset) {
          return pad;
        }
      }
    }
    return null;
  }

  // This method is for checking is a line is connected to an smd.
  Smd? checkForSMD(Offset offset) {
    for (var comp in footprints) {
      for (var smd in comp.component.smd) {
        smdOffset = Offset(smd.x, smd.y) + comp.position;
        if (offset == smdOffset) {
          return smd;
        }
      }
    }
    return null;
  }

  // This method is for calculating the edge of a circle to match the lines connected to it.
  Offset calculateCircleEdgePoint(
      Offset padOffset, double padRadius, double angle) {
    return Offset(padOffset.dx + padRadius * cos(angle),
        padOffset.dy + padRadius * sin(angle));
  }

  // This method is for checking the intersection of two lines whether they intersected already or not.
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

  // This method is for getting the angle of the lines.
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

  // This method is for calculating the outline of the pad along with the lines connected to it
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

  // This method is for calculating the lines that are not connected to a pad or smd.
  // This method is for lines that are just connected to another line.
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

  void calculateOutlines() {
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

            outlines.add(outline);

            Arc arc = Arc(
                startPoint: outline.leftStartPoint,
                endPoint: outline.rightStartPoint,
                centerPoint: padOffset! * scale,
                radius: pad.drill * scale);

            arcs.add(arc);
          } else if (smd != null) {
            Outlines outline = getSMDLines(lineThickness, startLine, endLine,
                Offset(smd.x, smd.y) + (smdOffset! * scale), smd);
            outlines.add(outline);

            SMDOutline smdOutline = getSMDOutline(
                smd,
                outline.leftStartPoint,
                outline.rightStartPoint,
                Offset(smd.x, smd.y) + (smdOffset! * scale),
                scale);

            smds.add(smdOutline);
          }
        } else if (!line.startConnected && !line.endConnected) {
          Outlines outline =
              getLines(startLine / scale, endLine / scale, lineThickness);

          outlines.add(outline);
        } else if (line.endConnected && !line.startConnected) {
          Pad? pad = checkForPads(line.end);
          Smd? smd = checkForSMD(line.end);

          if (pad != null && smd == null) {
            Outlines outline = getPadOutlines(
                padOffset!, pad.drill * scale, lineThickness, startLine, true);
            outlines.add(outline);

            Arc arc = Arc(
                startPoint: outline.rightEndPoint,
                endPoint: outline.leftEndPoint,
                centerPoint: padOffset! * scale,
                radius: pad.drill * scale);

            arcs.add(arc);
          } else if (smd != null) {
            Outlines outline = getSMDLines(lineThickness, startLine, endLine,
                Offset(smd.x, smd.y) + (smdOffset! * scale), smd);

            SMDOutline smdOutline = getSMDOutline(
                smd,
                outline.leftStartPoint,
                outline.rightStartPoint,
                Offset(smd.x, smd.y) + (smdOffset! * scale),
                scale);

            smds.add(smdOutline);
            outlines.add(outline);
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
          Outlines outline2 = getPadOutlines(
              padOffset!, pad2!.drill * scale, lineThickness, startLine, true);

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
    }

    passLists(arcs, connectingLines, smds, smdGCode);
  }

  Outlines getSMDLines(
    double thickness,
    Offset lineStart,
    Offset lineEnd,
    Offset smdCenter,
    Smd smd,
  ) {
    final double lineThickness = thickness;
    final Offset direction = (lineEnd - smdCenter).normalize();
    final perpendicularOffset =
        Offset(-direction.dy, direction.dx) * lineThickness;

    final rect = Rect.fromCenter(
        center: smdCenter, width: smd.dx * scale, height: smd.dy * scale);

    final Offset leftEdgeStart = _getSquareEdgeIntersection(
        rect,
        smdCenter + perpendicularOffset,
        lineEnd + perpendicularOffset,
        smdCenter);
    final Offset rightEdgeStart = _getSquareEdgeIntersection(
        rect,
        smdCenter - perpendicularOffset,
        lineEnd - perpendicularOffset,
        smdCenter);

    return Outlines(
        leftStartPoint: leftEdgeStart,
        leftEndPoint: lineEnd + perpendicularOffset,
        rightStartPoint: rightEdgeStart,
        rightEndPoint: lineEnd - perpendicularOffset,
        centerStartPoint: lineStart,
        centerEndPoint: lineEnd);
  }

  SMDOutline getSMDOutline(Smd smd, Offset leftStart, Offset rightStart,
      Offset smdCenter, double scale) {
    final rect = Rect.fromCenter(
        center: smdCenter, width: smd.dx * scale, height: smd.dy * scale);

    final Offset topLeft = rect.topLeft;
    final Offset topRight = rect.topRight;
    final Offset bottomRight = rect.bottomRight;
    final Offset bottomLeft = rect.bottomLeft;

    if (leftStart.dy == rect.top) {
      // Entry from top edge
      smdGCode.add(GCodeLines(startOffset: leftStart, endOffset: topRight));
      smdGCode.add(GCodeLines(startOffset: topRight, endOffset: bottomRight));
      smdGCode.add(GCodeLines(startOffset: bottomRight, endOffset: bottomLeft));
      smdGCode.add(GCodeLines(startOffset: bottomLeft, endOffset: topLeft));
      smdGCode.add(GCodeLines(startOffset: topLeft, endOffset: rightStart));
    } else if (leftStart.dx == rect.right) {
      // Entry from right edge
      smdGCode.add(GCodeLines(startOffset: leftStart, endOffset: bottomRight));
      smdGCode.add(GCodeLines(startOffset: bottomRight, endOffset: bottomLeft));
      smdGCode.add(GCodeLines(startOffset: bottomLeft, endOffset: topLeft));
      smdGCode.add(GCodeLines(startOffset: topLeft, endOffset: bottomLeft));
      smdGCode.add(GCodeLines(startOffset: bottomLeft, endOffset: rightStart));
    } else if (leftStart.dy == rect.bottom) {
      // Entry from bottom edge
      smdGCode.add(GCodeLines(startOffset: leftStart, endOffset: bottomLeft));
      smdGCode.add(GCodeLines(startOffset: bottomLeft, endOffset: topLeft));
      smdGCode.add(GCodeLines(startOffset: topLeft, endOffset: topRight));
      smdGCode.add(GCodeLines(startOffset: topRight, endOffset: bottomRight));
      smdGCode.add(GCodeLines(startOffset: bottomRight, endOffset: rightStart));
    } else if (leftStart.dx == rect.left) {
      // Entry from left edge
      smdGCode.add(GCodeLines(startOffset: leftStart, endOffset: topLeft));
      smdGCode.add(GCodeLines(startOffset: topLeft, endOffset: topRight));
      smdGCode.add(GCodeLines(startOffset: topRight, endOffset: bottomRight));
      smdGCode.add(GCodeLines(startOffset: bottomRight, endOffset: bottomLeft));
      smdGCode.add(GCodeLines(startOffset: bottomLeft, endOffset: rightStart));
    }

    return SMDOutline(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
        connectedLeftLine: leftStart,
        connectedRightLine: rightStart);
  }

  Offset _getSquareEdgeIntersection(
      Rect square, Offset lineStart, Offset lineEnd, Offset smdCenter) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;

    List<Offset> intersections = [];

    // Left edge
    if (dx != 0) {
      double t = (square.left - lineStart.dx) / dx;
      if (t >= 0 && t <= 1) {
        final intersect = Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);
        if (intersect.dy >= square.top && intersect.dy <= square.bottom) {
          intersections.add(intersect);
        }
      }
    }

    // Right edge
    if (dx != 0) {
      double t = (square.right - lineStart.dx) / dx;
      if (t >= 0 && t <= 1) {
        final intersect = Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);
        if (intersect.dy >= square.top && intersect.dy <= square.bottom) {
          intersections.add(intersect);
        }
      }
    }

    // Top edge
    if (dy != 0) {
      double t = (square.top - lineStart.dy) / dy;
      if (t >= 0 && t <= 1) {
        final intersect = Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);
        if (intersect.dx >= square.left && intersect.dx <= square.right) {
          intersections.add(intersect);
        }
      }
    }

    // Bottom edge
    if (dy != 0) {
      double t = (square.bottom - lineStart.dy) / dy;
      if (t >= 0 && t <= 1) {
        final intersect = Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);
        if (intersect.dx >= square.left && intersect.dx <= square.right) {
          intersections.add(intersect);
        }
      }
    }

    // Return the closest intersection to the square center
    intersections.sort(
        (a, b) => (a - smdCenter).distance.compareTo((b - smdCenter).distance));
    return intersections.isNotEmpty ? intersections.first : lineStart;
  }
}

extension on Offset {
  Offset normalize() {
    final double length = distance;
    return length == 0 ? Offset.zero : this / length;
  }
}
