import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/store_service.dart';

class AddShipmentPage extends StatefulWidget {
  const AddShipmentPage({super.key});

  @override
  State<AddShipmentPage> createState() => _AddShipmentPageState();
}

class _AddShipmentPageState extends State<AddShipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _formNumberController = TextEditingController();
  final _formReceiverNameController = TextEditingController();
  final _formPostDateController = TextEditingController();

  List<DocumentSnapshot> _products = [];

  final List<_DetailItem> _details = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final storeCode = await StoreService.getStoreCode();
      if (storeCode == null) return;

      final storeQuery = await FirebaseFirestore.instance
          .collection('stores')
          .where('code', isEqualTo: storeCode)
          .limit(1)
          .get();

      if (storeQuery.docs.isEmpty) return;
      final storeRef = storeQuery.docs.first.reference;


      final productSnap = await FirebaseFirestore.instance
          .collection('products')
          .where('store_ref', isEqualTo: storeRef)
          .get();

      setState(() {
        _products = productSnap.docs;
      });
    } catch (e) {
      debugPrint('Error fetching dropdown data: $e');
    }
  }

  int get itemTotal => _details.fold(0, (sum, item) => sum + item.qty);

  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate() ||
        _details.isEmpty) {
      return;
    }

    final storeCode = await StoreService.getStoreCode();
    if (storeCode == null) return;

    final storeQuery = await FirebaseFirestore.instance
        .collection('stores')
        .where('code', isEqualTo: storeCode)
        .limit(1)
        .get();

    if (storeQuery.docs.isEmpty) return;
    final storeRef = storeQuery.docs.first.reference;

    final shipment = {
      'no_form': _formNumberController.text.trim(),
      'receiver_name': _formReceiverNameController.text.trim(),
      'item_total': itemTotal,
      'post_date': _formPostDateController.text.trim(),
      'created_at': DateTime.now(),
      'store_ref': storeRef,
    };

    final shipmentDoc = await FirebaseFirestore.instance
        .collection('salesGoodsShipment')
        .add(shipment);

    for (final detail in _details) {
      await shipmentDoc.collection('details').add(detail.toMap());

      if (detail.productRef != null) {
        final productSnapshot = await detail.productRef!.get();
        final productData = productSnapshot.data() as Map<String, dynamic>?;

        if (productData != null) {
          final currentStock = productData['stock'] ?? 0;
          final updatedStock = currentStock - detail.qty;

          await detail.productRef!.update({'stock': updatedStock});
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }

  void _addDetail() {
    setState(() {
      _details.add(_DetailItem(products: _products));
    });
  }

  void _removeDetail(int index) {
    setState(() {
      _details.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Pengiriman')),
      body: _products.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KIRI: No Form, Supplier, Warehouse
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          TextFormField(
                            controller: _formNumberController,
                            decoration: InputDecoration(labelText: 'No. Form'),
                            validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                          ),
                          TextFormField(
                            controller: _formReceiverNameController,
                            decoration: InputDecoration(labelText: 'Nama Penerima'),
                            validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                          ),
                          TextFormField(
                            controller: _formPostDateController,
                            decoration: InputDecoration(labelText: 'Tanggal'),
                            validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 32), // Jarak antar kolom

                    // KANAN: Detail Produk
                    Expanded(
                      flex: 2,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Text('Detail Produk', style: TextStyle(fontWeight: FontWeight.bold)),
                          ..._details.asMap().entries.map((entry) {
                            final i = entry.key;
                            final item = entry.value;

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    DropdownButtonFormField<DocumentReference>(
                                      value: item.productRef,
                                      items: _products.map((doc) {
                                        return DropdownMenuItem(
                                          value: doc.reference,
                                          child: Text(doc['name']),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setState(() {
                                        item.productRef = value;
                                        item.unitName = 'pcs';
                                      }),
                                      decoration: InputDecoration(labelText: "Produk"),
                                      validator: (value) => value == null ? 'Pilih produk' : null,
                                    ),
                                    TextFormField(
                                      initialValue: item.qty.toString(),
                                      decoration: InputDecoration(labelText: "Jumlah"),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) => setState(() => item.qty = int.tryParse(val) ?? 1),
                                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                                    ),
                                    SizedBox(height: 8),
                                    Text("Satuan: ${item.unitName}"),
                                    TextButton.icon(
                                      onPressed: () => _removeDetail(i),
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      label: Text("Hapus"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          ElevatedButton.icon(
                            onPressed: _addDetail,
                            icon: Icon(Icons.add),
                            label: Text('Tambah Produk'),
                          ),
                          SizedBox(height: 16),
                          Text("Item Total: $itemTotal"),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _saveReceipt,
                            child: Text("Simpan Shipment"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DetailItem {
  DocumentReference? productRef;
  int price = 0;
  int qty = 1;
  String unitName = 'unit';
  final List<DocumentSnapshot> products;

  _DetailItem({required this.products});

  int get subtotal => price * qty;

  Map<String, dynamic> toMap() {
    return {
      'product_ref': productRef,
      'qty': qty,
      'unit_name': unitName,
    };
  }
}
