import 'package:flutter/material.dart';

class Line {
  String name;
  Offset start;
  Offset end;
  bool isSelected;
  bool isHovered;
  double thickness;

  // Add this field to track which point was clicked (start or end)
  bool? moveStart;

  Line({
    required this.name,
    required this.start,
    required this.end,
    required this.isSelected,
    required this.isHovered,
    this.moveStart,
    required this.thickness // Nullable at first
  });
}
