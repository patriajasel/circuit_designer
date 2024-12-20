// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:circuit_designer/draggable_footprints.dart';
import 'package:circuit_designer/line_traces.dart';
import 'package:circuit_designer/sketch_designer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuActions {
  List<DraggableFootprints>? footprints;
  List<Line>? lines;
  BuildContext context;
  Function(String, String) sendPath;
  String? path;
  String? sketchName;

  MenuActions(
      {this.footprints,
      this.lines,
      required this.context,
      required this.sendPath,
      this.path,
      this.sketchName});

  Map<LogicalKeySet, Intent> buildShortcuts() {
    return {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
          const ActivateIntent('newDesign'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO):
          const ActivateIntent('openDesign'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
          const ActivateIntent('save'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX):
          const ActivateIntent('cut'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
          const ActivateIntent('copy'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
          const ActivateIntent('paste'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
          const ActivateIntent('undo'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
          const ActivateIntent('redo'),
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.f4):
          const ActivateIntent('exit'),
    };
  }

  // * Mapping the shortcuts to Actions
  Map<Type, Action<Intent>> buildActions() {
    return {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (ActivateIntent intent) {
          switch (intent.action) {
            case 'newDesign':
              print('New Design clicked');
              break;
            case 'openDesign':
              print('Open Design clicked');
              break;
            case 'save':
              saveDesign(footprints!, lines!, context, sendPath,
                  filePath: path, fileName: sketchName);
              break;
            case 'cut':
              print('Cut clicked');
              break;
            case 'copy':
              print('Copy clicked');
              break;
            case 'paste':
              print('Paste clicked');
              break;
            case 'undo':
              print('Undo clicked');
              break;
            case 'redo':
              print('Redo clicked');
              break;
            case 'exit':
              print('Exit clicked');
              break;
          }
          return null;
        },
      ),
    };
  }

  // * Building File Menu in Menu bar
  SubmenuButton buildFileMenu() {
    return SubmenuButton(
      menuChildren: [
        _addMenuItem('New Design', () => print('New clicked'),
            shortcut: 'Ctrl + N'),
        _addMenuItem('Open Design', () => print('Open clicked'),
            shortcut: 'Ctrl + O'),
        const Divider(),
        _addMenuItem(
            'Save',
            () => saveDesign(footprints!, lines!, context, sendPath,
                filePath: path, fileName: sketchName),
            shortcut: 'Ctrl + S'),
        const Divider(),
        _addMenuItem('Import', () => print('Exit clicked')),
        _addMenuItem('Export', () => print('Exit clicked')),
        const Divider(),
        _addMenuItem('Exit', () => print('Exit clicked'), shortcut: 'Alt + F4'),
      ],
      menuStyle:
          const MenuStyle(padding: WidgetStatePropertyAll(EdgeInsets.all(5))),
      child: const Text("File", style: TextStyle(color: Colors.white)),
    );
  }

  // * Building Edit Menu in Menu bar
  SubmenuButton buildEditMenu() {
    return SubmenuButton(
      menuChildren: [
        _addMenuItem('Undo', () => print('Undo clicked'), shortcut: 'Ctrl + Z'),
        _addMenuItem('Redo', () => print('Redo clicked'), shortcut: 'Ctrl + Y'),
        const Divider(),
        _addMenuItem('Cut', () => print('Cut clicked'), shortcut: 'Ctrl + X'),
        _addMenuItem('Copy', () => print('Copy clicked'), shortcut: 'Ctrl + C'),
        _addMenuItem('Paste', () => print('Paste clicked'),
            shortcut: 'Ctrl + V'),
      ],
      menuStyle:
          const MenuStyle(padding: WidgetStatePropertyAll(EdgeInsets.all(5))),
      child: const Text("Edit", style: TextStyle(color: Colors.white)),
    );
  }

  // * Building Settings Menu in Menu bar
  SubmenuButton buildSettingsMenu(
      BuildContext context,
      Function(int, int) updateCanvasSize,
      int currentCanvasHeight,
      int currentCanvasWidth) {
    return SubmenuButton(
        menuChildren: [
          _addMenuItem(
              'Canvas Settings',
              () => canvasSettings(context, updateCanvasSize,
                  currentCanvasHeight, currentCanvasWidth)),
          _addMenuItem('Open Configuration', () => print('Settings clicked')),
        ],
        child: const Text(
          "Settings",
          style: TextStyle(color: Colors.white),
        ));
  }

  // * Building Help Menu in Menu bar
  SubmenuButton buildHelpMenu() {
    return SubmenuButton(menuChildren: [
      _addMenuItem('About Us', () => print('Help clicked')),
    ], child: const Text("Help", style: TextStyle(color: Colors.white)));
  }

  // * Adding Menu Item for menu
  MenuItemButton _addMenuItem(String text, VoidCallback onPressed,
      {String? shortcut}) {
    return MenuItemButton(
        onPressed: onPressed,
        trailingIcon: shortcut != null && shortcut.isNotEmpty
            ? Text(
                shortcut,
                style: const TextStyle(color: Colors.grey),
              )
            : null,
        child: Text(text));
  }
}

void canvasSettings(BuildContext context, Function(int, int) updateCanvasSize,
    int currentCanvasHeight, int currentCanvasWidth) {
  int? selectedHeight = currentCanvasHeight;
  int? selectedWidth = currentCanvasWidth;

  List<int> canvasHeightList = [2, 3, 4, 5, 6];
  List<int> canvasWidthList = [2, 3, 4, 5, 6];
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            height: 500,
            width: 400,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  children: [
                    const Text(
                      "Canvas Settings",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Divider(
                      thickness: 2,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Select Height',
                              labelStyle: const TextStyle(
                                fontSize: 20,
                                color: Colors.black, // Label color
                              ),
                              filled: true,
                              fillColor:
                                  Colors.grey.shade100, // Background fill color
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    15.0), // Rounded corners
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 2.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 2.0, // Normal border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 2.0, // Focused border color
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, // Vertical padding
                                horizontal: 12.0, // Horizontal padding
                              ),
                              // Dropdown arrow
                            ),
                            value: selectedHeight?.toString(),
                            elevation: 16,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 18),
                            onChanged: (String? newHeight) {
                              if (newHeight != null) {
                                // Update the local state inside the dialog
                                setState(() {
                                  selectedHeight = int.parse(newHeight);
                                });
                              }
                            },
                            items: canvasHeightList
                                .map<DropdownMenuItem<String>>((int value) {
                              return DropdownMenuItem<String>(
                                value: value.toString(),
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            // Assign a unique key to avoid conflicts
                            decoration: InputDecoration(
                              labelText: 'Select Width',
                              labelStyle: const TextStyle(
                                fontSize: 20,
                                color: Colors.black, // Label color
                              ),
                              filled: true,
                              fillColor:
                                  Colors.grey.shade100, // Background fill color
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    15.0), // Rounded corners
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 2.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 2.0, // Normal border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 2.0, // Focused border color
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, // Vertical padding
                                horizontal: 12.0, // Horizontal padding
                              ),
                            ),
                            value: selectedWidth?.toString(),
                            elevation: 16,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 18),
                            onChanged: (String? newWidth) {
                              if (newWidth != null) {
                                // Update the selectedWidth state variable
                                setState(() {
                                  selectedWidth = int.parse(newWidth);
                                });
                              }
                            },
                            items: canvasWidthList
                                .map<DropdownMenuItem<String>>((int value) {
                              return DropdownMenuItem<String>(
                                value: value.toString(),
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                        )
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
                onPressed: () {
                  updateCanvasSize(selectedHeight!, selectedWidth!);
                  Navigator.pop(context);
                },
                child: const Text("Proceed")),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel")),
          ],
        );
      });
}

