// ignore_for_file: avoid_print

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'data_footprints.dart';

class CompAndPartsSection {
  SizedBox sideSection(List<Package> packages) {
    return SizedBox(
      width: 300.0,
      child: Column(
        children: [componentLibrary(packages), partSection()],
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
                            print("Component Clicked: ${component.name}");
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

  Expanded partSection() {
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
                child: const Card(
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  elevation: 0,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
