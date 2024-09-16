// ignore_for_file: avoid_print

import 'package:circuit_designer/sketch_menubar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For key bindings
import 'package:window_manager/window_manager.dart';

class Sketchboard extends StatefulWidget {
  const Sketchboard({super.key});

  @override
  State<Sketchboard> createState() => _SketchboardState();
}

class _SketchboardState extends State<Sketchboard> {
  @override
  void initState() {
    WindowManager.instance.setMinimumSize(const Size(1280, 720));
    WindowManager.instance.setMaximizable(true);
    WindowManager.instance.maximize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    MenuActions menuActions = MenuActions();

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
                    menuActions.buildSettingsMenu(),
                    menuActions.buildHelpMenu()
                  ]),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// * A custom intent to handle different menu actions
class ActivateIntent extends Intent {
  const ActivateIntent(this.action);
  final String action;
}
