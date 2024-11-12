import 'dart:math';

import 'package:circuit_designer/line_traces.dart';
import 'package:circuit_designer/outline_carve.dart';
import 'package:flutter/material.dart';

class OutlinePainter extends CustomPainter {
  final List<ConnectingLines> connectingLines;
  final List<Arc> arcs;
  final List<SMDOutline> smdOutlines;
  final double scale;

  OutlinePainter(this.connectingLines, this.arcs, this.scale, this.smdOutlines);

  Offset? previousLeftStart;
  Offset? previousLeftEnd;
  Offset? previousRightStart;
  Offset? previousRightEnd;

  List<GCodeLines>? smdGCode = [];

  @override
  void paint(Canvas canvas, Size size) {
    print("I am here");
    print("Arcs Length: ${arcs.length}");
    if (connectingLines.isNotEmpty) {
      Paint linePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke;

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
      print("Arc is not Empty");
      final paint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      for (var arc in arcs) {
        drawArc(
            arc.startPoint, arc.endPoint, arc.centerPoint, arc.radius, canvas);

        if (arc.startPoint == Offset.zero && arc.endPoint == Offset.zero) {
          canvas.drawCircle(
              arc.centerPoint * scale, (arc.radius * scale) / 2, paint);
        }
      }
    }

    if (smdOutlines.isNotEmpty) {
      for (var smd in smdOutlines) {
        drawSMDs(smd, canvas);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
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
    Offset leftEdgeStart = smdOutline.connectedLeftLine;
    Offset rightEdgeStart = smdOutline.connectedRightLine;
    Offset topLeft = smdOutline.topLeft;
    Offset topRight = smdOutline.topRight;
    Offset bottomLeft = smdOutline.bottomLeft;
    Offset bottomRight = smdOutline.bottomRight;

    final Paint outlinePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    Path outlinePath = Path();

    if (leftEdgeStart.dy == smdOutline.topLeft.dy) {
      // Entry from top edge
      outlinePath.moveTo(leftEdgeStart.dx, leftEdgeStart.dy);
      outlinePath.lineTo(topRight.dx, topRight.dy);
      smdGCode!
          .add(GCodeLines(startOffset: leftEdgeStart, endOffset: topRight));
      outlinePath.lineTo(bottomRight.dx, bottomRight.dy);
      smdGCode!.add(GCodeLines(startOffset: topRight, endOffset: bottomRight));
      outlinePath.lineTo(bottomLeft.dx, bottomLeft.dy);
      smdGCode!
          .add(GCodeLines(startOffset: bottomRight, endOffset: bottomLeft));
      if (leftEdgeStart.dy == rightEdgeStart.dy) {
        outlinePath.lineTo(topLeft.dx, topLeft.dy);
        smdGCode!.add(GCodeLines(startOffset: bottomRight, endOffset: topLeft));
      }
      outlinePath.lineTo(rightEdgeStart.dx, rightEdgeStart.dy);
      smdGCode!
          .add(GCodeLines(startOffset: bottomRight, endOffset: rightEdgeStart));
    } else if (leftEdgeStart.dx == smdOutline.topRight.dx) {
      // Entry from right edge
      outlinePath.moveTo(leftEdgeStart.dx, leftEdgeStart.dy);
      outlinePath.lineTo(bottomRight.dx, bottomRight.dy);
      smdGCode!
          .add(GCodeLines(startOffset: leftEdgeStart, endOffset: bottomRight));
      outlinePath.lineTo(bottomLeft.dx, bottomLeft.dy);
      smdGCode!
          .add(GCodeLines(startOffset: bottomRight, endOffset: bottomLeft));
      outlinePath.lineTo(topLeft.dx, topLeft.dy);
      smdGCode!.add(GCodeLines(startOffset: bottomLeft, endOffset: topLeft));
      if (leftEdgeStart.dx == rightEdgeStart.dx) {
        outlinePath.lineTo(topRight.dx, topRight.dy);
        smdGCode!.add(GCodeLines(startOffset: topLeft, endOffset: bottomLeft));
      }
      outlinePath.lineTo(rightEdgeStart.dx, rightEdgeStart.dy);
      smdGCode!
          .add(GCodeLines(startOffset: bottomLeft, endOffset: rightEdgeStart));
    } else if (leftEdgeStart.dy == smdOutline.bottomRight.dy) {
      // Entry from bottom edge
      outlinePath.moveTo(leftEdgeStart.dx, leftEdgeStart.dy);
      outlinePath.lineTo(bottomLeft.dx, bottomLeft.dy);
      smdGCode!
          .add(GCodeLines(startOffset: leftEdgeStart, endOffset: bottomLeft));
      outlinePath.lineTo(topLeft.dx, topLeft.dy);
      smdGCode!.add(GCodeLines(startOffset: bottomLeft, endOffset: topLeft));
      outlinePath.lineTo(topRight.dx, topRight.dy);
      smdGCode!.add(GCodeLines(startOffset: topLeft, endOffset: topRight));
      if (leftEdgeStart.dy == rightEdgeStart.dy) {
        outlinePath.lineTo(bottomRight.dx, bottomRight.dy);
        smdGCode!
            .add(GCodeLines(startOffset: topRight, endOffset: bottomRight));
      }
      outlinePath.lineTo(rightEdgeStart.dx, rightEdgeStart.dy);
      smdGCode!
          .add(GCodeLines(startOffset: bottomRight, endOffset: rightEdgeStart));
    } else if (leftEdgeStart.dx == smdOutline.bottomLeft.dx) {
      // Entry from left edge
      outlinePath.moveTo(leftEdgeStart.dx, leftEdgeStart.dy);
      outlinePath.lineTo(topLeft.dx, topLeft.dy);
      smdGCode!.add(GCodeLines(startOffset: leftEdgeStart, endOffset: topLeft));
      outlinePath.lineTo(topRight.dx, topRight.dy);
      smdGCode!.add(GCodeLines(startOffset: topLeft, endOffset: topRight));
      outlinePath.lineTo(bottomRight.dx, bottomRight.dy);
      smdGCode!.add(GCodeLines(startOffset: topRight, endOffset: bottomRight));
      if (leftEdgeStart.dx == rightEdgeStart.dx) {
        outlinePath.lineTo(bottomLeft.dx, bottomLeft.dy);
        smdGCode!
            .add(GCodeLines(startOffset: bottomRight, endOffset: bottomLeft));
      }
      outlinePath.lineTo(rightEdgeStart.dx, rightEdgeStart.dy);
      smdGCode!
          .add(GCodeLines(startOffset: bottomLeft, endOffset: rightEdgeStart));
    }

    canvas.drawPath(outlinePath, outlinePaint);
  }
}
