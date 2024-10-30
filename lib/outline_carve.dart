import 'package:flutter/material.dart';

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
