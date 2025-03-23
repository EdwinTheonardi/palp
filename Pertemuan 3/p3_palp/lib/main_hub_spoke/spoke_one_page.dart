import 'package:flutter/material.dart';

class SpokeOnePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fitur 1 - Spoke 1'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Halaman Fitur 1', style: TextStyle(fontSize: 24)),
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