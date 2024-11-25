// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:circuit_designer/cnc_controls_outline_painter.dart';
import 'package:circuit_designer/outline_carve.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class CncControls extends StatefulWidget {
  final List<File>? gCodeFiles;
  final List<String>? gCodeCommands;
  final OverallOutline? designOutlines;
  final double? scale;
  final double? canvasWidth;
  final double? canvasHeight;
  const CncControls(
      {super.key,
      this.gCodeFiles,
      this.gCodeCommands,
      this.designOutlines,
      this.scale,
      this.canvasHeight,
      this.canvasWidth});

  @override
  State<CncControls> createState() => _CncControlsState();
}

class _CncControlsState extends State<CncControls> {
  TextEditingController feedRateController = TextEditingController(text: '500');
  TextEditingController gCodeController = TextEditingController();
  TextEditingController textFieldController = TextEditingController();

  TextEditingController stepSizeX = TextEditingController(text: "1");
  TextEditingController stepSizeY = TextEditingController(text: "1");
  TextEditingController stepSizeZ = TextEditingController(text: "1");

  List<String> textsToDisplay = [];
  List<List<String>> gCodeLinesToDisplay = [];
  List<List<String>> gCodeLinesToSend = [];

  bool isSpindleOn = false;
  bool isConnected = false;
  bool isPaused = false;
  bool isStopped = false;

  String portStatus = "Disconnected";
  String? portName;

  List<String> availablePorts = [];
  SerialPort? selectedPort;
  SerialPortReader? reader;
  String grblResponse = '';
  StringBuffer responseBuffer = StringBuffer();

  late SharedPreferences pref;
  double xValue = 0;
  double yValue = 0;
  double zValue = 0;

  double defaultFeedRate = 500.0;

  @override
  void initState() {
    WindowManager.instance.maximize();
    WindowManager.instance.setMaximizable(true);

    _listAvailablePorts();

    if (widget.gCodeFiles != null) {
      for (var file in widget.gCodeFiles!) {
        parseGCodeFiles(file);
      }
    }

    super.initState();
  }

  void parseGCodeFiles(File gcodeFile) async {
    try {
      final List<String> gCodeFromFile = await gcodeFile.readAsLines();

      final List<String> parsedLines = gCodeFromFile
          .map((line) {
            final cleanLine = line.split(";").first.trim();
            return cleanLine.isNotEmpty ? cleanLine : null;
          })
          .whereType<String>()
          .toList();

      setState(() {
        gCodeLinesToDisplay.add(parsedLines);
        gCodeLinesToSend.add(parsedLines);
      });
    } catch (e) {
      print('Error parsing GCode: $e');
    }
  }

  // Method to list available ports
  void _listAvailablePorts() {
    availablePorts = SerialPort.availablePorts;

    if (availablePorts.isNotEmpty) {
      print("Available Ports: ");
      for (var port in availablePorts) {
        print(port);
      }
    } else {
      print("No serial ports available");
    }
  }

  StreamSubscription<Uint8List>? _subscription;

  // Method to connect to the selected port
  // Connect to the serial port
  void _connectToPort(String portName) async {
    try {
      // Close the port if it is already open
      if (selectedPort != null && selectedPort!.isOpen) {
        _disconnectPort();
      }

      selectedPort = SerialPort(portName);
      selectedPort!.config.baudRate = 115200;
      selectedPort!.config.bits = 8;
      selectedPort!.config.parity = SerialPortParity.none;
      selectedPort!.config.stopBits = 1;

      // Open the port for reading and writing
      if (selectedPort!.openReadWrite()) {
        print('Successfully connected to $portName');

        // Flush any residual data
        selectedPort!.flush();

        await Future.delayed(Duration(milliseconds: 1000));

        // Set up a listener to read the response
        reader = SerialPortReader(selectedPort!);

        _subscription = reader!.stream.listen((data) {
          print('Raw data received: $data');
          final response = String.fromCharCodes(data);
          print('Converted response: $response');

          // Append new data to the buffer
          responseBuffer.write(response);

          // If a complete response is received (contains '\n')
          if (responseBuffer.toString().contains('\n')) {
            setState(() {
              grblResponse = responseBuffer.toString().trim();
              textsToDisplay.insert(0, "-> $grblResponse");
              responseBuffer.clear();
            });

            // Print the response to the console
            print('GRBL Response: $grblResponse');
          }
        }, onError: (error) {
          print("Error reading from serial port: $error");
        }, onDone: () {
          print("Stream is done.");
        });

        // Send G-code commands after confirming GRBL is ready
        await _initializeGRBL();
      } else {
        print('Failed to open port $portName');
      }
    } catch (e) {
      print('Exception occurred while connecting: $e');
    }
  }

