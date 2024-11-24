import 'package:circuit_designer/sketch_menubar.dart';
import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          //  This is the side menu section
          Column(
            children: [
              Expanded(
                child: Container(
                  width: screenWidth * 0.25,
                  margin: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.01,
                      vertical: screenHeight * 0.03),
                  decoration: BoxDecoration(
                      color: Colors.blueGrey.shade900,
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.005,
                            vertical: screenHeight * 0.015),
                        child: Row(
                          children: [
                            Image.asset(
                              "lib/assets/logo/logo.png",
                              scale: 7,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.005,
                                  vertical: screenHeight * 0.015),
                              child: const Text(
                                "CREATIVE CIRCUITS",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Righteous"),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.02,
                            vertical: screenHeight * 0.06),
                        child: Column(
                          children: [
                            _sideMenuOptions(
                                "Create PCB Design",
                                Icons.polyline_rounded,
                                "/Sketch",
                                false,
                                screenHeight,
                                screenWidth),
                            _sideMenuOptions(
                                "Open Existing Design",
                                Icons.folder_open,
                                "/Sketch",
                                true,
                                screenHeight,
                                screenWidth),
                            _sideMenuOptions(
                                "CNC Controls",
                                Icons.settings_remote_rounded,
                                "/Controls",
                                false,
                                screenHeight,
                                screenWidth),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _sideMenuOptions(
                                "User Manual",
                                Icons.menu_book_rounded,
                                "/Sketch",
                                false,
                                screenHeight,
                                screenWidth),
                            _sideMenuOptions(
                                "About Us",
                                Icons.info_outline_rounded,
                                "/Sketch",
                                false,
                                screenHeight,
                                screenWidth)
                          ],
                        ),
                      )

                      // * This is the section for Side navigation Buttons
                    ],
                  ),
                ),
              ),
            ],
          ),

          //  This is the main section
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.01,
                  vertical: screenHeight * 0.03),
              decoration: BoxDecoration(
                  color: Colors.blueGrey.shade900,
                  borderRadius: BorderRadius.circular(10.0)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  top: screenHeight * 0.045,
                                  left: screenWidth * 0.03,
                                  bottom: screenHeight * 0.01),
                              child: const Text(
                                "RECENT PROJECTS",
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontFamily: "Righteous",
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02),
                          child: const Divider(
                            thickness: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  //  This is the method for generating Text Navigation buttons.
  MouseRegion _sideMenuOptions(
      String optionsName,
      IconData icon,
      String routeName,
      bool isImport,
      double screenHeight,
      double screenWidth) {
    final hoverNotifier = ValueNotifier<bool>(false);

    return MouseRegion(
      onEnter: (_) => hoverNotifier.value = true,
      onExit: (_) => hoverNotifier.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: hoverNotifier,
        builder: (context, hover, child) {
          return Container(
            margin: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.005,
                vertical: screenHeight * 0.015),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.0025,
                vertical: screenHeight * 0.0075),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color:
                  hover ? Colors.lightGreenAccent.shade700 : Colors.transparent,
            ),
            child: TextButton(
              onPressed: () async {
                if (isImport) {
                  await importDesign(context);
                } else {
                  _navigator(routeName);
                }
              },
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: screenWidth * 0.0015),
                  Text(
                    optionsName,
                    style: const TextStyle(fontSize: 14.0, color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  //  Navigation Method here
  void _navigator(String routeName) {
    Navigator.pushNamed(context, routeName);
  }
}
