import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'dart:typed_data';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GRBL Serial Communication',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SerialCommunicationPage(),
    );
  }
}

class SerialCommunicationPage extends StatefulWidget {
  @override
  _SerialCommunicationPageState createState() =>
      _SerialCommunicationPageState();
}

class _SerialCommunicationPageState extends State<SerialCommunicationPage> {
  List<String> availablePorts = [];
  SerialPort? selectedPort;
  SerialPortReader? reader;
  String grblResponse = '';
  StringBuffer responseBuffer = StringBuffer();

  @override
  void initState() {
    super.initState();
    _listAvailablePorts();
  }

  // List all available serial ports
  void _listAvailablePorts() {
    try {
      availablePorts = SerialPort.availablePorts;
      setState(() {});
      print('Available ports: $availablePorts');
    } catch (e) {
      print('Failed to list ports: $e');
    }
  }

  // Connect to the selected port
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
        reader = SerialPortReader(selectedPort!);
        reader!.stream.listen((data) {
          final response = String.fromCharCodes(data);

          // Append the new data to the buffer
          responseBuffer.write(response);

          // Check if the response contains a newline character, which signifies the end of the response
          if (response.contains('\n')) {
            setState(() {
              grblResponse = responseBuffer.toString().trim();
              responseBuffer.clear(); // Clear the buffer for the next response
            });

            // Print the response to the debug console
            print('GRBL Response: $grblResponse');
          }
        });
      } else {
        print('Failed to open port');
      }
    } catch (e) {
      print('Exception occurred while connecting: $e');
    }
  }

  // Send G-code command to GRBL
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

  // Disconnect from the port
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
      appBar: AppBar(
        title: Text('GRBL Serial Communication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown to select a serial port
            const Text('Select Serial Port:'),
            DropdownButton<String>(
              value: availablePorts.isNotEmpty ? availablePorts.first : null,
              hint: const Text('Select a port'),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _connectToPort(newValue);
                }
              },
              items:
                  availablePorts.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Send G-code button
            ElevatedButton(
              onPressed: () {
                _sendGCode('G01 X10 Y10 F500'); // Example G-code command
              },
              child: Text('Send G-code'),
            ),
            SizedBox(height: 20),

            // Display GRBL response
            Text(
              'GRBL Response:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(grblResponse.isNotEmpty
                ? grblResponse
                : 'No response received yet'),

            SizedBox(height: 20),

            // Disconnect button
            ElevatedButton(
              onPressed: _disconnectPort,
              child: Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disconnectPort();
    super.dispose();
  }
}
