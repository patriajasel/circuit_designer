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
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          //  This is the side menu section
          Column(
            children: [
              Expanded(
                child: Container(
                  width: 250,
                  color: const Color(0xFF454545),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: const Text(
                          "Start Here",
                          style: TextStyle(
                              fontSize: 18.0,
                              fontFamily: "Arvo",
                              color: Colors.white),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15.0),
                        child: Divider(
                          thickness: 2,
                        ),
                      ),

                      // * This is the section for Side navigation Buttons
                      _sideMenuOptions(
                          "Create Design", Icons.polyline_rounded, "/Sketch"),
                      _sideMenuOptions("Import Design",
                          Icons.cloud_upload_rounded, "/Sketch"),
                      _sideMenuOptions("CNC Controls",
                          Icons.settings_remote_rounded, "/Sketch"),
                      _sideMenuOptions(
                          "User Manual", Icons.menu_book_rounded, "/Sketch"),
                      _sideMenuOptions(
                          "About Us", Icons.info_outline_rounded, "/Sketch")
                    ],
                  ),
                ),
              ),
            ],
          ),

          //  This is the main section
          Expanded(
            child: Container(
              color: const Color(0xFF333333),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(15.0),
                              child: Text(
                                "Recent Projects",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontFamily: "Arvo",
                                    color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // This is the section for Searching, Sorting and Deleting recent projects
                                  _sideIconButtons(Icons.search),
                                  _sideIconButtons(Icons.grid_on),
                                  _sideIconButtons(Icons.delete)
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: Divider(
                            thickness: 2,
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
  Container _sideMenuOptions(
      String optionsName, IconData icon, String routeName) {
    return Container(
      margin: const EdgeInsets.all(15),
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: const Color(0xFF5B5B5B)),
      child: TextButton(
        onPressed: () {
          // ! Button action here!
          _navigator(routeName);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              optionsName,
              style: const TextStyle(
                  fontSize: 14.0, fontFamily: "Arvo", color: Colors.white),
            ),
          ],
        ),
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