  // Method to send GCode to GRBL
  void _sendGCode(String command) {
    if (selectedPort != null && selectedPort!.isOpen) {
      try {
        final data = Uint8List.fromList('$command\n'.codeUnits);
        selectedPort!.write(data);
        print('Sent G-code: $command');
      } catch (e) {
        print('Exception occurred while sending G-code: $e');
      }
    } else {
      print('No port connected');
    }
  }

  void sendCommandLines(
      List<List<String>> gCodeLines, BuildContext context) async {
    for (int i = 0; i < gCodeLines.length; i++) {
      for (int j = 0; j < gCodeLines[i].length; j++) {
        if (isStopped) {
          return;
        }
        bool check = await validateCommand(gCodeLines[i][j]);
        if (check == true) {
          _sendGCode(gCodeLines[i][j]);
          await Future.delayed(const Duration(seconds: 2));
          setState(() {
            textsToDisplay.insert(0, gCodeLines[i][j]);
          });
        } else {
          _sendGCode("G0 X0 Y0 Z50");
          _sendGCode("M30");
          int indexI = i;
          int indexJ = j + 1;
          String string2 = gCodeLines[indexI][indexJ];

          promptUser(context, string2);

          setState(() {
            textsToDisplay.insert(0, "-> Stopping Process");
            removeGCodes(indexI, indexJ);
          });

          return;
        }
      }
    }
  }

