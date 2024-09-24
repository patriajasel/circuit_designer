// Define the Component model
class Component {
  final String name;
  final List<TextElement> text;
  final List<Wire> wire;
  final List<Pad> pad;
  final List<Smd> smd;
  final List<Hole> hole;
  final List<Circle> circle;
  final List<Rectangle> rectangle;
  final Polygon? polygon;

  Component(
      {required this.name,
      required this.text,
      required this.wire,
      required this.pad,
      required this.smd,
      required this.hole,
      required this.circle,
      required this.rectangle,
      this.polygon});

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(
      name: json['_name'] ?? '',
      text: (json['text'] as List<dynamic>?)
              ?.map((e) => TextElement.fromJson(e))
              .toList() ??
          [],
      wire: (json['wire'] as List<dynamic>?)
              ?.map((e) => Wire.fromJson(e))
              .toList() ??
          [],
      pad: (json['pad'] as List<dynamic>?)
              ?.map((e) => Pad.fromJson(e))
              .toList() ??
          [],
      smd: (json['smd'] as List<dynamic>?)
              ?.map((e) => Smd.fromJson(e))
              .toList() ??
          [],
      hole: (json['hole'] is List
          ? (json['hole'] as List<dynamic>)
              .map((e) => Hole.fromJson(e))
              .toList()
          : json['hole'] != null
              ? [Hole.fromJson(json['hole'])] // Wrap a single object in a list
              : []),
      circle: (json['circle'] is List
          ? (json['circle'] as List<dynamic>)
              .map((e) => Circle.fromJson(e))
              .toList()
          : json['circle'] != null
              ? [
                  Circle.fromJson(json['circle'])
                ] // If it's a single circle, wrap it in a list
              : []),
      rectangle: (json['rectangle'] as List<dynamic>?)
              ?.map((e) => Rectangle.fromJson(e))
              .toList() ??
          [],
      polygon:
          json['polygon'] != null ? Polygon.fromJson(json['polygon']) : null,
    );
  }
}

// Define TextElement model
class TextElement {
  final String x;
  final String y;
  final String size;
  final String layer;
  final String text;

  TextElement(
      {required this.x,
      required this.y,
      required this.size,
      required this.layer,
      required this.text});

  factory TextElement.fromJson(Map<String, dynamic> json) {
    return TextElement(
      x: json['_x'],
      y: json['_y'],
      size: json['_size'],
      layer: json['_layer'],
      text: json['__text'],
    );
  }
}

// Define Wire model
class Wire {
  final String x1;
  final String y1;
  final String x2;
  final String y2;
  final String width;
  final String layer;

  Wire(
      {required this.x1,
      required this.y1,
      required this.x2,
      required this.y2,
      required this.width,
      required this.layer});

  factory Wire.fromJson(Map<String, dynamic> json) {
    return Wire(
      x1: json['_x1'],
      y1: json['_y1'],
      x2: json['_x2'],
      y2: json['_y2'],
      width: json['_width'],
      layer: json['_layer'],
    );
  }
}

// Define Pad model
class Pad {
  final String name;
  final String x;
  final String y;
  final String drill;
  final String? shape;

  Pad(
      {required this.name,
      required this.x,
      required this.y,
      required this.drill,
      this.shape});

  factory Pad.fromJson(Map<String, dynamic> json) {
    return Pad(
      name: json['_name'],
      x: json['_x'],
      y: json['_y'],
      drill: json['_drill'],
      shape: json['_shape'],
    );
  }
}

//Define Smd model
class Smd {
  final String name;
  final String x;
  final String y;
  final String dx;
  final String dy;
  final String layer;

  Smd(
      {required this.name,
      required this.x,
      required this.y,
      required this.dx,
      required this.dy,
      required this.layer});

  factory Smd.fromJson(Map<String, dynamic> json) {
    return Smd(
        name: json['_name'],
        x: json['_x'],
        y: json['_y'],
        dx: json['_dx'],
        dy: json['_dy'],
        layer: json['_layer']);
  }
}

// Define Hole model
class Hole {
  final String x;
  final String y;
  final String drill;

  Hole({
    required this.x,
    required this.y,
    required this.drill,
  });

  factory Hole.fromJson(Map<String, dynamic> json) {
    return Hole(
      x: json['_x'],
      y: json['_y'],
      drill: json['_drill'],
    );
  }
}

// Define Circle model
class Circle {
  final String x;
  final String y;
  final String radius;
  final String width;
  final String layer;

  Circle(
      {required this.x,
      required this.y,
      required this.radius,
      required this.width,
      required this.layer});

  factory Circle.fromJson(Map<String, dynamic> json) {
    return Circle(
      x: json['_x'],
      y: json['_y'],
      radius: json['_radius'],
      width: json['_width'],
      layer: json['_layer'],
    );
  }
}

// Define Circle model
class Rectangle {
  final String x1;
  final String y1;
  final String x2;
  final String y2;
  final String layer;

  Rectangle(
      {required this.x1,
      required this.y1,
      required this.x2,
      required this.y2,
      required this.layer});

  factory Rectangle.fromJson(Map<String, dynamic> json) {
    return Rectangle(
      x1: json['_x1'],
      y1: json['_y1'],
      x2: json['_x2'],
      y2: json['_y2'],
      layer: json['_layer'],
    );
  }
}

// Define Polygon model
class Polygon {
  final List<Vertex> vertices;
  final String width;
  final String layer;

  Polygon({required this.vertices, required this.width, required this.layer});

  factory Polygon.fromJson(Map<String, dynamic> json) {
    return Polygon(
      vertices: (json['vertex'] as List<dynamic>)
          .map((e) => Vertex.fromJson(e))
          .toList(),
      width: json['_width'],
      layer: json['_layer'],
    );
  }
}

// Define Vertex model for the Polygon
class Vertex {
  final String x;
  final String y;
  final String? curve;

  Vertex({required this.x, required this.y, this.curve});

  factory Vertex.fromJson(Map<String, dynamic> json) {
    return Vertex(
      x: json['_x'],
      y: json['_y'],
      curve: json['_curve'],
    );
  }
}

// Define the Package model
class Package {
  final String packageType;
  final List<Component> components;

  Package({required this.packageType, required this.components});

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      packageType: json['packageType'],
      components: (json['components'] as List<dynamic>)
          .map((e) => Component.fromJson(e))
          .toList(),
    );
  }
}
