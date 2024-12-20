import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:circuit_designer/line_traces.dart';
import 'package:circuit_designer/outline_carve.dart';
import 'package:intl/intl.dart';

class GCodeConverter {
  List<List<String>> compiledGcodeCommands = [];
  List<String> gCodeCommands = [];
  List<GCodeLines> gCodeLines = [];
  Offset? arcCenter;
  bool isPad = false;
  bool isLine = false;
  bool isSmd = false;
  int? indexToRemove;
  double? radius;
  double? cwI;
  double? cwJ;
  List<Arc> arcsToDrill = [];
  List<int> arcsToRemove = [];
  double? currentRadius;

  Future<void> convertOutlineToGCode(
      List<Arc> arcs,
      List<ConnectingLines> outlines,
      List<SMDOutline> smdOutlines,
      double scale,
      String filePath,
      String fileName) async {
    // Prepare gCodeLines based on outlines
    for (var outline in outlines) {
      disperseOutLines(outline);
    }

    for (var smdLines in smdOutlines) {
      disperseSmdOutlines(smdLines, scale);
    }

    for (int i = 0; i < outlines.length; i++) {
      // Start point of the GCode path
      Offset firstOffset = gCodeLines.first.startOffset / scale;
      Offset currentOffset = firstOffset;

      // Add initial GCode setup commands
      if (i == 0) {
        gCodeCommands.add(gCode("millimeters"));
        gCodeCommands.add(gCode("absolute"));
        gCodeCommands.add(gCode("home"));
      }

      gCodeCommands.add("G0 Z10.0;");
      gCodeCommands
          .add("${gCode("move")} X${firstOffset.dx} Y${firstOffset.dy}");
      gCodeCommands.add("M3;");
      gCodeCommands.add("G0 Z-0.1;");

      currentOffset = outlines[i].connectingLines.first.leftStartPoint / scale;
      do {
        Offset? newOffset = checkLines(currentOffset, scale) ??
            checkPads(currentOffset, arcs, scale);

        if (newOffset != null) {
          // Check if newOffset is not null before accessing it
          if (isPad == true && isLine == false) {
            arcs.removeAt(indexToRemove!);
            gCodeCommands.add(
                "${gCode("arcCW")} X${NumberFormat("#.####").format(newOffset.dx)} Y${NumberFormat("#.####").format(newOffset.dy)} I${NumberFormat("#.####").format(cwI)} J${NumberFormat("#.####").format(cwJ)}");
            currentOffset = newOffset;
          } else if (isLine == true && isPad == false) {
            gCodeLines.removeAt(indexToRemove!);
            gCodeCommands.add(
                "${gCode("engrave")} X${NumberFormat("#.####").format(newOffset.dx)} Y${NumberFormat("#.####").format(newOffset.dy)} F1000");
            currentOffset = newOffset;
          } else if (isSmd == true && isPad == false && isLine == false) {}
        } else {
          // Handle the case when newOffset is null.
          print("Warning: newOffset is null. Breaking the loop.");
          // or continue; based on your intended behavior
          break;
        }
      } while (currentOffset != firstOffset);
    }

    gCodeCommands.add("G0 Z10.0;");

    gCodeCommands.add("M5"); // Stop spindle
    gCodeCommands.add("M30"); // End of program

    if (fileName.endsWith('-design.cc')) {
      fileName = fileName.replaceAll('-design.cc', '');
    }

    print("Trimmed FileName GCode: $fileName");

    await saveGcodeFile(
      filePath,
      "$fileName-carve",
      gCodeCommands,
    );
  }

  Future<void> arcHoleToGCode(
      List<Arc> arcs, double scale, String filePath, String fileName) async {
    Set<double> drillSizes = {};

    for (var arc in arcs) {
      drillSizes.add((arc.radius / scale) / 2);
    }

    List<double> uniqueDrillSizes = drillSizes.toList();

    for (int i = 0; i < uniqueDrillSizes.length; i++) {
      gCodeCommands.clear();

      gCodeCommands.add("(Drilling)");
      gCodeCommands.add("(${uniqueDrillSizes[i]})");
      gCodeCommands.add(gCode("millimeters"));
      gCodeCommands.add(gCode("absolute"));
      gCodeCommands.add("G0 Z10;");
      gCodeCommands.add(gCode("home"));

      for (var arc in arcs) {
        if (uniqueDrillSizes[i] == (arc.radius / scale) / 2) {
          gCodeCommands.add("G0 Z5");
          gCodeCommands.add(
              '${gCode("move")} X${(arc.centerPoint.dx / scale)} Y${(arc.centerPoint.dy / scale)}');

          gCodeCommands.add("G0 Z5");
          gCodeCommands.add("M3;");
          gCodeCommands.add("G1 Z-1.2 F1000");
        }
      }

      gCodeCommands.add("G0 Z50 F1000;");
      gCodeCommands.add("G0 X0 Y0 F1000;");

      gCodeCommands.add("M5");
      gCodeCommands.add("M30");

      if (fileName.endsWith('-design.cc')) {
        fileName = fileName.replaceAll('-design.cc', '');
      }

      print("Trimmed FileName GCode: $fileName");

      // save file inside here
      await saveGcodeFile(filePath, "$fileName-drill($i)", gCodeCommands);
    }
  }

  void disperseOutLines(ConnectingLines connectingLines) {
    for (var line in connectingLines.connectingLines) {
      gCodeLines.add(GCodeLines(
          startOffset: line.leftStartPoint, endOffset: line.leftEndPoint));
      gCodeLines.add(GCodeLines(
          startOffset: line.rightStartPoint, endOffset: line.rightEndPoint));
    }
  }

  void disperseSmdOutlines(SMDOutline smdOutline, double scale) {
    Offset leftLine = smdOutline.connectedLeftLine;
    Offset rightLine = smdOutline.connectedRightLine;
    Offset topLeft = smdOutline.topLeft;
    Offset topRight = smdOutline.topRight;
    Offset bottomLeft = smdOutline.bottomLeft;
    Offset bottomRight = smdOutline.bottomRight;

    if (leftLine.dx == topLeft.dx) {
      double distance1 = sqrt(
          pow(topLeft.dx - leftLine.dx, 2) + pow(topLeft.dy - leftLine.dy, 2));
      double distance2 = sqrt(pow(bottomLeft.dx - leftLine.dx, 2) +
          pow(bottomLeft.dy - leftLine.dy, 2));

      if (distance2 < distance1) {
        gCodeLines
            .add(GCodeLines(startOffset: leftLine, endOffset: bottomLeft));
        gCodeLines
            .add(GCodeLines(startOffset: bottomLeft, endOffset: bottomRight));
        gCodeLines
            .add(GCodeLines(startOffset: bottomRight, endOffset: topRight));
        gCodeLines.add(GCodeLines(startOffset: topRight, endOffset: topLeft));
        gCodeLines.add(GCodeLines(startOffset: topLeft, endOffset: rightLine));
      } else {
        gCodeLines.add(GCodeLines(startOffset: leftLine, endOffset: topLeft));
        gCodeLines.add(GCodeLines(startOffset: topLeft, endOffset: topRight));
        gCodeLines
            .add(GCodeLines(startOffset: topRight, endOffset: bottomRight));
        gCodeLines
            .add(GCodeLines(startOffset: bottomRight, endOffset: bottomLeft));
        gCodeLines
            .add(GCodeLines(startOffset: bottomLeft, endOffset: rightLine));
      }
    } else if (leftLine.dx == topRight.dx) {
      double distance1 = sqrt(pow(topRight.dx - leftLine.dx, 2) +
          pow(topRight.dy - leftLine.dy, 2));
      double distance2 = sqrt(pow(bottomRight.dx - leftLine.dx, 2) +
          pow(bottomRight.dy - leftLine.dy, 2));

      if (distance2 < distance1) {
        gCodeLines
            .add(GCodeLines(startOffset: leftLine, endOffset: bottomRight));
        gCodeLines
            .add(GCodeLines(startOffset: bottomRight, endOffset: bottomLeft));
        gCodeLines.add(GCodeLines(startOffset: bottomLeft, endOffset: topLeft));
        gCodeLines.add(GCodeLines(startOffset: topLeft, endOffset: topRight));
        gCodeLines.add(GCodeLines(startOffset: topRight, endOffset: rightLine));
      } else {
        gCodeLines.add(GCodeLines(startOffset: leftLine, endOffset: topRight));
        gCodeLines.add(GCodeLines(startOffset: topRight, endOffset: topLeft));
        gCodeLines.add(GCodeLines(startOffset: topLeft, endOffset: bottomLeft));
        gCodeLines
            .add(GCodeLines(startOffset: bottomLeft, endOffset: bottomRight));
        gCodeLines
            .add(GCodeLines(startOffset: bottomRight, endOffset: rightLine));
      }
    } else if (leftLine.dy == topRight.dy) {
      double distance1 = sqrt(pow(topRight.dx - leftLine.dx, 2) +
          pow(topRight.dy - leftLine.dy, 2));
      double distance2 = sqrt(
          pow(topLeft.dx - leftLine.dx, 2) + pow(topLeft.dy - leftLine.dy, 2));

      if (distance2 < distance1) {
        gCodeLines.add(GCodeLines(startOffset: leftLine, endOffset: topLeft));
        gCodeLines.add(GCodeLines(startOffset: topLeft, endOffset: bottomLeft));
        gCodeLines
            .add(GCodeLines(startOffset: bottomLeft, endOffset: bottomRight));
        gCodeLines
            .add(GCodeLines(startOffset: bottomRight, endOffset: topRight));
        gCodeLines.add(GCodeLines(startOffset: topRight, endOffset: rightLine));
      } else {
        gCodeLines.add(GCodeLines(startOffset: leftLine, endOffset: topRight));
        gCodeLines
            .add(GCodeLines(startOffset: topRight, endOffset: bottomRight));
        gCodeLines
            .add(GCodeLines(startOffset: bottomRight, endOffset: bottomLeft));
        gCodeLines.add(GCodeLines(startOffset: bottomLeft, endOffset: topLeft));
        gCodeLines.add(GCodeLines(startOffset: topLeft, endOffset: rightLine));
      }
    } else if (leftLine.dy == bottomRight.dy) {
      double distance1 = sqrt(pow(bottomRight.dx - leftLine.dx, 2) +
          pow(bottomRight.dy - leftLine.dy, 2));
      double distance2 = sqrt(pow(bottomLeft.dx - leftLine.dx, 2) +
          pow(bottomLeft.dy - leftLine.dy, 2));

      if (distance2 < distance1) {
        gCodeLines
            .add(GCodeLines(startOffset: leftLine, endOffset: bottomLeft));
        gCodeLines.add(GCodeLines(startOffset: bottomLeft, endOffset: topLeft));
        gCodeLines.add(GCodeLines(startOffset: topLeft, endOffset: topRight));
        gCodeLines
            .add(GCodeLines(startOffset: topRight, endOffset: bottomRight));
        gCodeLines
            .add(GCodeLines(startOffset: bottomRight, endOffset: rightLine));
      } else {
        gCodeLines
            .add(GCodeLines(startOffset: leftLine, endOffset: bottomRight));
        gCodeLines
            .add(GCodeLines(startOffset: bottomRight, endOffset: topRight));
        gCodeLines.add(GCodeLines(startOffset: topRight, endOffset: topLeft));
        gCodeLines.add(GCodeLines(startOffset: topLeft, endOffset: bottomLeft));
        gCodeLines
            .add(GCodeLines(startOffset: bottomLeft, endOffset: rightLine));
      }
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
        isLine = true;
        isPad = false;
        indexToRemove = gCodeLines.indexOf(line);
        return line.endOffset / scale;
      } else if ((line.endOffset.dx / scale) == offset.dx &&
          (line.endOffset.dy / scale) == offset.dy) {
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
        isPad = true;
        isLine = false;
        arcCenter = arc.centerPoint / scale;
        radius = arc.radius / scale;
        indexToRemove = arcs.indexOf(arc);
        calculateIJ(arc.startPoint / scale, arc.endPoint / scale);
        return arc.endPoint / scale;
      } else if ((arc.endPoint.dx / scale) == offset.dx &&
          (arc.endPoint.dy / scale) == offset.dy) {
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
      String customPath, String fileName, List<String> gcodeCommands) async {
    try {
      print("FileName GCode: $fileName");
      print("FileName GCode: $customPath");

      // Create the directory within the custom path
      String fullFolderPath = '$customPath/GCode';
      Directory folder = Directory(fullFolderPath);

      // Check if the folder exists, and create it if it doesn't
      if (!folder.existsSync()) {
        await folder.create(recursive: true);
      }

      // Define the full file path
      String filePath = '$fullFolderPath/$fileName.gcode';

      // Convert the list of strings into a single string with line breaks
      String gcodeContent = gcodeCommands.join('\n');

      // Create the file and write the content
      File gcodeFile = File(filePath);
      await gcodeFile.writeAsString(gcodeContent);

      print("File saved successfully: $filePath");
    } catch (e) {
      print("Error saving file: $e");
    }
  }

  List<File> getGCodeFiles(String folderPath) {
    final directory = Directory(folderPath);

    List<FileSystemEntity> entities = directory.listSync();

    List<File> files = entities
        .whereType<File>()
        .where((file) => file.path.endsWith('.gcode'))
        .toList();

    return files;
  }
}
