import 'package:circuit_designer/data_footprints.dart';
import 'package:circuit_designer/footprints_bounding_box.dart';
import 'package:flutter/material.dart';

// Initializing the Draggable Footprints Model
class DraggableFootprints {
  final Component component;
  Offset position;
  bool isSelected;
  bool isHovered;
  final BoundingBox boundingBox;

  DraggableFootprints(
      {required this.component,
      required this.position,
      required this.isSelected,
      required this.isHovered,
      required this.boundingBox});
}
