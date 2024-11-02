// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:circuit_designer/canvas_to_gcode.dart';
import 'package:circuit_designer/cnc_controls.dart';
import 'package:circuit_designer/draggable_footprints.dart';
import 'package:circuit_designer/footprints_arcs.dart';
import 'package:circuit_designer/footprints_bounding_box.dart';
import 'package:circuit_designer/line_traces.dart';
import 'package:circuit_designer/outline_carve.dart';
import 'package:circuit_designer/sketch_comp_library.dart';
import 'package:circuit_designer/sketch_footprint_painter.dart';
import 'package:circuit_designer/sketch_menubar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'data_footprints.dart';

class Sketchboard extends StatefulWidget {
  const Sketchboard({super.key});

  @override
  State<Sketchboard> createState() => _SketchboardState();
}

class _SketchboardState extends State<Sketchboard> {
  List<Package> packages = [];
  double canvasWidthInPixels = 25.4 * 2;
  double canvasHeightInPixels = 25.4 * 2;

  int canvasHeightInInches = 2;
  int canvasWidthInInches = 2;

  double scale = 10;

  List<DraggableFootprints> compToDisplay = [];

  DraggableFootprints? selectedFootprint;
  List<Line>? selectedLines;

  bool isTracing = false;
  bool isHorizontal = false;
  bool isVertical = false;
  bool isDiagonal = false;

  bool onHoveredPart = false;
  bool startConnected = false;
  bool endConnected = false;

  bool displayOutline = false;

  Offset? startPoint;
  Offset? temporaryPoint;
  Offset? currentPoint;
  Offset? endPoint;

  List<Line> lines = [];
  FocusNode focusNode = FocusNode();

  List<Arc>? arcs;
  List<ConnectingLines>? outlines;

  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    WindowManager.instance.maximize();
    WindowManager.instance.setMaximizable(true);

    loadJsonFiles();
    focusNode.requestFocus();
    super.initState();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void updateCanvasSize(int height, int width) {
    setState(() {
      canvasHeightInPixels = 25.4 * height.toDouble();
      canvasWidthInPixels = 25.4 * width.toDouble();
      canvasHeightInInches = height;
      canvasWidthInInches = width;
    });
  }

  void updateLineWidth(List<Line> updatedLines) {
    setState(() {
      lines = List.from(updatedLines); // Create a new instance of the list
    });
  }

  void updateListForGCode(
      List<Arc> receivedArcs, List<ConnectingLines> receivedOutlines) {
    arcs = receivedArcs;
    outlines = receivedOutlines;
  }

