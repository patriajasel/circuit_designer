// ignore_for_file: avoid_print

import 'package:circuit_designer/sketch_menubar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

    final TextEditingController _searchTextController = TextEditingController();

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
                ),
                Expanded(
                    child: Row(
                  children: [
                    SizedBox(
                      width: 300.0,
                      child: Column(
                        children: [
                          Expanded(
                              child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(width: 2),
                              color: const Color(0xFFF9FCFE),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        top: 8.0, left: 8.0, right: 8.0),
                                    child: Text(
                                      "Components",
                                      style: TextStyle(
                                          fontFamily: "Arvo", fontSize: 18.0),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding:
                                      EdgeInsets.only(left: 8.0, right: 8.0),
                                  child: Divider(thickness: 2),
                                ),
                                SizedBox(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CupertinoSearchTextField(
                                      placeholder: "Search Components...",
                                      decoration: BoxDecoration(
                                          border: Border.all(width: 2),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      style: const TextStyle(fontSize: 14.0),
                                      controller: _searchTextController,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )),
                          Expanded(
                            child: Container(
                              color: Colors.blue,
                              width: double.infinity,
                              child: const Text("Hierarchy Section"),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
