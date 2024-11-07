// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:window_manager/window_manager.dart';

class CncControls extends StatefulWidget {
  final List<String>? gCodeCommands;
  const CncControls({super.key, this.gCodeCommands});

  @override
  State<CncControls> createState() => _CncControlsState();
}

class _CncControlsState extends State<CncControls> {
  @override
  void initState() {
    WindowManager.instance.maximize();
    WindowManager.instance.setMaximizable(true);

    _listAvailablePorts();

    super.initState();
  }

  TextEditingController feedRateController = TextEditingController();
  TextEditingController gCodeController = TextEditingController();
  TextEditingController textFieldController = TextEditingController();

  TextEditingController stepSizeX = TextEditingController(text: "1");
  TextEditingController stepSizeY = TextEditingController(text: "1");
  TextEditingController stepSizeZ = TextEditingController(text: "1");

  List<String> textsToDisplay = [];

  bool isSpindleOn = false;
  bool isConnected = false;

  String portStatus = "Disconnected";
  String? portName;

  List<String> availablePorts = [];
  SerialPort? selectedPort;
  SerialPortReader? reader;
  String grblResponse = '';
  StringBuffer responseBuffer = StringBuffer();

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

        await Future.delayed(Duration(milliseconds: 10000));

        // Set up a listener to read the response
        reader = SerialPortReader(selectedPort!);

