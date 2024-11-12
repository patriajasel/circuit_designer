import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:circuit_designer/line_traces.dart';
import 'package:circuit_designer/outline_carve.dart';
import 'package:path_provider/path_provider.dart';

class GCodeConverter {
  List<List<String>> compiledGcodeCommands = [];
  List<String> gCodeCommands = [];
  List<GCodeLines> gCodeLines = [];
  Offset? arcCenter;
  bool isPad = false;
  bool isLine = false;
  int? indexToRemove;
  double? radius;
  double? cwI;
  double? cwJ;
  List<Arc> arcsToDrill = [];
  List<int> arcsToRemove = [];
  double? currentRadius;

  List<String> convertCanvasToGCode(
      List<Arc> arcs,
      List<ConnectingLines> outlines,
      List<GCodeLines> smdGCodes,
      double scale) {
    arcsToDrill.addAll(arcs);

    // Prepare gCodeLines based on outlines
    for (var outline in outlines) {
      disperseOutLines(outline);
    }

    for (int i = 0; i < outlines.length; i++) {
      // Start point of the GCode path
      Offset firstOffset = gCodeLines.first.startOffset / scale;
      Offset currentOffset = firstOffset;

      // Add initial GCode setup commands
      if (i == 0) {
        gCodeCommands.add(gCode("millimeters"));
        gCodeCommands.add(gCode("absolute"));
        gCodeCommands.add("G0 Z10;");
        gCodeCommands.add(gCode("home"));
      }

      gCodeCommands.add("G0 Z10 F1000;");
      gCodeCommands
          .add("${gCode("move")} X${firstOffset.dx} Y${firstOffset.dy}");
      gCodeCommands.add("M3;");
      gCodeCommands.add("G0 Z-0.398 F400;");

      currentOffset = outlines[i].connectingLines.first.leftStartPoint / scale;
      do {
        Offset? newOffset = checkLines(currentOffset, scale) ??
            checkPads(currentOffset, arcs, scale);

        if (newOffset != null) {
          // Check if newOffset is not null before accessing it
          if (isPad == true && isLine == false) {
            arcs.removeAt(indexToRemove!);
            gCodeCommands.add(
                "${gCode("arcCW")} X${newOffset.dx} Y${newOffset.dy} I$cwI J$cwJ");
            currentOffset = newOffset;
          } else if (isLine == true && isPad == false) {
            gCodeLines.removeAt(indexToRemove!);
            gCodeCommands
                .add("${gCode("engrave")} X${newOffset.dx} Y${newOffset.dy}");
            currentOffset = newOffset;
          }
        } else {
          // Handle the case when newOffset is null.
          print("Warning: newOffset is null. Breaking the loop.");
          // or continue; based on your intended behavior
          break;
        }
      } while (currentOffset != firstOffset);
    }

    while (arcsToDrill.isNotEmpty) {
      List<int> arcsToRemove = [];

      for (int i = 0; i < arcsToDrill.length; i++) {
        currentRadius ??= (arcsToDrill[i].radius / 2) / scale;

        gCodeCommands.add("G0 Z10 F1000;");
        gCodeCommands.add("(Drilling)");
        gCodeCommands.add("(${(arcsToDrill[i].radius / 2) / scale})");

        if (((arcsToDrill[i].radius / 2) / scale) == currentRadius) {
          gCodeCommands.add(
              "${gCode("move")} X${(arcsToDrill[i].centerPoint.dx / scale)} Y${arcsToDrill[i].centerPoint.dy / scale};");
          gCodeCommands.add("G0 Z5");
          gCodeCommands.add("G1 Z-1.2 F300");

          arcsToRemove.add(i);
        }
      }

      // Remove items in reverse order to avoid index shifting
      for (var index in arcsToRemove.reversed) {
        arcsToDrill.removeAt(index);
      }

      // Reset arcsToRemove and currentRadius for the next iteration
      arcsToRemove.clear();
      currentRadius = null;
    }

    gCodeCommands.add("G0 Z10;");

    gCodeCommands.add("M5"); // Stop spindle
    gCodeCommands.add("M30"); // End of program

    saveGcodeFile("engrave", gCodeCommands);
    return gCodeCommands;

    // Finalize GCode commands
  }

  void disperseOutLines(ConnectingLines connectingLines) {
    for (var line in connectingLines.connectingLines) {
      gCodeLines.add(GCodeLines(
          startOffset: line.leftStartPoint, endOffset: line.leftEndPoint));
      gCodeLines.add(GCodeLines(
          startOffset: line.rightStartPoint, endOffset: line.rightEndPoint));
    }
  }

  // Command keyword mappings
  String gCode(String keyword) {
    switch (keyword) {
      case "millimeters":
        return "G21;";
      case "absolute":
        return "G90;";
      case "home":
        return "G0 X0 Y0;";
      case "spindleOn":
        return "M3;";
      case "spindleOff":
        return "M5;";
      case "end":
        return "M30;";
      case "move":
        return "G0";
      case "engrave":
        return "G1";
      case "arcCW":
        return "G2";
      case "arcCCW":
        return "G3";
      default:
        return "";
    }
  }

