import 'package:flutter/material.dart';

class SpokeThreePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fitur 3 - Spoke 3'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Halaman Fitur 3', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Kembali ke Hub
              },
              child: Text('Kembali ke Hub'),
            ),
          ],
        ),
      ),
    );
  }
}