  void promptUser(BuildContext context, String string) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Drill bit Size'),
          content: Text(
            'Please change the drill bit sizes to $string mm and set the home axis again',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Okay'),
            ),
          ],
        );
      },
    );
  }

  void removeGCodes(int indexI, int indexJ) {
    setState(() {
      // Remove all elements in lines before indexI
      for (int i = 0; i < indexI; i++) {
        gCodeLinesToSend.removeAt(0);
      }

      // Now remove elements up to indexJ in the first line (previously at indexI)
      if (gCodeLinesToSend.isNotEmpty && indexJ < gCodeLinesToSend[0].length) {
        for (int j = 0; j <= indexJ; j++) {
          gCodeLinesToSend[0].removeAt(0);
        }
      }

      // Remove the line if it's empty after element removal
      if (gCodeLinesToSend.isNotEmpty && gCodeLinesToSend[0].isEmpty) {
        gCodeLinesToSend.removeAt(0);
      }
    });
  }

  Future<bool> validateCommand(String command) async {
    if (command == "(Drilling)") {
      return false;
    } else {
      return true;
    }
  }

  // Initialize GRBL and set zeroth position
  Future<void> _initializeGRBL() async {
    try {
      textsToDisplay.insert(0, "Initializing GRBL...");
      _sendGCode("\$X"); // Unlock GRBL (if locked)
      await Future.delayed(const Duration(milliseconds: 500));
      _sendGCode("G10 L20 P1 X0 Y0 Z0"); // Set zeroth position
      textsToDisplay.insert(0, "GRBL initialized and position set to zero.");

      setState(() {});
    } catch (e) {
      print('Error initializing GRBL: $e');
    }
  }

  // Method to disconnect from the serial port
  void _disconnectPort() {
    if (selectedPort != null && selectedPort!.isOpen) {
      try {
        _subscription?.cancel(); // Make sure the stream is properly canceled
        selectedPort!.close();
        setState(() {
          textsToDisplay.insert(0, "Connection has been closed");
          selectedPort = null;
          reader = null;
          _subscription = null;
          grblResponse = '';
        });
        print('Disconnected from port');
      } catch (e) {
        print('Exception occurred while disconnecting: $e');
      }
    }
  }

  // Method to listen for GRBL response (if needed)
  Future<String> _waitForGRBLResponse() async {
    Completer<String> completer = Completer();

    if (reader != null) {
      reader!.stream.listen((data) {
        final response = String.fromCharCodes(data);

        // Append the new data to the buffer
        responseBuffer.write(response);

        // Check if the response contains a newline character, which signifies the end of the response
        if (response.contains('\n')) {
          setState(() {
            grblResponse = responseBuffer.toString().trim();
            textsToDisplay.insert(0, "-> $grblResponse");
            responseBuffer.clear(); // Clear the buffer for the next response
          });

          // Complete the completer with the GRBL response
          completer.complete(grblResponse);

          // Print the response to the debug console
          print('GRBL Response: $grblResponse');
        }
      });
    } else {
      completer.completeError(
          'SerialPortReader not initialized or no port connected.');
    }

    // Return the future which will complete when the response is received
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // This is for the Left Side sections consisting of (Controller state, and Manual Controls)
          Column(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  width: screenWidth * 0.21,
                  child: Card(
                    color: Colors.blueGrey.shade800,
                    elevation: 10.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.005,
                              vertical: screenHeight * 0.015),
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.0025,
                              vertical: screenHeight * 0.0075),
                          decoration: BoxDecoration(
                              color: isConnected
                                  ? Colors.lightGreenAccent.shade700
                                  : Colors.red,
                              border:
                                  Border.all(width: 2, color: Colors.white)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "STATUS: ",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isConnected ? "Connected" : "Disconnected",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Text(
                              'Select Serial Port:',
                              style: TextStyle(
                                fontSize: 16, // Larger text for label
                                fontWeight: FontWeight.bold, // Bold label text
                                color: Colors
                                    .white, // Slightly faded black for a polished look
                              ),
                            ),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey.shade600),
                                onPressed: () {
                                  if (isConnected == false) {
                                    setState(() {
                                      _connectToPort(portName!);
                                      isConnected = true;
                                    });
                                  } else {
                                    setState(() {
                                      if (xValue != 0 ||
                                          yValue != 0 ||
                                          zValue != 0) {
                                        _sendGCode(
                                            "G0 X0 Y0 Z0 F${feedRateController.text}");
                                        xValue = 0;
                                        yValue = 0;
                                        zValue = 0;
                                      }
                                      _disconnectPort();
                                      isConnected = false;
                                    });
                                  }
                                },
                                child: Text(
                                  isConnected ? "Disconnect" : "Connect",
                                  style: const TextStyle(color: Colors.white),
                                )),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey.shade600),
                                onPressed: () {
                                  _listAvailablePorts();
                                  setState(() {});
                                },
                                child: const Text(
                                  "Refresh",
                                  style: TextStyle(color: Colors.white),
                                ))
                          ],
                        ), // Space between label and dropdown
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.005,
                              vertical: screenHeight * 0.015),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.0075),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey
                                  .shade600, // Set the background to white
                              borderRadius:
                                  BorderRadius.circular(10), // Rounded corners
                              border: Border.all(
                                  color:
                                      Colors.white), // Border around dropdown
                            ),
                            child: DropdownButton<String>(
                              value: portName,

                              hint: const Text(
                                "Select a Port",
                                style: TextStyle(color: Colors.white),
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ), // Add a dropdown icon
                              isExpanded:
                                  true, // Ensure dropdown takes full width
                              underline: const SizedBox
                                  .shrink(), // Remove the default underline
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    portName = newValue;
                                    print(newValue);
                                  });
                                }
                              },
                              items: availablePorts
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.005,
                                        vertical: screenHeight * 0.015),
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        fontSize:
                                            14, // Larger text for dropdown items
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.005,
                              vertical: screenHeight * 0.015),
                          margin: EdgeInsets.only(
                              top: screenHeight * 0.01,
                              bottom: screenHeight * 0.01,
                              left: screenWidth * 0.015,
                              right: screenWidth * 0.015),
                          decoration: BoxDecoration(
                              border:
                                  Border.all(width: 2, color: Colors.white)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "X Axis",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                "0.000",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.005,
                              vertical: screenHeight * 0.015),
                          margin: EdgeInsets.only(
                              top: screenHeight * 0.01,
                              bottom: screenHeight * 0.01,
                              left: screenWidth * 0.015,
                              right: screenWidth * 0.015),
                          decoration: BoxDecoration(
                              border:
                                  Border.all(width: 2, color: Colors.white)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Y Axis",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                "0.000",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.005,
                              vertical: screenHeight * 0.015),
                          margin: EdgeInsets.only(
                              top: screenHeight * 0.01,
                              bottom: screenHeight * 0.01,
                              left: screenWidth * 0.015,
                              right: screenWidth * 0.015),
                          decoration: BoxDecoration(
                              border:
                                  Border.all(width: 2, color: Colors.white)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Z Axis",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                "0.000",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenHeight * 0.01),
                          child: TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            controller: feedRateController,
                            style: const TextStyle(
                                color: Colors
                                    .white), // Set input text color to white
                            decoration: const InputDecoration(
                              labelText: 'Enter Feed Rate',
                              labelStyle: TextStyle(
                                  color: Colors.white), // Make label text white
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors
                                        .white), // Set border color to white
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors
                                        .white), // White color when enabled
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors
                                        .white), // White color when focused
                              ),
                            ),
                          ),
                        ),

                        Container(
                          margin: EdgeInsets.only(top: screenHeight * 0.04),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey.shade600,
                                      shape: const CircleBorder(),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.005,
                                          vertical: screenHeight * 0.02)),
                                  onPressed: () async {
                                    if (isPaused == true) {
                                      setState(() {
                                        textsToDisplay.insert(0, "Resumed");
                                        isPaused = false;
                                      });
                                      _sendGCode("~");
                                    } else {
                                      setState(() {
                                        isStopped = false;
                                      });
                                      sendCommandLines(
                                          gCodeLinesToSend, context);
                                    }
                                  },
                                  child: const Icon(Icons.play_arrow,
                                      color: Colors.white)),
                              ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      textsToDisplay.insert(0, "Paused");
                                      isPaused = true;
                                    });
                                    _sendGCode("!");
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey.shade600,
                                      shape: const CircleBorder(),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.005,
                                          vertical: screenHeight * 0.02)),
                                  child: const Icon(Icons.pause,
                                      color: Colors.white)),
                              ElevatedButton(
                                  onPressed: () {
                                    _sendGCode("M30");
                                    isStopped = true;
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey.shade600,
                                      shape: const CircleBorder(),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.005,
                                          vertical: screenHeight * 0.02)),
                                  child: const Icon(Icons.stop,
                                      color: Colors.white)),
                              ElevatedButton(
                                  onPressed: () {
                                    _sendGCode("G10 L20 P1 X0 Y0 Z0");
                                    textsToDisplay.insert(
                                        0, "-> G10 L20 P1 X0 Y0 Z0");

                                    xValue = 0;
                                    yValue = 0;
                                    zValue = 0;
                                    setState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey.shade600,
                                      shape: const CircleBorder(),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.005,
                                          vertical: screenHeight * 0.02)),
                                  child: const Icon(Icons.restart_alt,
                                      color: Colors.white))
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              // This is the Manual Controls Section
              Expanded(
                flex: 2,
                child: SizedBox(
                  width: screenWidth * 0.21,
                  child: Card(
                    color: Colors.blueGrey.shade800,
                    elevation: 10.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              width: screenWidth * 0.01,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.0025,
                                  vertical: screenHeight * 0.001),
                              child: const Text(
                                "Manual Controls",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                  top: screenWidth * 0.01,
                                  left: screenWidth * 0.01),
                              child: IconButton(
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (builder) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5)),
                                            child: Container(
                                              height: screenHeight * 0.35,
                                              width: screenWidth * 0.2,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0)),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal:
                                                                screenWidth *
                                                                    0.01,
                                                            vertical:
                                                                screenHeight *
                                                                    0.03),
                                                    child: const Text(
                                                      "Step Sizes",
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal:
                                                                screenWidth *
                                                                    0.01,
                                                            vertical:
                                                                screenHeight *
                                                                    0.01),
                                                    child: TextField(
                                                      controller: stepSizeX,
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText:
                                                            'Step Size for X Axis (mm)',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal:
                                                                screenWidth *
                                                                    0.01,
                                                            vertical:
                                                                screenHeight *
                                                                    0.01),
                                                    child: TextField(
                                                      controller: stepSizeY,
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText:
                                                            'Step Size for Y Axis (mm)',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal:
                                                                screenWidth *
                                                                    0.01,
                                                            vertical:
                                                                screenHeight *
                                                                    0.01),
                                                    child: TextField(
                                                      controller: stepSizeZ,
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText:
                                                            'Step Size for Z Axis (mm)',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal:
                                                                screenWidth *
                                                                    0.01,
                                                            vertical:
                                                                screenHeight *
                                                                    0.01),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        ElevatedButton(
                                                            onPressed: () {
                                                              setState(() {
                                                                textsToDisplay
                                                                    .insert(0,
                                                                        "-> Step sizes Updated:");

                                                                textsToDisplay
                                                                    .insert(0,
                                                                        "-> X: ${stepSizeX.text} mm");
                                                                textsToDisplay
                                                                    .insert(0,
                                                                        "-> Y: ${stepSizeY.text} mm");
                                                                textsToDisplay
                                                                    .insert(0,
                                                                        "-> Z: ${stepSizeZ.text} mm");
                                                              });
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                "Update")),
                                                        ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                "Cancel"))
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        });
                                  },
                                  icon: const Icon(Icons.settings,
                                      color: Colors.white)),
                            )
                          ],
                        ),
                        const Divider(),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.01),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Spindle",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              CupertinoSwitch(
                                  value: isSpindleOn,
                                  onChanged: (value) {
                                    setState(() {
                                      isSpindleOn = value;
                                      if (value == true) {
                                        textsToDisplay.insert(0, "M3");
                                        _sendGCode("M3");
                                      } else {
                                        textsToDisplay.insert(0, "M5");
                                        _sendGCode("M5");
                                      }
                                    });
                                  }),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 4,
                            children: [
                              Container(),
                              Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                child: ElevatedButton(
                                    onPressed: () {
                                      if (feedRateController.text.isEmpty) {
                                        textsToDisplay.insert(0,
                                            "-> Error: Feed Rate not specified");
                                      } else {
                                        double calculatedPosition =
                                            getCalculatedPosition(
                                                double.parse(stepSizeY.text),
                                                yValue,
                                                true);

                                        _sendGCode(
                                            "G90 G1 X$xValue Y$calculatedPosition F${feedRateController.text}");

                                        textsToDisplay.insert(0,
                                            "-> G90 G1 X$xValue Y$calculatedPosition F${feedRateController.text}");

                                        yValue = calculatedPosition;
                                      }

                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueGrey.shade600,
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 2, color: Colors.white),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("Y",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 10,
                                        )
                                      ],
                                    )),
                              ),
                              Container(),
                              Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                child: ElevatedButton(
                                    onPressed: () {
                                      if (feedRateController.text.isEmpty) {
                                        textsToDisplay.insert(0,
                                            "-> Error: Feed Rate not specified");
                                      } else {
                                        double calculatedPosition =
                                            getCalculatedPosition(
                                                double.parse(stepSizeZ.text),
                                                zValue,
                                                true);

                                        _sendGCode(
                                            "G90 G1 Z$calculatedPosition F${feedRateController.text}");

                                        textsToDisplay.insert(0,
                                            "-> G90 G1 Z$calculatedPosition F${feedRateController.text}");

                                        zValue = calculatedPosition;
                                      }

                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueGrey.shade600,
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 2, color: Colors.white),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("Z",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 10,
                                        )
                                      ],
                                    )),
                              ),
                              Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                child: ElevatedButton(
                                    onPressed: () {
                                      if (feedRateController.text.isEmpty) {
                                        textsToDisplay.insert(0,
                                            "-> Error: Feed Rate not specified");
                                      } else {
                                        double calculatedPosition =
                                            getCalculatedPosition(
                                                double.parse(stepSizeX.text),
                                                xValue,
                                                false);

                                        _sendGCode(
                                            "G90 G1 X$calculatedPosition Y$yValue F${feedRateController.text}");

                                        textsToDisplay.insert(0,
                                            "-> G90 G1 X$calculatedPosition Y$yValue F${feedRateController.text}");

                                        xValue = calculatedPosition;
                                      }

                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueGrey.shade600,
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 2, color: Colors.white),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("X",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                          size: 10,
                                        )
                                      ],
                                    )),
                              ),
                              Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _sendGCode("G90 G0 X0 Y0 Z0");
                                        textsToDisplay.insert(
                                            0, "-> G90 G0 X0 Y0 Z0");

                                        xValue = 0;
                                        yValue = 0;
                                        zValue = 0;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueGrey.shade600,
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 2, color: Colors.white),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Icon(
                                      Icons.home,
                                      color: Colors.white,
                                      size: 20,
                                    )),
                              ),
                              Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                child: ElevatedButton(
                                    onPressed: () {
                                      if (feedRateController.text.isEmpty) {
                                        textsToDisplay.insert(0,
                                            "-> Error: Feed Rate not specified");
                                      } else {
                                        double calculatedPosition =
                                            getCalculatedPosition(
                                                double.parse(stepSizeX.text),
                                                xValue,
                                                true);

                                        _sendGCode(
                                            "G90 G1 X$calculatedPosition Y$yValue F${feedRateController.text}");

                                        textsToDisplay.insert(0,
                                            "-> G90 G1 X$calculatedPosition Y$yValue F${feedRateController.text}");

                                        xValue = calculatedPosition;
                                      }

                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueGrey.shade600,
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 2, color: Colors.white),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("X",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 10,
                                        )
                                      ],
                                    )),
                              ),
                              Container(),
                              Container(),
                              Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                child: ElevatedButton(
                                    onPressed: () {
                                      if (feedRateController.text.isEmpty) {
                                        textsToDisplay.insert(0,
                                            "-> Error: Feed Rate not specified");
                                      } else {
                                        double calculatedPosition =
                                            getCalculatedPosition(
                                                double.parse(stepSizeY.text),
                                                yValue,
                                                false);

                                        _sendGCode(
                                            "G90 G1 X$xValue Y$calculatedPosition F${feedRateController.text}");

                                        textsToDisplay.insert(0,
                                            "-> G90 G1  X$xValue Y$calculatedPosition F${feedRateController.text}");

                                        yValue = calculatedPosition;
                                      }

                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueGrey.shade600,
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 2, color: Colors.white),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("Y",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                          size: 10,
                                        )
                                      ],
                                    )),
                              ),
                              Container(),
                              Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                child: ElevatedButton(
                                    onPressed: () {
                                      if (feedRateController.text.isEmpty) {
                                        textsToDisplay.insert(0,
                                            "-> Error: Feed Rate not specified");
                                      } else {
                                        double calculatedPosition =
                                            getCalculatedPosition(
                                                double.parse(stepSizeZ.text),
                                                zValue,
                                                false);

                                        _sendGCode(
                                            "G90 G1 Z$calculatedPosition F${feedRateController.text}");

                                        textsToDisplay.insert(0,
                                            "-> G90 G1 Z$calculatedPosition F${feedRateController.text}");

                                        zValue = calculatedPosition;
                                      }

                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueGrey.shade600,
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 2, color: Colors.white),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text(
                                          "Z",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                          size: 10,
                                        )
                                      ],
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // This section is for consol and GCode Viewer
          Column(
            children: [
              Expanded(
                  child: SizedBox(
                width: screenWidth * 0.3,
                child: Card(
                  color: Colors.blueGrey.shade800,
                  elevation: 10.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      const Text(
                        "Console",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20),
                          child: Card(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: ListView.separated(
                                itemCount: gCodeLinesToDisplay.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                        color: Colors.grey, thickness: 1),
                                itemBuilder: (context, index) {
                                  int reversedIndex =
                                      gCodeLinesToDisplay.length - 1 - index;

                                  List<String> subList =
                                      gCodeLinesToDisplay[reversedIndex];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: subList
                                          .map((item) => Text(
                                                item,
                                                style: const TextStyle(
                                                    fontSize:
                                                        16), // Customize text style
                                              ))
                                          .toList(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20),
                          child: Card(
                            child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white),
                                child: ListView.builder(
                                    itemCount: textsToDisplay.length,
                                    reverse: true,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                          minVerticalPadding: 2,
                                          minTileHeight: 20,
                                          title: Text(textsToDisplay[index]));
                                    })),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Card(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          color: Colors.blueGrey.shade800,
                          child: Container(
                            height: 48,
                            color: Colors.white,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: TextField(
                                controller: gCodeController,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textAlignVertical: TextAlignVertical.bottom,
                                decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      onPressed: () async {
                                        textsToDisplay.insert(
                                            0, gCodeController.text);
                                        _sendGCode(gCodeController.text);
                                      },
                                      icon: const Icon(Icons.send),
                                    )),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),

          // This is for the design Viewer
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.blueGrey.shade800,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    "Design Viewer",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white),
                  ),
                  Expanded(
                      child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              width: 2.0, color: Colors.blueGrey.shade900),
                        ),
                        child: widget.designOutlines == null
                            ? const Center(
                                child: Text(
                                    "No design outlines available")) // Optional: Display a message
                            : CustomPaint(
                                painter: OutlinePainter(
                                  widget.designOutlines!.connectedLines,
                                  widget.designOutlines!.arcs,
                                  widget.scale!,
                                  widget.designOutlines!.smdOutline,
                                ),
                                size: Size(
                                    widget.canvasWidth!, widget.canvasHeight!),
                              ),
                      ),
                    ),
                  ))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double getCalculatedPosition(double a, double b, bool isAdd) {
    if (isAdd) {
      return b + a;
    }

    return b - a;
  }
}