        _subscription = reader!.stream.listen((data) {
          print('Raw data received: $data'); // Debugging log for raw data
          final response = String.fromCharCodes(data);
          print(
              'Converted response: $response'); // Debugging log for converted data

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
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // This is for the Left Side sections consisting of (Controller state, and Manual Controls)
          Column(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  width: 400,
                  child: Card(
                    elevation: 10.0,
                    shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                              color: isConnected
                                  ? Colors.lightGreenAccent.shade700
                                  : Colors.red,
                              border:
                                  Border.all(width: 2, color: Colors.black54)),
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
                                    .black87, // Slightly faded black for a polished look
                              ),
                            ),
                            ElevatedButton(
                                onPressed: () {
                                  if (isConnected == false) {
                                    setState(() {
                                      _connectToPort(portName!);
                                      isConnected = true;
                                    });
                                  } else {
                                    setState(() {
                                      _disconnectPort();
                                      isConnected = false;
                                    });
                                  }
                                },
                                child: Text(
                                    isConnected ? "Disconnect" : "Connect")),
                            ElevatedButton(
                                onPressed: () {
                                  _listAvailablePorts();
                                },
                                child: const Text("Refresh"))
                          ],
                        ), // Space between label and dropdown
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white, // Set the background to white
                              borderRadius:
                                  BorderRadius.circular(10), // Rounded corners
                              border: Border.all(
                                  color: Colors
                                      .grey.shade400), // Border around dropdown
                            ),
                            child: DropdownButton<String>(
                              value: portName,
                              hint: const Text("Select a Port"),
                              icon: const Icon(
                                  Icons.arrow_drop_down), // Add a dropdown icon
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 8),
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
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(
                              top: 30.0, bottom: 10, left: 30, right: 30),
                          decoration: BoxDecoration(
                              border:
                                  Border.all(width: 2, color: Colors.black)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "X Axis",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text("0.000")
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 10),
                          decoration: BoxDecoration(
                              border:
                                  Border.all(width: 2, color: Colors.black)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Y Axis",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text("0.000")
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 10),
                          decoration: BoxDecoration(
                              border:
                                  Border.all(width: 2, color: Colors.black)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Z Axis",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text("0.000")
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50.0, vertical: 10),
                          child: TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            controller: feedRateController,
                            decoration: const InputDecoration(
                              labelText: 'Enter Feed Rate',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        Container(
                          margin: const EdgeInsets.only(top: 60),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(20.0)),
                                  onPressed: () {},
                                  child: const Icon(Icons.play_arrow)),
                              ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(20.0)),
                                  child: const Icon(Icons.pause)),
                              ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(20.0)),
                                  child: const Icon(Icons.stop)),
                              ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(20.0)),
                                  child: const Icon(Icons.restart_alt))
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
                  width: 400,
                  child: Card(
                    elevation: 10.0,
                    shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            const SizedBox(
                              width: 20,
                            ),
                            const Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Text(
                                "Manual Controls",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 10.0, left: 10),
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
                                              height: 350,
                                              width: 400,
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
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.all(20.0),
                                                    child: Text(
                                                      "Step Sizes",
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20.0,
                                                        vertical: 10),
                                                    child: TextField(
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .digitsOnly
                                                      ],
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20.0,
                                                        vertical: 10),
                                                    child: TextField(
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .digitsOnly
                                                      ],
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20.0,
                                                        vertical: 10),
                                                    child: TextField(
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .digitsOnly
                                                      ],
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
                                                        const EdgeInsets.all(
                                                            20.0),
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
                                  icon: const Icon(Icons.settings)),
                            )
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.all(3.0),
                          child: Divider(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Spindle",
                                  style: TextStyle(
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
                                            "Error: Feed Rate not specified");
                                      } else {
                                        _sendGCode(
                                            "G1 X0 Y${stepSizeY.text} F${feedRateController.text}");
                                        textsToDisplay.insert(0,
                                            "-> G1 X0 Y${stepSizeY.text} F${feedRateController.text}");
                                      }
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(width: 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("Y"),
                                        Icon(
                                          Icons.add,
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
                                            "Error: Feed Rate not specified");
                                      } else {
                                        _sendGCode(
                                            "G0 Z${stepSizeZ.text} F${feedRateController.text}");
                                        textsToDisplay.insert(0,
                                            "-> G0 Z${stepSizeZ.text} F${feedRateController.text}");
                                      }
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(width: 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("Z"),
                                        Icon(
                                          Icons.add,
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
                                            "Error: Feed Rate not specified");
                                      } else {
                                        _sendGCode(
                                            "G1 X-${stepSizeX.text} Y0 F${feedRateController.text}");
                                        textsToDisplay.insert(0,
                                            "-> G1 X-${stepSizeX.text} Y0 F${feedRateController.text}");
                                      }
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(width: 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("X"),
                                        Icon(
                                          Icons.remove,
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
                                        textsToDisplay.insert(
                                            0, "Error: Feed Rate no specified");
                                      } else {
                                        _sendGCode(
                                            "G1 X${stepSizeX.text} Y0 F${feedRateController.text}");
                                        textsToDisplay.insert(0,
                                            "-> G1 X${stepSizeX.text} Y0 F${feedRateController.text}");
                                      }
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(width: 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("X"),
                                        Icon(
                                          Icons.add,
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
                                        textsToDisplay.insert(
                                            0, "Error: Feed Rate no specified");
                                      } else {
                                        _sendGCode(
                                            "G1 X0 Y-${stepSizeY.text} F${feedRateController.text}");
                                        textsToDisplay.insert(0,
                                            "-> G1 X0 Y-${stepSizeY.text} F${feedRateController.text}");
                                      }
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(width: 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("Y"),
                                        Icon(
                                          Icons.remove,
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
                                        textsToDisplay.insert(
                                            0, "Error: Feed Rate no specified");
                                      } else {
                                        _sendGCode(
                                            "G0 Z-${stepSizeZ.text} F${feedRateController.text}");
                                        textsToDisplay.insert(0,
                                            "-> G0 Z-${stepSizeZ.text} F${feedRateController.text}");
                                      }
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(width: 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)))),
                                    child: const Row(
                                      children: [
                                        Text("Z"),
                                        Icon(
                                          Icons.remove,
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
          Column(
            children: [
              Expanded(
                  child: SizedBox(
                width: 600,
                child: Card(
                  elevation: 10.0,
                  shape: const RoundedRectangleBorder(),
                  child: Column(
                    children: [
                      const Text(
                        "Console",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20),
                          child: Card(
                            child: Container(
                                color: Colors.white,
                                child: ListView.builder(
                                    itemCount: 0,
                                    reverse: true,
                                    itemBuilder: (context, index) {
                                      return ListTile(title: Text("NONE"));
                                    })),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20),
                          child: Card(
                            child: Container(
                                color: Colors.white,
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
                          child: Container(
                            height: 50,
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
        ],
      ),
    );
  }
}
