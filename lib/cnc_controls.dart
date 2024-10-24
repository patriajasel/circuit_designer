// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:window_manager/window_manager.dart';

class CncControls extends StatefulWidget {
  const CncControls({super.key});

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

  void _listAvailablePorts() {
    try {
      availablePorts = SerialPort.availablePorts;
      setState(() {});
      print('Available ports: $availablePorts');
    } catch (e) {
      print('Failed to list ports: $e');
    }
  }

  StreamSubscription<Uint8List>? _subscription;

  void _connectToPort(String portName) {
    try {
      selectedPort = SerialPort(portName);

      // Configure the serial port
      selectedPort!.config.baudRate = 115200; // Example baud rate
      selectedPort!.config.bits = 8;
      selectedPort!.config.parity = SerialPortParity.none;
      selectedPort!.config.stopBits = 1;

      if (selectedPort!.openReadWrite()) {
        print('Connected to $portName');

        // Ensure only one listener is attached
        if (_subscription == null) {
          reader = SerialPortReader(selectedPort!);

          _subscription = reader!.stream.listen((data) {
            final response = String.fromCharCodes(data);

            // Append the new data to the buffer
            responseBuffer.write(response);

            // Check if the response contains a newline character, which signifies the end of the response
            if (response.contains('\n')) {
              setState(() {
                grblResponse = responseBuffer.toString().trim();
                textsToDisplay.insert(
                    0, grblResponse); // Store the response in the list
                responseBuffer
                    .clear(); // Clear the buffer for the next response
              });

              // Print the response to the debug console
              print('GRBL Response: $grblResponse');
            }
          });
        } else {
          print('Stream already being listened to.');
        }
      } else {
        print('Failed to open port');
      }
    } catch (e) {
      print('Exception occurred while connecting: $e');
    }
  }

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

  void _disconnectPort() {
    if (selectedPort != null && selectedPort!.isOpen) {
      try {
        selectedPort!.close();
        setState(() {
          selectedPort = null;
          grblResponse = '';
        });
        print('Disconnected from port');
      } catch (e) {
        print('Exception occurred while disconnecting: $e');
      }
    }
  }

  // Method to listen for GRBL response
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
            textsToDisplay.insert(0, grblResponse);
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
                                    isConnected ? "Disconnect" : "Connect"))
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
                              value: availablePorts.isNotEmpty
                                  ? availablePorts.first
                                  : null, // Default selected port
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
                        const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Text(
                            "Manual Controls",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
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
                                    onPressed: () {},
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
                                    onPressed: () {},
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
                                    onPressed: () {},
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
                                    onPressed: () {},
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
                                    onPressed: () {},
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
                                    onPressed: () {},
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
                width: 700,
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
          )
        ],
      ),
    );
  }
}
