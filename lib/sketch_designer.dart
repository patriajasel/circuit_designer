// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:circuit_designer/draggable_footprints.dart';
import 'package:circuit_designer/sketch_comp_library.dart';
import 'package:circuit_designer/sketch_footprint_painter.dart';
import 'package:circuit_designer/sketch_menubar.dart';
import 'package:flutter/material.dart';
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

  final List<String> toolsIcons = [
    'lib/assets/images/icon_buttons/rounded_pad.png',
    'lib/assets/images/icon_buttons/square_pad.png',
    'lib/assets/images/icon_buttons/oval_pad.png',
    'lib/assets/images/icon_buttons/rectangle_pad.png',
    'lib/assets/images/icon_buttons/rectangle_pad.png',
    'lib/assets/images/icon_buttons/rectangle_pad.png',
    'lib/assets/images/icon_buttons/rectangle_pad.png',
  ];

  List<DraggableFootprints> compToDisplay = [];

  @override
  void initState() {
    WindowManager.instance.setMinimumSize(const Size(1920, 1080));
    WindowManager.instance.maximize();
    WindowManager.instance.setMaximizable(true);

    loadJsonFiles();
    super.initState();
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
                            GestureDetector(
                              child: Container(
                                height: double.infinity,
                                color: Colors.grey.shade800,
                                child: Center(
                                  child: Container(
                                    height: canvasHeightInPixels * scale,
                                    width: canvasWidthInPixels * scale,
                                    color: Colors.white,
                                    child: CustomPaint(
                                      painter: FootPrintPainter(
                                          compToDisplay, scale),
                                      size: Size(canvasWidthInPixels,
                                          canvasHeightInPixels),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              child: SizedBox(
                                  height: 400,
                                  width: 150,
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero),
                                    child: Column(
                                      children: [
                                        const Center(
                                          child: Text("Tools"),
                                        ),
                                        Expanded(
                                            child: Card(
                                          child: Container(
                                            color: Colors.grey,
                                            child: GridView.builder(
                                                itemCount: toolsIcons.length,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                gridDelegate:
                                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 2),
                                                itemBuilder: (context, index) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: Container(
                                                      color: Colors.white,
                                                      child: IconButton(
                                                          onPressed: () {},
                                                          icon: Image.asset(
                                                              toolsIcons[
                                                                  index])),
                                                    ),
                                                  );
                                                }),
                                          ),
                                        ))
                                      ],
                                    ),
                                  )),
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
                                          itemCount: 4,
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
    });
  }

  void zoomOutButton() {
    print("zoom out button pressed");
    if (scale <= 1) {
      setState(() {
        scale = 1;
      });
    } else {
      setState(() {
        scale -= 0.2;
      });
    }
  }

  void deleteButton() {
    print("delete button pressed");
  }
}
