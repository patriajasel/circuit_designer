import 'package:circuit_designer/data_footprints.dart';

class BoundingBox {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  BoundingBox({required this.minX, required this.minY, required this.maxX, required this.maxY});

  static BoundingBox calculate(Component component) {
    // Initialize bounding box with extreme values
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    // Function to update the bounding box with new coordinates
    void updateBounds(double x, double y) {
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // Iterate over each sub-component to update bounding box

    // Process TextElements
    for (var text in component.text) {
      updateBounds(text.x, text.y);
    }

    // Process Wires
    for (var wire in component.wire) {
      updateBounds(wire.x1, wire.y1);
      updateBounds(wire.x2, wire.y2);
    }

    // Process Pads
    for (var pad in component.pad) {
      // Assuming the pad is circular, update based on the pad's position and radius
      double radius = pad.drill / 2;
      updateBounds(pad.x - radius, pad.y - radius);
      updateBounds(pad.x + radius, pad.y + radius);
    }

    // Process SMDs
    for (var smd in component.smd) {
      updateBounds(smd.x, smd.y);
      updateBounds(smd.x + smd.dx, smd.y + smd.dy);
    }

    // Process Holes
    for (var hole in component.hole) {
      double radius = hole.drill / 2;
      updateBounds(hole.x - radius, hole.y - radius);
      updateBounds(hole.x + radius, hole.y + radius);
    }

    // Process Circles
    for (var circle in component.circle) {
      updateBounds(circle.x - circle.radius, circle.y - circle.radius);
      updateBounds(circle.x + circle.radius, circle.y + circle.radius);
    }

    // Process Rectangles
    for (var rect in component.rectangle) {
      updateBounds(rect.x1, rect.y1);
      updateBounds(rect.x2, rect.y2);
    }

    // Process Polygons
    if (component.polygon != null) {
      for (var vertex in component.polygon!.vertices) {
        updateBounds(vertex.x, vertex.y);
      }
    }

    // Return the final bounding box
    return BoundingBox(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }
}
