import 'package:circuit_designer/data_footprints.dart';

class BoundingBox {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  BoundingBox(
      {required this.minX,
      required this.minY,
      required this.maxX,
      required this.maxY});

  static BoundingBox calculate(Component component) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    void updateBounds(double x, double y) {
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // For Texts Bounding Box
    for (var text in component.text) {
      updateBounds(text.x, text.y);
    }

    // For Wires Bounding Box
    for (var wire in component.wire) {
      updateBounds(wire.x1, wire.y1);
      updateBounds(wire.x2, wire.y2);
    }

    // For Pads Bounding Box
    for (var pad in component.pad) {
      double radius = pad.drill / 2;
      updateBounds(pad.x - radius, pad.y - radius);
      updateBounds(pad.x + radius, pad.y + radius);
    }

    // For SMD Bounding Box
    for (var smd in component.smd) {
      updateBounds(smd.x, smd.y);
      updateBounds(smd.x + smd.dx, smd.y + smd.dy);
    }

    // For Holes Bounding Box
    for (var hole in component.hole) {
      double radius = hole.drill / 2;
      updateBounds(hole.x - radius, hole.y - radius);
      updateBounds(hole.x + radius, hole.y + radius);
    }

    // For Circle Bounding Box
    for (var circle in component.circle) {
      updateBounds(circle.x - circle.radius, circle.y - circle.radius);
      updateBounds(circle.x + circle.radius, circle.y + circle.radius);
    }

    // For Rectangles Bounding Box
    for (var rect in component.rectangle) {
      updateBounds(rect.x1, rect.y1);
      updateBounds(rect.x2, rect.y2);
    }

    // For POlygons Bounding Box
    if (component.polygon != null) {
      for (var vertex in component.polygon!.vertices) {
        updateBounds(vertex.x, vertex.y);
      }
    }

    // Returning the final bounding box
    return BoundingBox(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }
}