  Future<void> loadJsonFiles() async {
    const folderPath = 'lib/data/component_libraries/';
    final folder = Directory(folderPath);

    if (await folder.exists()) {
      final files = folder.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final jsonString = await file.readAsString();
          final jsonData = jsonDecode(jsonString);
          final package = Package.fromJson(jsonData);
          setState(() {
            packages.add(package);
          });
        }
      }
    }
  }

  void addToPainterList(DraggableFootprints comp) {
    setState(() {
      compToDisplay.add(comp);
    });
  }

  @override
  Widget build(BuildContext context) {
    MenuActions menuActions = MenuActions();
    Offset position = Offset(canvasWidthInPixels / 2, canvasHeightInPixels / 2);

    return Scaffold(
      body: Shortcuts(
        shortcuts: menuActions.buildShortcuts(),
        child: Actions(
          actions: menuActions.buildActions(),
          child: Focus(
            autofocus: true,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: MenuBar(children: [
                    menuActions.buildFileMenu(),
                    menuActions.buildEditMenu(),
                    menuActions.buildSettingsMenu(context, updateCanvasSize,
                        canvasHeightInInches, canvasWidthInInches),
                    menuActions.buildHelpMenu()
                  ]),
                ),
                Expanded(
                  child: Row(
                    children: [
                      CompAndPartsSection(
                        packages: packages,
                        footprints: compToDisplay,
                        position: position,
                        passComp: addToPainterList,
                        lines: lines,
                        rebuildState: rebuildState,
                        updateLines: updateLineWidth,
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            LayoutBuilder(builder: (context, constraints) {
                              double interval = constraints.maxWidth / 10;
                              int divisions = (interval / 20).round();
                              if (divisions < 1) divisions = 1;

                              return Container(
                                color: Colors.black,
                                child: Center(
                                  child: KeyboardListener(
                                    focusNode: focusNode,
                                    autofocus: true,
                                    onKeyEvent: _onKeyEvent,
                                    child: GestureDetector(
                                      onTapDown: _onTapDown,
                                      onPanStart: ((details) {
                                        setState(() {
                                          selectedFootprint =
                                              getComponentAtPosition(
                                                  details.localPosition /
                                                      scale);
                                          selectedFootprint?.isSelected = true;

                                          selectedLines = getLinesAtPosition(
                                              details.localPosition / scale);

                                          if (selectedLines != null) {
                                            for (var line in selectedLines!) {
                                              line.isSelected = true;

                                              // Determine if the start or end is closer to the tap and store that information
                                              double distanceToStart =
                                                  ((details.localPosition /
                                                              scale) -
                                                          line.start)
                                                      .distance;
                                              double distanceToEnd =
                                                  ((details.localPosition /
                                                              scale) -
                                                          line.end)
                                                      .distance;

                                              // Set moveStart to true if start is closer, otherwise false
                                              line.moveStart = distanceToStart <
                                                  distanceToEnd;
                                            }
                                          }
                                        });
                                      }),
                                      onPanUpdate: ((details) {
                                        if (selectedFootprint != null) {
                                          Offset newPosition =
                                              (selectedFootprint!.position) +
                                                  (details.delta / scale);

                                          newPosition = clampPosition(
                                              newPosition,
                                              canvasWidthInPixels,
                                              canvasHeightInPixels);
                                          setState(() {
                                            selectedFootprint!.position =
                                                newPosition;
                                          });
                                        }

                                        if (selectedLines != null) {
                                          setState(() {
                                            for (var line in selectedLines!) {
                                              if (line.moveStart == true) {
                                                // Move the start point
                                                line.start = line.start +
                                                    (details.delta / scale);

                                                line.start = clampPosition(
                                                    line.start,
                                                    canvasWidthInPixels,
                                                    canvasHeightInPixels);

                                                if (compToDisplay.isNotEmpty) {
                                                  DraggableFootprints?
                                                      hoveredFootprint =
                                                      getComponentAtPosition(
                                                          details.localPosition /
                                                              scale);
                                                  if (hoveredFootprint !=
                                                      null) {
                                                    Offset? newLinePosition =
                                                        getPartsOfFootprint(
                                                            details.localPosition /
                                                                scale,
                                                            hoveredFootprint);

                                                    if (newLinePosition !=
                                                        null) {
                                                      line.start =
                                                          newLinePosition +
                                                              hoveredFootprint
                                                                  .position;
                                                      line.startConnected =
                                                          true;

                                                      //print("New Line Position: $newLinePosition");
                                                    }
                                                  } else {
                                                    //print("No footprint hovered");

                                                    line.startConnected = false;
                                                  }
                                                }
                                              } else if (line.moveStart ==
                                                  false) {
                                                // Move the start point
                                                line.end = line.end +
                                                    (details.delta / scale);

                                                line.end = clampPosition(
                                                    line.end,
                                                    canvasWidthInPixels,
                                                    canvasHeightInPixels);

                                                if (compToDisplay.isNotEmpty) {
                                                  DraggableFootprints?
                                                      hoveredFootprint =
                                                      getComponentAtPosition(
                                                          details.localPosition /
                                                              scale);
                                                  if (hoveredFootprint !=
                                                      null) {
                                                    Offset? newLinePosition =
                                                        getPartsOfFootprint(
                                                            details.localPosition /
                                                                scale,
                                                            hoveredFootprint);

                                                    if (newLinePosition !=
                                                        null) {
                                                      line.end =
                                                          newLinePosition +
                                                              hoveredFootprint
                                                                  .position;
                                                      line.endConnected = true;
                                                      //print("New Line Position: $newLinePosition");
                                                    }
                                                  } else {
                                                    //print("No footprint hovered");

                                                    line.endConnected = false;
                                                  }
                                                }
                                              }
                                            }
                                          });
                                        }
                                      }),
                                      onPanEnd: ((details) {
                                        setState(() {
                                          selectedFootprint?.isSelected = false;
                                          selectedFootprint = null;

                                          if (selectedLines != null) {
                                            List<Line> tempSelectedLines =
                                                List.from(selectedLines!);

                                            for (var line
                                                in tempSelectedLines) {
                                              line.isSelected = false;
                                              line.moveStart =
                                                  null; // Reset the moveStart flag after the interaction ends
                                            }

                                            // Now clear the list after the iteration
                                            selectedLines!.clear();
                                          }
                                          // Instead of modifying selectedLines while iterating, collect changes first
                                        });
                                      }),
                                      child: MouseRegion(
                                        onHover: _onMouseMove,
                                        child: Container(
                                          height: canvasHeightInPixels * scale,
                                          width: canvasWidthInPixels * scale,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: Colors.purple, width: 4),
                                          ),
                                          child: RepaintBoundary(
                                            key: _globalKey,
                                            child: CustomPaint(
                                              painter: FootPrintPainter(
                                                  compToDisplay,
                                                  scale,
                                                  displayOutline,
                                                  lines,
                                                  currentPoint,
                                                  startPoint,
                                                  updateListForGCode),
                                              size: Size(
                                                  canvasWidthInPixels * scale,
                                                  canvasHeightInPixels * scale),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            Positioned(
                                right: 0,
                                child: SizedBox(
                                  height: 500,
                                  width: 100,
                                  child: Card(
                                      elevation: 0,
                                      color: Colors.transparent,
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero),
                                      child: ListView.builder(
                                          itemCount: 6,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 20),
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  onPressed: () {
                                                    getFunction(
                                                      index,
                                                    );
                                                  },
                                                  icon: Icon(
                                                    getIcon(index),
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                          })),
                                )),
                            Positioned(
                              right: 20.0,
                              bottom: 20.0,
                              child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      displayOutline = true;
                                    });
                                    /*Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const CncControls()));*/

                                    GCodeConverter().convertCanvasToGCode(
                                        arcs!, outlines!, scale);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0))),
                                  child: const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.memory,
                                        ),
                                        Text("Proceed to PCB Making")
                                      ],
                                    ),
                                  )),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isHorizontallyAligned(Line line) {
    return (line.start.dy - line.end.dy).abs() <
        1e-3; // A small threshold to account for floating point precision
  }

  bool isVerticallyAligned(Line line) {
    return (line.start.dx - line.end.dx).abs() < 1e-3;
  }

  void getFunction(int index) {
    switch (index) {
      case 0:
        homeButton();
        break;
      case 1:
        zoomInButton();
        break;
      case 2:
        zoomOutButton();
        break;
      case 3:
        deleteButton();
        break;
      case 4:
        traceButton();
        break;
      case 5:
        outlineButton();
        break;
    }
  }

  IconData getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.zoom_in;
      case 2:
        return Icons.zoom_out;
      case 3:
        return Icons.delete;
      case 4:
        return Icons.draw;
      case 5:
        return Icons.polyline;
      default:
        return Icons.face;
    }
  }

  void homeButton() {
    //print("home button pressed");
  }

  void zoomInButton() {
    //print("zoom in button pressed");
    setState(() {
      scale += 1;
      // print(canvasHeightInPixels * scale);
      //print(canvasWidthInPixels * scale);
    });
  }

  void zoomOutButton() {
    //print("zoom out button pressed");
    setState(() {
      if (scale > 1.0) {
        scale -= 1;
        //  print(canvasHeightInPixels * scale);
        //  print(canvasWidthInPixels * scale);
      }
    });
  }

  void deleteButton() {
    List<DraggableFootprints> itemsToRemove = [];
    List<Line> linesToRemove = [];

    for (int i = 0; i < compToDisplay.length; i++) {
      if (compToDisplay[i].isSelected == true) {
        itemsToRemove.add(compToDisplay[i]);
      }
    }

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].isSelected == true) {
        linesToRemove.add(lines[i]);
      }
    }

    setState(() {
      compToDisplay
          .removeWhere((footprint) => itemsToRemove.contains(footprint));
      lines.removeWhere((lines) => linesToRemove.contains(lines));
    });
  }

  void traceButton() {
    if (isTracing) {
      setState(() {
        isTracing = !isTracing;
        //  print(isTracing);
      });
    } else {
      setState(() {
        isTracing = !isTracing;
        startPoint = null;
        endPoint = null;
        //  print(isTracing);
      });
    }
  }

  void outlineButton() {
    setState(() {
      displayOutline = !displayOutline;
    });
  }

  DraggableFootprints? getComponentAtPosition(Offset localPosition) {
    for (var draggableFootprint in compToDisplay) {
      BoundingBox boundingBox = draggableFootprint.boundingBox;

      // Get the position of the footprint and calculate its bounding box
      double minX = (draggableFootprint.position.dx + boundingBox.minX);
      double maxX = (draggableFootprint.position.dx + boundingBox.maxX);
      double minY = (draggableFootprint.position.dy + boundingBox.minY);
      double maxY = (draggableFootprint.position.dy + boundingBox.maxY);

      // Check if the localPosition is within the bounding box
      if (localPosition.dx >= minX &&
          localPosition.dx <= maxX &&
          localPosition.dy >= minY &&
          localPosition.dy <= maxY) {
        return draggableFootprint;
      }
    }
    return null;
  }

  Offset? getPartsOfFootprint(
      Offset localPosition, DraggableFootprints footprintSelected) {
    const double hitboxSize = 1.0;
    bool padSelected = false, smdSelected = false;
    Offset position = localPosition - footprintSelected.position;

    for (var pads in footprintSelected.component.pad) {
      if ((position.dx - pads.x).abs() < hitboxSize &&
          (position.dy - pads.y).abs() < hitboxSize) {
        padSelected = true;
        return Offset(pads.x, pads.y);
      }
    }

    for (var smd in footprintSelected.component.smd) {
      if ((position.dx - smd.x).abs() < hitboxSize &&
          (position.dy - smd.y).abs() < hitboxSize) {
        smdSelected = true;
        return Offset(smd.x, smd.y);
      }
    }

    if (!padSelected && !smdSelected) {
      // print("No parts selected at: x ${position.dx}, y ${position.dy}");
      return null;
    }

    return null;
  }

  List<Line>? getLinesAtPosition(Offset localPosition) {
    List<Line> getLines = [];
    const double hitboxSize =
        2.0; // Distance in pixels to detect line proximity

    for (var line in lines) {
      // Check proximity to start point
      if ((localPosition.dx - line.start.dx).abs() < hitboxSize &&
          (localPosition.dy - line.start.dy).abs() < hitboxSize) {
        getLines.add(line);
      }

      // Check proximity to end point
      if ((localPosition.dx - line.end.dx).abs() < hitboxSize &&
          (localPosition.dy - line.end.dy).abs() < hitboxSize) {
        getLines.add(line);
      }
    }

    // Return the list of found lines or an empty list if none were found
    return getLines.isNotEmpty ? getLines : null;
  }

  Offset clampPosition(Offset position, double maxWidth, double maxHeight) {
    final double clampedX = position.dx.clamp(0.0, maxWidth);
    final double clampedY = position.dy.clamp(0.0, maxHeight);
    return Offset(clampedX, clampedY);
  }

  void _onTapDown(TapDownDetails details) {
    if (isTracing) {
      // Convert mouse position to unscaled canvas coordinates
      Offset unscaledPosition = details.localPosition / scale;

      if (startPoint == null) {
        setState(() {
          if (onHoveredPart) {
            startPoint = temporaryPoint;
            startConnected = true;
          } else {
            startPoint = unscaledPosition;
            startConnected = false;
          }
        });
      } else if (startPoint != null && endPoint == null) {
        if (isHorizontal && !onHoveredPart) {
          setState(() {
            endPoint = Offset(unscaledPosition.dx, startPoint!.dy);
          });
        } else if (isVertical && !onHoveredPart) {
          setState(() {
            endPoint = Offset(startPoint!.dx, unscaledPosition.dy);
          });
        } else if (isDiagonal && !onHoveredPart) {
          // Set the endPoint for diagonal move (45-degree line in any direction)
          setState(() {
            double deltaX = unscaledPosition.dx - startPoint!.dx;
            double deltaY = unscaledPosition.dy - startPoint!.dy;

            // Find the smaller delta to maintain a 45-degree line
            double minDelta =
                deltaX.abs() < deltaY.abs() ? deltaX.abs() : deltaY.abs();

            // Adjust dx and dy to maintain the correct diagonal direction
            double adjustedDx = deltaX.sign * minDelta; // Keep the sign of dx
            double adjustedDy = deltaY.sign * minDelta; // Keep the sign of dy

            endPoint = Offset(
                startPoint!.dx + adjustedDx, startPoint!.dy + adjustedDy);
          });
        } else {
          setState(() {
            if (onHoveredPart) {
              endPoint = temporaryPoint;
              endConnected = true;
            } else {
              endPoint = unscaledPosition;
              endConnected = false;
            }
          });
        }
      }

      if (startPoint != null && endPoint != null) {
        setState(() {
          // Create a new line
          Line newLine = Line(
              name: "Traces ${lines.length}",
              start: startPoint!,
              end: endPoint!,
              isSelected: false,
              isHovered: false,
              thickness: 1.0,
              startConnected: startConnected,
              endConnected: endConnected);

          lines.add(newLine);

          startPoint = endPoint;
          endPoint = null;

          startConnected = false;
          endConnected = false;

          // print("Line added and line points calculated");
        });
      }
    } else {
      setState(() {
        selectedFootprint =
            getComponentAtPosition(details.localPosition / scale);

        if (selectedFootprint != null) {
          selectedFootprint?.isSelected = !selectedFootprint!.isSelected;
        }

        selectedLines = getLinesAtPosition(details.localPosition / scale);
        if (selectedLines != null) {
          for (var line in selectedLines!) {
            line.isSelected = true;
          }
        }
      });
    }
  }

  void _onMouseMove(PointerHoverEvent event) {
    if (isTracing) {
      // Convert mouse position to unscaled canvas coordinates
      Offset unscaledPosition = event.localPosition / scale;

      DraggableFootprints? hoveredFootprint =
          getComponentAtPosition(unscaledPosition);
      Offset? newLinePosition;

      if (hoveredFootprint != null) {
        newLinePosition =
            getPartsOfFootprint(unscaledPosition, hoveredFootprint);
        onHoveredPart = true;

        if (newLinePosition != null) {
          temporaryPoint = newLinePosition + hoveredFootprint.position;
        }
      } else {
        // print("No footprint hovered");
        onHoveredPart = false;
      }

      if (endPoint == null && startPoint != null) {
        if (isHorizontal) {
          setState(() {
            currentPoint = Offset(unscaledPosition.dx, startPoint!.dy);
          });
        } else if (isVertical) {
          setState(() {
            currentPoint = Offset(startPoint!.dx, unscaledPosition.dy);
          });
        } else if (isDiagonal) {
          // Move diagonally (allowing for all directions)
          setState(() {
            double deltaX = unscaledPosition.dx - startPoint!.dx;
            double deltaY = unscaledPosition.dy - startPoint!.dy;

            // Ensure diagonal movement in both directions (45 degrees)
            double minDelta =
                deltaX.abs() < deltaY.abs() ? deltaX.abs() : deltaY.abs();

            // Adjust dx and dy to maintain the correct diagonal direction
            double adjustedDx = deltaX.sign * minDelta; // Keep the sign of dx
            double adjustedDy = deltaY.sign * minDelta; // Keep the sign of dy

            currentPoint = Offset(
                startPoint!.dx + adjustedDx, startPoint!.dy + adjustedDy);
          });
        } else {
          setState(() {
            currentPoint = unscaledPosition;
          });
        }
      }
    } else {
      setState(() {
        startPoint = null;
        currentPoint = null;
      });
    }
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyH) {
        setState(() {
          isHorizontal = !isHorizontal; // Toggle horizontal lock
          // If vertical or diagonal lock is active, disable them
          if (isHorizontal) {
            isVertical = false;
            isDiagonal = false;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.keyV) {
        setState(() {
          isVertical = !isVertical; // Toggle vertical lock
          // If horizontal or diagonal lock is active, disable them
          if (isVertical) {
            isHorizontal = false;
            isDiagonal = false;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        setState(() {
          isDiagonal = !isDiagonal; // Toggle diagonal lock
          // If horizontal or vertical lock is active, disable them
          if (isDiagonal) {
            isHorizontal = false;
            isVertical = false;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        // Stop drawing when Escape key is pressed
        setState(() {
          isTracing = false; // Disable further drawing
          currentPoint = null; // Stop following the mouse pointer
          startPoint = null;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.keyT) {
        setState(() {
          isTracing = true;
        });
      }
    }
  }

  void rebuildState() {
    setState(() {});
  }
}
