import 'package:flutter/material.dart';
import 'third_page.dart';

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text (
              'Halaman Kedua',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigasi ke halaman ke tiga
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ThirdPage()),
                );
              },
              child: Text('Pergi ke Halaman Ketiga'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Kembali ke halaman sebelumnya
                Navigator.pop(context);
              }, 
              child: Text('Kembali ke Halaman Utama')),
          ],
        )
      )
    );
  }
}