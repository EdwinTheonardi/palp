import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'add_note_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Liburan',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: NotesPage(),
    );
  }
}

class NotesPage extends StatelessWidget {
  final CollectionReference notes =
    FirebaseFirestore.instance.collection('notes');

  NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Catatan Liburan"),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              tooltip: "Tambah Catatan",
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => AddNotePage())
                );
              },
            )
          ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notes.orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Belum ada catatan."));
          }

          final docs = snapshot.data!.docs;

          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['author'] == 'Edwin';
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(child: Text("Belum ada catatan."));
          }

          return ListView(
            children: filteredDocs.map((DocumentSnapshot document) {
              final data = document.data()! as Map <String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['title'] ?? '-'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Penulis: ${data['author'] ?? '-'}",
                      ),
                      SizedBox(height: 4),
                      Text(data['content'] ?? '-'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: "Hapus Catatan",
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, document.id);
                        },
                      ),
                      data['synced'] == true
                        ? Icon(Icons.cloud_done, color: Colors.green)
                        : Icon(Icons.cloud_off, color: Colors.grey),
                    ],
                  ),
                  ),
                );
            }).toList(),
          );
        },
      ),
    );
  }
}

void _showDeleteConfirmationDialog(BuildContext context, String documentId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content: Text('Apakah kamu yakin ingin menghapus catatan ini?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteNote(context, documentId);
              Navigator.of(context).pop();
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

Future<void> _deleteNote(BuildContext context, String documentId) async {
  try {
    await FirebaseFirestore.instance.collection('notes').doc(documentId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Catatan berhasil dihapus')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal menghapus catatan')),
    );
  }
}
