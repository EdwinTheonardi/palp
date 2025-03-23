import 'package:flutter/material.dart';
import 'spoke_one_page.dart';
import 'spoke_two_page.dart';
import 'spoke_three_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hub and Spoke Navigation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HubPage(), // Halaman utama sebagai hub
    );
  }
}

class HubPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hub Page - Main Menu'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hub - Halaman Utama',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            // Navigasi ke Spoke 1
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (contett) => SpokeOnePage()),
                );
              }, 
              child: Text('Pergi ke Fitur 1'),
            ),
            SizedBox(height: 10),
            // Navigasi ke Spoke 2
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (contett) => SpokeTwoPage()),
                );
              }, 
              child: Text('Pergi ke Fitur 2'),
            ),
            SizedBox(height: 10),
            // Navigasi ke Spoke 3
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (contett) => SpokeThreePage()),
                );
              }, 
              child: Text('Pergi ke Fitur 3'),
            ),
          ],
        ),
      ),
    );
  }
}