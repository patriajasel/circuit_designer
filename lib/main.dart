import 'dart:io';

import 'package:circuit_designer/cnc_controls.dart';
import 'package:circuit_designer/sketch_designer.dart';
import 'package:circuit_designer/start_page.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setting the minimum and maximum size for the window
  await windowManager.ensureInitialized();
  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(1280, 720));
    WindowManager.instance.setMaximumSize(const Size(1920, 1080));
    WindowManager.instance.setTitle("Creative Circuits");
    WindowManager.instance.setMaximizable(false);
    WindowManager.instance.setResizable(false);
    WindowManager.instance.center();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Circuit Designer',
      home: const StartPage(),

      // Navigation Names
      routes: {
        '/Sketch': (context) => const Sketchboard(),
        '/Controls': (context) => const CncControls()
      },
    );
  }
}
