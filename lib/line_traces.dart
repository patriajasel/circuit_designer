import 'package:flutter/material.dart';

// This is the class for traces of lines
class Line {
  String name;
  Offset start;
  Offset end;
  bool isSelected;
  bool isHovered;
  double thickness;
  bool startConnected;
  bool endConnected;

  bool? moveStart;

  Line(
      {required this.name,
      required this.start,
      required this.end,
      required this.isSelected,
      required this.isHovered,
      this.moveStart,
      required this.thickness,
      required this.startConnected,
      required this.endConnected});

  Map<String, dynamic> toJson() => {
        'name': name,
        'start': {'dx': start.dx, 'dy': start.dy},
        'end': {'dx': end.dx, 'dy': end.dy},
        'isSelected': isSelected,
        'isHovered': isHovered,
        'thickness': thickness,
        'startConnected': startConnected,
        'endConnected': endConnected,
        'moveStart': moveStart,
      };

  // fromJson for Line
  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      name: json['name'],
      start: Offset(json['start']['dx'], json['start']['dy']),
      end: Offset(json['end']['dx'], json['end']['dy']),
      isSelected: json['isSelected'],
      isHovered: json['isHovered'],
      thickness: json['thickness'],
      startConnected: json['startConnected'],
      endConnected: json['endConnected'],
      moveStart: json['moveStart'],
    );
  }
}

class GCodeLines {
  Offset startOffset;
  Offset endOffset;

  GCodeLines({required this.startOffset, required this.endOffset});
}
