import 'package:flutter/material.dart';

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
