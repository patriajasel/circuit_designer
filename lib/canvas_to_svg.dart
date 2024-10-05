import 'dart:io';

import 'package:circuit_designer/data_footprints.dart';
import 'package:circuit_designer/draggable_footprints.dart';
import 'package:circuit_designer/line_traces.dart';

class SVGConvert {
  String canvasToSVG(List<DraggableFootprints> footprints, List<Line> lines) {
    StringBuffer svgBuffer = StringBuffer();

    svgBuffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">');

    for (int i = 0; i < footprints.length; i++) {
      for (int j = 0; j < footprints[i].component.pad.length; j++) {
        svgBuffer.writeln(padToSvg(footprints[i].component.pad[j]));
      }
    }

    for (int i = 0; i < footprints.length; i++) {
      for (int j = 0; j < footprints[i].component.smd.length; j++) {
        svgBuffer.writeln(smdToSvg(footprints[i].component.smd[j]));
      }
    }

    for (var line in lines) {
      svgBuffer.writeln(lineToSvg(line));
    }

    svgBuffer.writeln('</svg>');

    return svgBuffer.toString();
  }

  void saveSVGToFile(String svg, String fileName) async {
    final file = File(fileName);
    await file.writeAsString(svg);
  }

  String padToSvg(Pad pad) {
    return '<circle cx="${pad.x}" cy="${pad.y}" r="${pad.drill}" stroke="black" fill="none" />';
  }

  String smdToSvg(Smd smd) {
    return '<rect x="${smd.x}" y="${smd.y}" width="${smd.dx}" height="${smd.dy}" stroke="black" fill="none" />';
  }

  String lineToSvg(Line line) {
    return '<line x1="${line.start.dx}" y1="${line.start.dy}" x2="${line.end.dx}" y2="${line.end.dy}" stroke="black" stroke-width="1" />';
  }
}
