// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:circuit_designer/sketch_comp_library.dart';
import 'package:circuit_designer/sketch_menubar.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'data_footprints.dart';

// TODO: Make it that whenever a component is clicked, it will be added to the canvas

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

  @override
  void initState() {
    WindowManager.instance.setMinimumSize(const Size(1280, 720));
    WindowManager.instance.setMaximizable(true);
    WindowManager.instance.maximize();

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

  @override
  Widget build(BuildContext context) {
    MenuActions menuActions = MenuActions();
    CompAndPartsSection sideSection = CompAndPartsSection();

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
                    child: Row(children: [
                  sideSection.sideSection(packages),
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      color: Colors.grey.shade800,
                      child: Center(
                        child: Container(
                          height: canvasHeightInPixels,
                          width: canvasWidthInPixels,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ]))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
