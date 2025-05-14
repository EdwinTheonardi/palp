import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/store_service.dart';
import 'firebase_options.dart';
import 'add_receipt.dart';
import 'edit_receipt.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  String? storeCode = await StoreService.getStoreCode();
  if (storeCode == null) {
    try {
      await StoreService.initStore("22100035");
    } catch (e) {
      print("Gagal menginisialisasi store: $e");
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Penerimaan Barang',
      debugShowCheckedModeBanner: false,
      home: ReceiptPage(),
    );
  }
}

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({ super.key });

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  DocumentReference? _storeRef;
  List<DocumentSnapshot> _allReceipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReceiptsForStore();
  }

  Future<void> _loadReceiptsForStore() async {
    final storeCode = await StoreService.getStoreCode();

    if (storeCode == null || storeCode.isEmpty) {
      print("Store code tidak ditemukan.");
      setState(() => _loading = false);
      return;
    }

    try {
      final storeSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('code', isEqualTo: storeCode)
          .limit(1)
          .get();

      if (storeSnapshot.docs.isEmpty) {
        print("Store dengan code $storeCode tidak ditemukan.");
        setState(() => _loading = false);
        return;
      }

      final storeDoc = storeSnapshot.docs.first;
      final storeRef = storeDoc.reference;

      print("Store reference ditemukan: ${storeRef.path}");

      final receiptsSnapshot = await FirebaseFirestore.instance
          .collection('purchaseGoodsReceipts')
          .where('store_ref', isEqualTo: storeRef)
          .get();

      setState(() {
        _storeRef = storeRef;
        _allReceipts = receiptsSnapshot.docs;
        _loading = false;
      });
    } catch (e) {
      print("Gagal memuat data: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Penerimaan Barang'),
      ),
      body: Stack(
        children: [
          _loading
              ? Center(child: CircularProgressIndicator())
              : _allReceipts.isEmpty
                  ? Center(child: Text('Tidak ada data penerimaan'))
                  : RefreshIndicator(
                      onRefresh: _loadReceiptsForStore,
                      child: ListView.builder(
                        itemCount: _allReceipts.length,
                        itemBuilder: (context, index) {
                          final receipt = _allReceipts[index].data() as Map<String, dynamic>;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Table(
                                columnWidths: {
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(1),
                                },
                                children: [
                                  // Baris 1: Judul
                                  TableRow(
                                    children: [
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Text(
                                            'No Form: ${receipt['no_form'] ?? '-'}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit, color: Colors.lightBlue),
                                              tooltip: "Edit Catatan",
                                              onPressed: () async {
                                                final updated = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => EditReceiptPage(
                                                      receiptRef: _allReceipts[index].reference,
                                                    ),
                                                  ),
                                                );
                                                await _loadReceiptsForStore(); // Refresh list setelah kembali
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.lightBlue),
                                              tooltip: "Hapus Catatan",
                                              onPressed: () async {
                                                _showDeleteConfirmationDialog(
                                                  context,
                                                  _allReceipts[index].reference,
                                                );                          
                                                await _loadReceiptsForStore(); 
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Baris 2: Info kiri & kanan
                                  TableRow(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Created At: ${receipt['created_at']?.toDate() ?? '-'}'),
                                          Text('Post Date: ${receipt['post_date'] ?? '-'}'),
                                          Text('Grand Total: ${receipt['grandtotal'] ?? '-'}'),
                                          Text('Item Total: ${receipt['item_total'] ?? '-'}'),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Synced: ${receipt['synced'] != null ? receipt['synced'].toString() : '-'}'),
                                          Text('Store Ref: ${receipt['store_ref']?.path ?? '-'}'),
                                          Text('Supplier Ref: ${receipt['supplier_ref']?.path ?? '-'}'),
                                          Text('Warehouse Ref: ${receipt['warehouse_ref']?.path ?? '-'}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Baris 3: Tombol
                                  TableRow(
                                    children: [
                                      TableCell(child: SizedBox()), // Kosong
                                      TableCell(
                                        child: Align(
                                          alignment: Alignment.bottomRight,
                                          child: TextButton(
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ReceiptDetailsPage(
                                                    receiptRef: _allReceipts[index].reference,
                                                  ),
                                                ),
                                              );
                                              await _loadReceiptsForStore();
                                            },
                                            child: Text("Lihat Detail"),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          // Tombol Tambah di kanan bawah
          Positioned(
            bottom: 16,
            right: 16,
            child: SizedBox(
              width: 180,
              height: 45,
              child: ElevatedButton(  
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddReceiptPage()),
                  );
                  await _loadReceiptsForStore(); // Refresh data setelah tambah
                },
                child: Text('Tambah Receipt'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, DocumentReference ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Yakin ingin menghapus receipt ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // Hapus detail dan dokumen utama
      final details = await ref.collection('details').get();
      for (final doc in details.docs) {
        await doc.reference.delete();
      }
      await ref.delete();
      await _loadReceiptsForStore();
    }
  }
}

class ReceiptDetailsPage extends StatefulWidget {
  final DocumentReference receiptRef;

  const ReceiptDetailsPage({super.key, required this.receiptRef});

  @override
  State<ReceiptDetailsPage> createState() => _ReceiptDetailsPageState();
}

class _ReceiptDetailsPageState extends State<ReceiptDetailsPage> {
  List<DocumentSnapshot> _allDetails = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final detailsSnapshot =
          await widget.receiptRef.collection('details').get();

      setState(() {
        _allDetails = detailsSnapshot.docs;
        _loading = false;
      });
    } catch (e) {
      print("Gagal memuat detail: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allDetails.isEmpty
              ? const Center(child: Text('Tidak ada detail produk.'))
              : ListView.builder(
                  itemCount: _allDetails.length,
                  itemBuilder: (context, index) {
                    final data =
                        _allDetails[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Product Ref: ${data['product_ref']?.path ?? '-'}"),
                            Text("Qty: ${data['qty'] ?? '-'}"),
                            Text("Unit: ${data['unit_name'] ?? '-'}"),
                            Text("Price: ${data['price'] ?? '-'}"),
                            Text("Subtotal: ${data['subtotal'] ?? '-'}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}