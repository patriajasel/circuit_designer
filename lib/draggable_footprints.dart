import 'package:circuit_designer/data_footprints.dart';
import 'package:flutter/material.dart';

// Initializing the Draggable Footprints Model
class DraggableFootprints {
  final Component component;
  Offset position;
  bool isSelected;
  bool isHovered;

  DraggableFootprints(
      {required this.component,
      required this.position,
      required this.isSelected,
      required this.isHovered});
}
