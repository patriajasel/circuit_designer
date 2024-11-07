import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          //  This is the side menu section
          Column(
            children: [
              Expanded(
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            Image.asset(
                              "lib/assets/logo/logo.png",
                              scale: 7,
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
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
                        margin: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            _sideMenuOptions("Create PCB Design",
                                Icons.polyline_rounded, "/Sketch"),
                            _sideMenuOptions("Open Existing Design",
                                Icons.folder_open, "/Sketch"),
                            _sideMenuOptions("CNC Controls",
                                Icons.settings_remote_rounded, "/Controls"),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _sideMenuOptions("User Manual",
                                Icons.menu_book_rounded, "/Sketch"),
                            _sideMenuOptions("About Us",
                                Icons.info_outline_rounded, "/Sketch")
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
              margin: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(10.0)),
              child: const Column(
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
                                  top: 30.0, left: 20.0, bottom: 10.0),
                              child: Text(
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
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: Divider(
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
      String optionsName, IconData icon, String routeName) {
    final hoverNotifier = ValueNotifier<bool>(false);

    return MouseRegion(
      onEnter: (_) => hoverNotifier.value = true,
      onExit: (_) => hoverNotifier.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: hoverNotifier,
        builder: (context, hover, child) {
          return Container(
            margin: const EdgeInsets.all(10),
            width: double.infinity,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color:
                  hover ? Colors.lightGreenAccent.shade700 : Colors.transparent,
            ),
            child: TextButton(
              onPressed: () {
                _navigator(routeName);
              },
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
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

  //  This is the section for the Recent project Buttons

  Container _sideIconButtons(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF5B5B5B)),
      child: IconButton(
        onPressed: () {
          // ! Button action here!
        },
        icon: Icon(
          icon,
          size: 16.0,
          color: Colors.white,
        ),
      ),
    );
  }

  //  Navigation Method here
  void _navigator(String routeName) {
    Navigator.pushNamed(context, routeName);
  }
}