// * A custom intent to handle different menu actions
class ActivateIntent extends Intent {
  const ActivateIntent(this.action);
  final String action;
}

Future<void> saveDesign(
  List<DraggableFootprints> footprints,
  List<Line> lines,
  BuildContext context,
  Function(String, String) sendPath, {
  String? filePath,
  String? fileName,
}) async {
  try {
    // Convert footprints and lines to JSON
    Map<String, dynamic> designData = {
      'footprints': footprints.map((footprint) => footprint.toJson()).toList(),
      'lines': lines.map((line) => line.toJson()).toList(),
    };

    // Serialize the combined JSON data
    String jsonString = jsonEncode(designData);

    String finalFilePath;
    String folderPath;
    String finalFileName;

    print("FilePath Menu: $filePath");
    print("FileName Menu: $fileName");

    if (filePath != null && fileName != null) {
      // Use the provided file path and name
      folderPath = filePath;
      finalFileName = fileName;
      finalFilePath = '$folderPath/$finalFileName';
    } else {
      // Default logic: create a new folder and generate file name
      Directory? documentsDir = Directory(Platform.isWindows
          ? "${Platform.environment['USERPROFILE']}\\Documents"
          : "${Platform.environment['HOME']}/Documents");

      Directory appFolder = Directory('${documentsDir.path}/CC-Projects');

      // Create the CC-Projects folder if it doesn't exist
      if (!appFolder.existsSync()) {
        await appFolder.create(recursive: true);
      }

      // Generate a random folder name
      String randomFolderName = 'Project-${_generateRandomString(8)}';
      Directory projectFolder =
          Directory('${appFolder.path}/$randomFolderName');

      // Create the project folder
      if (!projectFolder.existsSync()) {
        await projectFolder.create(recursive: true);
      }

      // Generate a file name with a timestamp
      folderPath = projectFolder.path;
      finalFileName = '$randomFolderName-design.cc';
      finalFilePath = '$folderPath/$finalFileName';

      // Notify the caller about the new path
      sendPath(projectFolder.path, randomFolderName);
    }

    // Write the JSON data to the file (overwriting if it exists)
    File file = File(finalFilePath);
    await file.writeAsString(jsonString);

    // Show a dialog with a button to open the directory if a new folder was created

    _showOpenDirectoryDialog(context, folderPath);
  } catch (e) {
    print('Error saving design: $e');
  }
}

