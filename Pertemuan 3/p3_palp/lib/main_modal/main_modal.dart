import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modal Navigation Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  void _showSimpleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah anda yakin ingin melanjutkan?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                print('Aksi dilanjutkan');
              },
              child: Text('Lanjut'),
            ),
          ],
        );
      },
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Aksi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Data'),
                onTap: () {
                  Navigator.pop(context);
                  print('Edit data dipilih');
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Hapus Data'),
                onTap: () {
                  Navigator.pop(context);
                  print('Hapus data dipilih');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modal Navigation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _showSimpleDialog(context);
              },
              child: Text('Tampilkan Dialog Konfirmasi'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showBottomSheet(context);
              },
              child: Text('Tampilkan Bottom Sheet'),
            ),
          ],
        ),
      ),
    );
  }
}