import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

// TODO: Add comments to the new code added
// TODO: Make the popup window border less rounded
// TODO: Make File Directory Textfield not writeable
// TODO: Make File Name Textfield character restrictions
// TODO: Make Dropdown menu for picking pcb Sizes
// TODO: Make Actions button like Proceed and Cancel

class _StartPageState extends State<StartPage> {
  String? directoryPath;

  Future<void> _pickDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      setState(() {
        directoryPath = selectedDirectory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // * This is the side menu section
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
                          "Other Options",
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
                      _sideMenuOptions(
                          "Import Design", Icons.cloud_upload_rounded),
                      _sideMenuOptions(
                          "CNC Controls", Icons.settings_remote_rounded),
                      _sideMenuOptions("User Manual", Icons.menu_book_rounded),
                      _sideMenuOptions("About Us", Icons.info_outline_rounded)
                    ],
                  ),
                ),
              ),
            ],
          ),

          // * This is the main section
          Expanded(
            child: Container(
              color: const Color(0xFF333333),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent.shade400,
                            Colors.purpleAccent.shade400
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.all(20),
                    width: double.infinity,
                    height: 75.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: () {
                        _showNewDesignDialog(context, _pickDirectory);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 30,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Create New Design',
                            style: TextStyle(
                                fontSize: 16.0,
                                fontFamily: "Arvo",
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: Divider(
                      thickness: 2,
                    ),
                  ),
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
                                  _sideIconButtons(Icons.search),
                                  _sideIconButtons(Icons.grid_on),
                                  _sideIconButtons(Icons.delete)
                                ],
                              ),
                            ),
                          ],
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
}

Container _sideMenuOptions(String optionsName, IconData icon) {
  return Container(
    margin: const EdgeInsets.all(15),
    width: double.infinity,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5), color: const Color(0xFF5B5B5B)),
    child: TextButton(
      onPressed: () {
        // ! Button action here!
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

Container _sideIconButtons(IconData icon) {
  return Container(
    margin: const EdgeInsets.only(right: 10),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF5B5B5B)),
    child: IconButton(
      onPressed: () {},
      icon: Icon(
        icon,
        size: 16.0,
        color: Colors.white,
      ),
    ),
  );
}

void _showNewDesignDialog(BuildContext context, Function() pickDirectory) {
  TextEditingController fileName = TextEditingController();
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("New Design"),
          titleTextStyle: const TextStyle(
              fontSize: 16.0, fontFamily: "Arvo", color: Colors.black),
          content: SizedBox(
            width: 300,
            child: Column(
              children: [
                const Divider(),
                const SizedBox(
                  height: 50,
                ),
                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: fileName,
                    decoration: InputDecoration(
                        suffixIcon: IconButton(
                            onPressed: () {
                              fileName.clear();
                            },
                            icon: const Icon(
                              Icons.clear,
                              size: 12,
                            )),
                        border: const OutlineInputBorder(),
                        hintText: "File Name",
                        hintStyle: const TextStyle(
                          fontSize: 12.0,
                        )),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                        suffixIcon: IconButton(
                            onPressed: () {
                              pickDirectory();
                            },
                            icon: const Icon(
                              Icons.folder_open,
                              size: 12,
                            )),
                        border: const OutlineInputBorder(),
                        hintText: "File Directory",
                        hintStyle: const TextStyle(
                          fontSize: 12.0,
                        )),
                  ),
                )
              ],
            ),
          ),
        );
      });
}
