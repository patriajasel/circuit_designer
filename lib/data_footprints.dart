// Initializing the Component model
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'text': text.map((e) => e.toJson()).toList(),
        'wires': wire.map((e) => e.toJson()).toList(),
        'pads': pad.map((e) => e.toJson()).toList(),
        'smd': smd.map((e) => e.toJson()).toList(),
        'holes': hole.map((e) => e.toJson()).toList(),
        'circles': circle.map((e) => e.toJson()).toList(),
        'rectangles': rectangle.map((e) => e.toJson()).toList(),
        'polygon': polygon?.toJson(),
      };

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(
      name: json['name'] ?? '',
      text: (json['text'] as List<dynamic>?)
              ?.map((e) => TextElement.fromJson(e))
              .toList() ??
          [],
      wire: (json['wires'] as List<dynamic>?)
              ?.map((e) => Wire.fromJson(e))
              .toList() ??
          [],
      pad: (json['pads'] as List<dynamic>?)
              ?.map((e) => Pad.fromJson(e))
              .toList() ??
          [],
      smd: (json['smd'] as List<dynamic>?)
              ?.map((e) => Smd.fromJson(e))
              .toList() ??
          [],
      hole: (json['holes'] is List
          ? (json['holes'] as List<dynamic>)
              .map((e) => Hole.fromJson(e))
              .toList()
          : json['holes'] != null
              ? [Hole.fromJson(json['hole'])]
              : []),
      circle: (json['circles'] is List
          ? (json['circles'] as List<dynamic>)
              .map((e) => Circle.fromJson(e))
              .toList()
          : json['circles'] != null
              ? [Circle.fromJson(json['circle'])]
              : []),
      rectangle: (json['rectangles'] as List<dynamic>?)
              ?.map((e) => Rectangle.fromJson(e))
              .toList() ??
          [],
      polygon:
          json['polygons'] != null ? Polygon.fromJson(json['polygon']) : null,
    );
  }
}

// Initializing TextElement model
class TextElement {
  final double x;
  final double y;
  final double size;
  final double layer;
  final String text;

  TextElement(
      {required this.x,
      required this.y,
      required this.size,
      required this.layer,
      required this.text});

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'size': size,
        'layer': layer,
        'text': text,
      };

  factory TextElement.fromJson(Map<String, dynamic> json) {
    return TextElement(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      size: json['size'].toDouble(),
      layer: json['layer'].toDouble(),
      text: json['text'],
    );
  }
}

// Initializing Wire model
class Wire {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double width;
  final double layer;

  Wire(
      {required this.x1,
      required this.y1,
      required this.x2,
      required this.y2,
      required this.width,
      required this.layer});

  Map<String, dynamic> toJson() => {
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
        'width': width,
        'layer': layer,
      };

  factory Wire.fromJson(Map<String, dynamic> json) {
    return Wire(
      x1: json['x1'].toDouble(),
      y1: json['y1'].toDouble(),
      x2: json['x2'].toDouble(),
      y2: json['y2'].toDouble(),
      width: json['width'].toDouble(),
      layer: json['layer'].toDouble(),
    );
  }
}

// Initializing Pad model
class Pad {
  final String name;
  final double x;
  final double y;
  final double drill;
  final String? shape;

  Pad(
      {required this.name,
      required this.x,
      required this.y,
      required this.drill,
      this.shape});

  Map<String, dynamic> toJson() => {
        'name': name,
        'x': x,
        'y': y,
        'drill': drill,
        'shape': shape,
      };

  factory Pad.fromJson(Map<String, dynamic> json) {
    return Pad(
      name: json['name'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      drill: json['drill'].toDouble(),
      shape: json['shape'],
    );
  }
}

// Initializing Smd model
class Smd {
  final String name;
  final double x;
  final double y;
  final double dx;
  final double dy;
  final double layer;

  Smd(
      {required this.name,
      required this.x,
      required this.y,
      required this.dx,
      required this.dy,
      required this.layer});

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'dx': dx,
        'dy': dy,
        'layer': layer,
      };

  factory Smd.fromJson(Map<String, dynamic> json) {
    return Smd(
        name: json['name'] ?? '',
        x: json['x'].toDouble(),
        y: json['y'].toDouble(),
        dx: json['dx'].toDouble(),
        dy: json['dy'].toDouble(),
        layer: json['layer'].toDouble());
  }
}

// Initializing Hole model
class Hole {
  final double x;
  final double y;
  final double drill;

  Hole({
    required this.x,
    required this.y,
    required this.drill,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'drill': drill,
      };

  factory Hole.fromJson(Map<String, dynamic> json) {
    return Hole(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      drill: json['drill'].toDouble(),
    );
  }
}

// Initializing Circle model
class Circle {
  final double x;
  final double y;
  final double radius;
  final double width;
  final double layer;

  Circle(
      {required this.x,
      required this.y,
      required this.radius,
      required this.width,
      required this.layer});

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'radius': radius,
        'width': width,
        'layer': layer,
      };

  factory Circle.fromJson(Map<String, dynamic> json) {
    return Circle(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      radius: json['radius'].toDouble(),
      width: json['width'].toDouble(),
      layer: json['layer'].toDouble(),
    );
  }
}

// Initializing Circle model
class Rectangle {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double layer;

  Rectangle(
      {required this.x1,
      required this.y1,
      required this.x2,
      required this.y2,
      required this.layer});

  Map<String, dynamic> toJson() => {
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
        'layer': layer,
      };

  factory Rectangle.fromJson(Map<String, dynamic> json) {
    return Rectangle(
      x1: json['x1'].toDouble(),
      y1: json['y1'].toDouble(),
      x2: json['x2'].toDouble(),
      y2: json['y2'].toDouble(),
      layer: json['layer'].toDouble(),
    );
  }
}

// Initializing Polygon model
class Polygon {
  final List<Vertex> vertices;
  final double width;
  final double layer;

  Polygon({required this.vertices, required this.width, required this.layer});

  Map<String, dynamic> toJson() => {
        'vertices': vertices,
        'width': width,
        'layer': layer,
      };

  factory Polygon.fromJson(Map<String, dynamic> json) {
    return Polygon(
      vertices: (json['vertex'] as List<dynamic>)
          .map((e) => Vertex.fromJson(e))
          .toList(),
      width: json['width'].toDouble(),
      layer: json['layer'].toDouble(),
    );
  }
}

// Initializing Vertex model for the Polygon
class Vertex {
  final double x;
  final double y;
  final double? curve;

  Vertex({required this.x, required this.y, this.curve});

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'curve': curve,
      };

  factory Vertex.fromJson(Map<String, dynamic> json) {
    return Vertex(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      curve: json['curve'].toDouble(),
    );
  }
}

// Initializing the Package model
class Package {
  final String packageType;
  final List<Component> components;

  Package({required this.packageType, required this.components});

  Map<String, dynamic> toJson() => {
        'packageType': packageType,
        'components': components.map((e) => e.toJson()).toList(),
      };

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      packageType: json['packageType'],
      components: (json['components'] as List<dynamic>)
          .map((e) => Component.fromJson(e))
          .toList(),
    );
  }
}
