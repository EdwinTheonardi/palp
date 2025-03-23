// import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: AppBar(title: Text("22100035 - Edwin Theonardi")),
//         body: LayoutBuilder(
//           builder: (context, constraints) {
//             bool isLargeScreen = constraints.maxWidth > 600;

//             return isLargeScreen
//                 ? GridView.count(
//                     crossAxisCount: 3,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     padding: EdgeInsets.all(16),
//                     children: List.generate(6, (index) => buildBox(index)),
//                   )
//                 : ListView(
//                     padding: EdgeInsets.all(16),
//                     children: List.generate(6, (index) => buildBox(index)),
//                   );
//           },
//         ),
//       ),
//     );
//   }

//   Widget buildBox(int index) {
//     return Container(
//       height: 100,
//       margin: EdgeInsets.symmetric(vertical: 5),
//       decoration: BoxDecoration(
//         color: Colors.blueAccent,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       alignment: Alignment.center,
//       child: Text(
//         "Item ${index + 1}",
//         style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }
