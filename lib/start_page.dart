import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  // TODO: Add Hovered effect for button sizes
  // TODO: Add Navigation Routes
  // TODO: Add Background Image

  String currentHoverText =
      "PCB Sketch is a free to use software for PCB footprint designing, PCB engraving and PCB drilling.";

  List<String> hoverTexts = [
    "PCB Sketch is a free to use software for PCB footprint designing, PCB engraving and PCB drilling.",
    "Upload, View and Edit your existing PCB design with our editor.",
    "Create your own PCB design using our own library of components.",
    "Control your CNC Machine for prototyping your PCB design to your Copper Board."
  ];

  //* This is for changing the text at the bottom depending on the hovered button
  void _updateHoverText(int index) {
    setState(() {
      currentHoverText = hoverTexts[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    const String appTitle = "PCB SKETCH"; // application title
    const String logoPath =
        "lib/assets/logo/logo.png"; // path for the logo of the app
    const TextStyle titleStyle = TextStyle(
        // Text style for the title
        fontFamily: "Protest",
        fontSize: 56,
        fontWeight: FontWeight.bold,
        letterSpacing: 5,
        color: Color(0xFF14243E));

    return Scaffold(
        body: Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // * This is the top section of the app displaying the logo and the title

          Row(
            children: [
              Image.asset(logoPath, width: 100, height: 100, fit: BoxFit.cover),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: const Text(appTitle, style: titleStyle),
              )
            ],
          ),

          // * This is the middle section of the app displaying the buttons

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 0),
            child: Card(
              elevation: 4.0,
              color: const Color(0xFF233C69),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: Colors.black, width: 2)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 50, left: 50, top: 100, bottom: 50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // * This section is the displaying the buttons by passing the parameters on the method buttonWithABottomText

                        buttonWithABottomText(
                            "Import",
                            "Design",
                            "lib/assets/images/buttons/import.png",
                            1,
                            _updateHoverText),
                        buttonWithABottomText(
                            "Create",
                            "Design",
                            "lib/assets/images/buttons/create.png",
                            2,
                            _updateHoverText),
                        buttonWithABottomText(
                            "CNC",
                            "Controls",
                            "lib/assets/images/buttons/controls.png",
                            3,
                            _updateHoverText),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        currentHoverText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: "Protest",
                            fontSize: 14,
                            letterSpacing: 2,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

// * This it the method that generates a button

Column buttonWithABottomText(String firstText, String secondText,
    String imagePath, int hoverIndex, Function(int) updateHoverText) {
  const TextStyle buttonStyle = TextStyle(
      // Text Style for the bottom text of the button
      fontFamily: "Protest",
      fontSize: 16,
      letterSpacing: 2,
      fontWeight: FontWeight.bold,
      color: Colors.white);

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      MouseRegion(
        onEnter: (_) => updateHoverText(hoverIndex),
        onExit: (_) => updateHoverText(0),
        child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF3660A4),
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                )),
            onPressed: () {},
            child: Column(
              children: [
                Image.asset(imagePath,
                    width: 75, height: 75, fit: BoxFit.cover),
              ],
            )),
      ),
      const SizedBox(height: 15),
      Text(firstText.toUpperCase(), style: buttonStyle),
      Text(secondText.toUpperCase(), style: buttonStyle)
    ],
  );
}
