import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ResponsiveScreen(),
    );
  }
}

class ResponsiveScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("22100035 - P3 - PALP")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          bool isLargeScreen = width > 600;

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: isLargeScreen ? buildGridLayout() : buildListLayout(),
          );
        },
      ),
    );
  }

  Widget buildGridLayout() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return buildBox(index, isLargeScreen: true);
      },
    );
  }

  Widget buildListLayout() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 5),
          child: buildBox(index, isLargeScreen: false),
        );
      },
    );
  }

  Widget buildBox(int index, {required bool isLargeScreen}) {
    double height = isLargeScreen ? (index % 2 == 0 ? 80 : 120) : 100;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        "Item ${index + 1}",
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
