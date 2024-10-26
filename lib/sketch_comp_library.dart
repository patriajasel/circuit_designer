// ignore_for_file: avoid_print

import 'package:circuit_designer/draggable_footprints.dart';
import 'package:circuit_designer/footprints_bounding_box.dart';
import 'package:circuit_designer/line_traces.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'data_footprints.dart';

class CompAndPartsSection extends StatefulWidget {
  final Function(DraggableFootprints) passComp;
  final Offset position;
  final List<Package> packages;
  final List<DraggableFootprints> footprints;
  final List<Line> lines;
  final Function rebuildState;
  final Function updateLines;
  const CompAndPartsSection(
      {super.key,
      required this.position,
      required this.passComp,
      required this.packages,
      required this.footprints,
      required this.lines,
      required this.rebuildState,
      required this.updateLines});

  @override
  State<CompAndPartsSection> createState() => _CompAndPartsSectionState();
}

class _CompAndPartsSectionState extends State<CompAndPartsSection> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300.0,
      child: Column(
        children: [
          componentLibrary(widget.packages),
          partSection(widget.footprints, widget.lines)
        ],
      ),
    );
  }

  // This is the component library section
  Expanded componentLibrary(List<Package> packages) {
    final TextEditingController searchTextController = TextEditingController();
    return Expanded(
        child: Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 10.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            child: Padding(
              padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              child: Text(
                "Component's Library",
                style: TextStyle(fontFamily: "Arvo", fontSize: 16.0),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            child: Divider(thickness: 2),
          ),
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoSearchTextField(
                backgroundColor: Colors.white,
                placeholder: "Search Components...",
                style: const TextStyle(fontSize: 14.0),
                controller: searchTextController,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 0,
                color: Colors.white,
                child: ListView.builder(
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final package = packages[index];
                    return ExpansionTile(
                      title: Text(
                        package.packageType,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: package.components.map((component) {
                        return ListTile(
                          title: Text(component.name),
                          onTap: () {
                            setState(() {
                              // For passing the component and adding dragging features.
                              widget.passComp(DraggableFootprints(
                                  component: component,
                                  position: widget.position,
                                  isSelected: false,
                                  isHovered: false,
                                  boundingBox:
                                      BoundingBox.calculate(component)));
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          )
        ],
      ),
    ));
  }

  // This is the for the pcb parts section
  Expanded partSection(List<DraggableFootprints> footprints, List<Line> lines) {
    final TextEditingController lineWidth = TextEditingController(text: "1.0");
    return Expanded(
      child: Card(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 10.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                child: Text(
                  "Parts Section",
                  style: TextStyle(fontFamily: "Arvo", fontSize: 16.0),
                ),
              ),
            ),

            // This is the section that shows the footprints inside the canvas
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8.0),
                child: Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                  elevation: 0,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: footprints.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            footprints[index].isSelected =
                                !footprints[index].isSelected;
                          });
                        },
                        child: MouseRegion(
                          onEnter: (PointerEvent event) {
                            setState(() {
                              footprints[index].isHovered = true;
                            });
                          },
                          onExit: (PointerEvent event) {
                            setState(() {
                              footprints[index].isHovered = false;
                            });
                          },
                          child: Container(
                            clipBehavior: Clip.none,
                            padding: const EdgeInsets.all(10.0),
                            color: footprints[index].isHovered
                                ? Colors.blue.shade50
                                : footprints[index].isSelected
                                    ? Colors.blue.shade100
                                    : null,
                            height: 40,
                            width: double.infinity,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  footprints[index].component.name,
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // This is the section that shows the traces inside the canvas
            const SizedBox(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                child: Text(
                  "Line Traces",
                  style: TextStyle(fontFamily: "Arvo", fontSize: 16.0),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8.0),
                child: Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                  elevation: 0,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onDoubleTap: () {
                          showDialog(
                              context: context,
                              builder: (builder) {
                                return AlertDialog(
                                  actionsPadding: EdgeInsets.zero,
                                  actions: [
                                    Center(
                                      child: Container(
                                        height: 200,
                                        width: 200,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.all(5.0),
                                              child: Text(
                                                "Enter Line Width",
                                                style: TextStyle(
                                                    fontFamily: "Arvo",
                                                    fontSize: 16),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 30,
                                                      horizontal: 10),
                                              child: TextField(
                                                controller: lineWidth,
                                                decoration: const InputDecoration(
                                                    hintText: "in millimeter",
                                                    labelText: "Line Width",
                                                    border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    10)))),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    for (var line in lines) {
                                                      setState(() {
                                                        if (line.isSelected) {
                                                          line.thickness =
                                                              double.parse(
                                                                  lineWidth
                                                                      .text);
                                                        }
                                                      });
                                                    }

                                                    widget.updateLines(
                                                        List<Line>.from(lines));

                                                    widget.rebuildState();
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("Proceed"),
                                                ),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text("Cancel"))
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              });
                        },
                        onTap: () {
                          setState(() {
                            lines[index].isSelected = !lines[index].isSelected;
                          });
                          widget.rebuildState();
                        },
                        child: MouseRegion(
                          onEnter: (PointerEvent event) {
                            setState(() {
                              lines[index].isHovered = true;
                            });
                            widget.rebuildState();
                          },
                          onExit: (PointerEvent event) {
                            setState(() {
                              lines[index].isHovered = false;
                            });
                            widget.rebuildState();
                          },
                          child: Container(
                            clipBehavior: Clip.none,
                            padding: const EdgeInsets.all(10.0),
                            color: lines[index].isHovered
                                ? Colors.blue.shade50
                                : lines[index].isSelected
                                    ? Colors.blue.shade100
                                    : null,
                            height: 40,
                            width: double.infinity,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  lines[index].name,
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
