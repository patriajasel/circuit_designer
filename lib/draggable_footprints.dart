import 'package:circuit_designer/data_footprints.dart';
import 'package:circuit_designer/footprints_bounding_box.dart';
import 'package:flutter/material.dart';

// This is the class for the footprints that can be dragged.
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

  Map<String, dynamic> toJson() => {
        'component': component.toJson(),
        'position': {'dx': position.dx, 'dy': position.dy},
        'isSelected': isSelected,
        'isHovered': isHovered,
        'boundingBox': boundingBox,
      };

  factory DraggableFootprints.fromJson(Map<String, dynamic> json) {
    return DraggableFootprints(
      component: Component.fromJson(json['component']),
      position: Offset(json['position']['dx'], json['position']['dy']),
      isSelected: json['isSelected'],
      isHovered: json['isHovered'],
      boundingBox: BoundingBox.fromJson(json['boundingBox']),
    );
  }
  
}
