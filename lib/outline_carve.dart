import 'package:flutter/material.dart';

class OverallOutline {
  List<ConnectingLines> connectedLines;
  List<SMDOutline> smdOutline;
  List<Arc> arcs;

  OverallOutline(
      {required this.connectedLines,
      required this.smdOutline,
      required this.arcs});
}

class ConnectingLines {
  List<Outlines> connectingLines;

  ConnectingLines({required this.connectingLines});
}

class Outlines {
  Offset leftStartPoint;
  Offset leftEndPoint;
  Offset rightStartPoint;
  Offset rightEndPoint;
  Offset centerStartPoint;
  Offset centerEndPoint;

  Outlines(
      {required this.leftStartPoint,
      required this.leftEndPoint,
      required this.rightStartPoint,
      required this.rightEndPoint,
      required this.centerStartPoint,
      required this.centerEndPoint});
}

class SMDOutline {
  Offset topLeft;
  Offset topRight;
  Offset bottomLeft;
  Offset bottomRight;
  Offset connectedLeftLine;
  Offset connectedRightLine;

  SMDOutline(
      {required this.topLeft,
      required this.topRight,
      required this.bottomLeft,
      required this.bottomRight,
      required this.connectedLeftLine,
      required this.connectedRightLine});
}

class Arc {
  Offset startPoint;
  Offset endPoint;
  Offset centerPoint;
  double radius;

  Arc(
      {required this.startPoint,
      required this.endPoint,
      required this.centerPoint,
      required this.radius});
}
