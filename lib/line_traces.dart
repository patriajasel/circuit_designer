import 'package:flutter/material.dart';

// This is the class for traces of lines
class Line {
  String name;
  Offset start;
  Offset end;
  bool isSelected;
  bool isHovered;
  double thickness;

  bool? moveStart;

  Line(
      {required this.name,
      required this.start,
      required this.end,
      required this.isSelected,
      required this.isHovered,
      this.moveStart,
      required this.thickness});
}
