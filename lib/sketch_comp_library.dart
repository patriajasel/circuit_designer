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
  const CompAndPartsSection(
      {super.key,
      required this.position,
      required this.passComp,
      required this.packages,
      required this.footprints,
      required this.lines,
      required this.rebuildState});

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

  Expanded partSection(List<DraggableFootprints> footprints, List<Line> lines) {
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
            // For the Line Traces section
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
                          for (var line in lines) {
                            line.thickness = 2.0;
                          }
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