// Helper method to show the dialog
void _showOpenDirectoryDialog(BuildContext context, String directoryPath) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Design Saved'),
      content: const Text(
          'Your design has been saved. Would you like to open the folder?'),
      actions: [
        TextButton(
          onPressed: () {
            _openDirectory(directoryPath);
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Open Directory'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

// Helper method to open the directory
void _openDirectory(String directoryPath) async {
  Uri directoryUri = Uri.directory(directoryPath);
  if (await canLaunchUrl(directoryUri)) {
    await launchUrl(directoryUri);
  } else {
    print("Could not open folder.");
  }
}

// Helper method to generate a random string
String _generateRandomString(int length) {
  const characters =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  Random random = Random();
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => characters.codeUnitAt(random.nextInt(characters.length)),
    ),
  );
}

// Example of how to pick a file and parse the .cc design file.
Future<void> importDesign(BuildContext context) async {
  try {
    // Open the file picker dialog to select .cc files
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // Custom file type to filter extensions
      allowedExtensions: ['cc'], // Allow only .cc files
    );

    // If no file is selected, return
    if (result == null) {
      print('No file selected.');
      return;
    }

    // Get the selected file's path
    String filePath = result.files.single.path!;
    print('Selected file: $filePath');

    // Extract only the directory path (without the file name)
    String directoryPath = File(filePath).parent.path;
    print('Directory path: $directoryPath');

    String fileName = result.files.single.name;
    print('File name: $fileName');

    // Open the file and read its content
    File file = File(filePath);
    String fileContent = await file.readAsString();

    // Decode the JSON data from the file
    Map<String, dynamic> designData = jsonDecode(fileContent);

    // Extract footprints and lines from the decoded JSON
    List<dynamic> footprintsJson = designData['footprints'];
    List<dynamic> linesJson = designData['lines'];

    // Parse the footprints and lines into your models
    List<DraggableFootprints> footprints = footprintsJson
        .map((footprintJson) => DraggableFootprints.fromJson(footprintJson))
        .toList();

    List<Line> lines =
        linesJson.map((lineJson) => Line.fromJson(lineJson)).toList();

    // Now you can use the `footprints` and `lines` lists as needed
    print('Loaded ${footprints.length} footprints and ${lines.length} lines.');

    // Handle your parsed data (display, edit, etc.)
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (builder) => Sketchboard(
                  linesFromJson: lines,
                  footprintsFromJson: footprints,
                  filePathFromJson: directoryPath,
                  fileNameFromJson: fileName,
                )));
  } catch (e) {
    print('Error reading or parsing file: $e');
  }
}
