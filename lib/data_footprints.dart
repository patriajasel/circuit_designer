// Define the Component model
class Component {
  final String name;
  final List<TextElement> text;
  final List<Wire> wire;
  final List<Pad> pad;

  Component(
      {required this.name,
      required this.text,
      required this.wire,
      required this.pad});

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