  Offset? checkLines(Offset offset, double scale) {
    for (var line in gCodeLines) {
      if ((line.startOffset.dx / scale) == offset.dx &&
          (line.startOffset.dy / scale) == offset.dy) {
        /* print("This is a match on start point");
        print("Line index at #${gCodeLines.indexOf(line)}");
        print(
            "Matching Values: X: ${line.startOffset.dx / scale} OffsetX: ${offset.dx}");
        print(
            "Matching Values: Y: ${line.startOffset.dy / scale} OffsetY: ${offset.dy}");

        print("Returned Offset is end point: ${line.endOffset / scale}");*/

        isLine = true;
        isPad = false;
        indexToRemove = gCodeLines.indexOf(line);
        return line.endOffset / scale;
      } else if ((line.endOffset.dx / scale) == offset.dx &&
          (line.endOffset.dy / scale) == offset.dy) {
        /*print("This is a match on end point");
        print("Line index at #${gCodeLines.indexOf(line)}");
        print(
            "Matching Values: X: ${line.endOffset.dx / scale} OffsetX: ${offset.dx}");
        print(
            "Matching Values: Y: ${line.endOffset.dy / scale} OffsetY: ${offset.dy}");

        print("Returned Offset is start point: ${line.startOffset / scale}");*/

        isLine = true;
        isPad = false;
        indexToRemove = gCodeLines.indexOf(line);
        return line.startOffset / scale;
      } else {
        print("No match in lines");
      }
    }
    return null;
  }

  Offset? checkPads(Offset offset, List<Arc> arcs, double scale) {
    for (var arc in arcs) {
      if ((arc.startPoint.dx / scale) == offset.dx &&
          (arc.startPoint.dy / scale) == offset.dy) {
        /*print("This is a match on start point");
        print("Arc index at #${arcs.indexOf(arc)}");
        print(
            "Matching Values: X: ${arc.startPoint.dx / scale} OffsetX: ${offset.dx}");
        print(
            "Matching Values: Y: ${arc.startPoint.dy / scale} OffsetY: ${offset.dy}");

        print("Returned Offset is end point: ${arc.endPoint / scale}");*/

        isPad = true;
        isLine = false;
        arcCenter = arc.centerPoint / scale;
        radius = arc.radius / scale;
        indexToRemove = arcs.indexOf(arc);
        calculateIJ(arc.startPoint / scale, arc.endPoint / scale);
        return arc.endPoint / scale;
      } else if ((arc.endPoint.dx / scale) == offset.dx &&
          (arc.endPoint.dy / scale) == offset.dy) {
        /*print("This is a match on end point");
        print("Arc index at #${arcs.indexOf(arc)}");
        print(
            "Matching Values: X: ${arc.endPoint.dx / scale} OffsetX: ${offset.dx}");
        print(
            "Matching Values: Y: ${arc.endPoint.dy / scale} OffsetY: ${offset.dy}");

        print("Returned Offset is start point: ${arc.startPoint / scale}");*/

        isPad = true;
        isLine = false;
        indexToRemove = arcs.indexOf(arc);
        radius = arc.radius / scale;
        calculateIJ(arc.endPoint / scale, arc.startPoint / scale);
        arcCenter = arc.centerPoint / scale;
        return arc.startPoint / scale;
      } else {
        print("No match in arcs");
      }
    }
    return null;
  }

  void calculateIJ(Offset startOffset, Offset endOffset) {
    double xMid = (startOffset.dx + endOffset.dx) / 2;
    double yMid = (startOffset.dy + endOffset.dy) / 2;

    double dx = endOffset.dx - startOffset.dx;
    double dy = endOffset.dy - startOffset.dy;
    double d = sqrt(dx * dx + dy * dy);

    if (radius! < d / 2) {
      throw ArgumentError(
          'Radius is too small to form an arc with these endpoints.');
    }

    double h = sqrt(radius! * radius! - (d / 2) * (d / 2));

    double offsetX = h * (-dy / d);
    double offsetY = h * (dx / d);

    double xCenterCW = xMid + offsetX;
    double yCenterCW = yMid + offsetY;

    //double xCenterCCW = xMid - offsetX;
    //double yCenterCCW = yMid - offsetY;

    double iCW = xCenterCW - startOffset.dx;
    double jCW = yCenterCW - startOffset.dy;

    //double iCCW = xCenterCCW - startOffset.dx;
    //double jCCW = yCenterCCW - startOffset.dy;

    cwI = iCW;
    cwJ = jCW;
  }

  Future<void> saveGcodeFile(
      String fileName, List<String> gcodeCommands) async {
    try {
      // Get the directory to store the file
      Directory directory = await getApplicationDocumentsDirectory();
      String path = directory.path;

      // Create the file with the specified file name
      File gcodeFile = File('$path/$fileName.gcode');

      // Convert the list of strings into a single string with line breaks
      String gcodeContent = gcodeCommands.join('\n');

      // Write the gcode content to the file  a
      await gcodeFile.writeAsString(gcodeContent);

      print("File saved successfully: ${gcodeFile.path}");
    } catch (e) {
      print("Error saving file: $e");
    }
  }
}

    // Debugging: Print lines and pads
    /* for (var line in gCodeLines) {
      print("line #${gCodeLines.indexOf(line)}");
      print("GCode StartPoint: ${line.startOffset / scale}");
      print("GCode EndPoint: ${line.endOffset / scale}");
    }

    for (var arc in arcs) {
      print("pad #${arcs.indexOf(arc)}");
      print("Arc StartPoint: ${arc.startPoint / scale}");
      print("Arc EndPoint: ${arc.endPoint / scale}");
    } */

    /*for (var gCodes in smdGCodes) {
      print(gCodes.startOffset);
      print(gCodes.endOffset);
    } */
