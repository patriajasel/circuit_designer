// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:circuit_designer/draggable_footprints.dart';
import 'package:circuit_designer/line_traces.dart';
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
  double canvasWidthInPixels = 200.0;
  double canvasHeightInPixels = 200.0;

  int canvasHeightInInches = 2;
  int canvasWidthInInches = 2;

  double scale = 1;

  List<DraggableFootprints> compToDisplay = [];

  DraggableFootprints? selectedFootprint;

  bool isTracing = false;
  bool isHorizontal = false;
  bool isVertical = false;
  bool isDiagonal = false;

  Offset? startPoint;
  Offset? currentPoint;
  Offset? endPoint;

  List<Line> lines = [];

  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    WindowManager.instance.setMinimumSize(const Size(1920, 1080));
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
      canvasHeightInPixels = 100.0 * double.parse(height.toString());
      canvasWidthInPixels = 100.0 * double.parse(width.toString());
      canvasHeightInInches = height;
      canvasWidthInInches = width;
    });
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
    CompAndPartsSection sideSection = CompAndPartsSection(
        passComp: addToPainterList,
        position: Offset(canvasWidthInPixels / 2, canvasHeightInPixels / 2));

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
                      sideSection.sideSection(packages),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: double.infinity,
                              color: Colors.grey.shade800,
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
                                                details.localPosition / scale);
                                      });
                                    }),
                                    onPanUpdate: ((details) {
                                      if (selectedFootprint != null) {
                                        setState(() {
                                          // Calculate new position
                                          Offset newPosition =
                                              (selectedFootprint!.position) +
                                                  (details.delta / scale);

                                          // Clamp position within the container's boundaries
                                          newPosition = clampPosition(
                                            newPosition,
                                            canvasWidthInPixels,
                                            canvasHeightInPixels,
                                          );

                                          // Update the selected component's position
                                          selectedFootprint!.position =
                                              newPosition;
                                        });
                                      }
                                    }),
                                    onPanEnd: ((details) {
                                      setState(() {
                                        selectedFootprint = null;
                                      });
                                    }),
                                    child: MouseRegion(
                                      onHover: _onMouseMove,
                                      child: Container(
                                        height: canvasHeightInPixels * scale,
                                        width: canvasWidthInPixels * scale,
                                        color: Colors.white,
                                        child: CustomPaint(
                                          painter: FootPrintPainter(
                                              compToDisplay,
                                              scale,
                                              isTracing,
                                              lines,
                                              currentPoint,
                                              startPoint),
                                          size: Size(canvasWidthInPixels,
                                              canvasHeightInPixels),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                                right: 0,
                                child: SizedBox(
                                  height: 400,
                                  width: 100,
                                  child: Card(
                                      color: Colors.grey.shade800,
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero),
                                      child: ListView.builder(
                                          itemCount: 5,
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
                                                    getFunction(index);
                                                  },
                                                  icon: Icon(
                                                    getIcon(index),
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                          })),
                                ))
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

  void getFunction(int index) {
    switch (index) {
      case 0:
        homeButton();
      case 1:
        zoomInButton();
      case 2:
        zoomOutButton();
      case 3:
        deleteButton();
      case 4:
        traceButton();
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
      default:
        return Icons.face;
    }
  }

  void homeButton() {
    print("home button pressed");
  }

  void zoomInButton() {
    print("zoom in button pressed");
    setState(() {
      scale += 0.2;
      print(canvasHeightInPixels * scale);
      print(canvasWidthInPixels * scale);
    });
  }

  void zoomOutButton() {
    print("zoom out button pressed");
    setState(() {
      if (scale > 1.0) {
        scale -= 0.2;
        print(canvasHeightInPixels * scale);
        print(canvasWidthInPixels * scale);
      }
    });
  }

  void deleteButton() {
    print("delete button pressed");
  }

  void traceButton() {
    if (isTracing) {
      setState(() {
        isTracing = !isTracing;
        print(isTracing);
      });
    } else {
      setState(() {
        isTracing = !isTracing;
        startPoint = null;
        endPoint = null;
        print(isTracing);
      });
    }
  }

  DraggableFootprints? getComponentAtPosition(Offset localPosition) {
    for (var draggableFootprint in compToDisplay) {
      // Define a hitbox around each component's position (for simplicity, using a rectangle)
      const hitboxSize = 10.0;
      if ((localPosition.dx - draggableFootprint.position.dx).abs() <
              hitboxSize &&
          (localPosition.dy - draggableFootprint.position.dy).abs() <
              hitboxSize) {
        return draggableFootprint;
      }
    }
    return null;
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
          startPoint = unscaledPosition;
        });
      } else if (startPoint != null && endPoint == null) {
        if (isHorizontal) {
          setState(() {
            endPoint = Offset(unscaledPosition.dx, startPoint!.dy);
          });
        } else if (isVertical) {
          setState(() {
            endPoint = Offset(startPoint!.dx, unscaledPosition.dy);
          });
        } else if (isDiagonal) {
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
            endPoint = unscaledPosition;
          });
        }
      }

      if (startPoint != null && endPoint != null) {
        setState(() {
          lines.add(Line(start: startPoint!, end: endPoint!));
          startPoint = endPoint;
          endPoint = null;
          print("lines added");
        });
      }
    }
  }

  void _onMouseMove(PointerHoverEvent event) {
    if (isTracing) {
      // Convert mouse position to unscaled canvas coordinates
      Offset unscaledPosition = event.localPosition / scale;

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
}
