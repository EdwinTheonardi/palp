import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/store_service.dart';

class AddReceiptPage extends StatefulWidget {
  const AddReceiptPage({super.key});

  @override
  State<AddReceiptPage> createState() => _AddReceiptPageState();
}

class _AddReceiptPageState extends State<AddReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final _formNumberController = TextEditingController();

  DocumentReference? _selectedSupplier;
  DocumentReference? _selectedWarehouse;
  List<DocumentSnapshot> _suppliers = [];
  List<DocumentSnapshot> _warehouses = [];
  List<DocumentSnapshot> _products = [];

  final List<_DetailItem> _details = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final supplierSnap = await FirebaseFirestore.instance.collection('suppliers').get();
    final warehouseSnap = await FirebaseFirestore.instance.collection('warehouses').get();
    final productSnap = await FirebaseFirestore.instance.collection('products').get();

    setState(() {
      _suppliers = supplierSnap.docs;
      _warehouses = warehouseSnap.docs;
      _products = productSnap.docs;
    });
  }

  int get itemTotal => _details.fold(0, (sum, item) => sum + item.qty);
  int get grandTotal => _details.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSupplier == null ||
        _selectedWarehouse == null ||
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

    final receipt = {
      'no_form': _formNumberController.text.trim(),
      'grandtotal': grandTotal,
      'item_total': itemTotal,
      'post_date': DateTime.now().toIso8601String(),
      'created_at': DateTime.now(),
      'store_ref': storeRef,
      'supplier_ref': _selectedSupplier,
      'warehouse_ref': _selectedWarehouse,
      'synced': true,
    };

    final receiptDoc = await FirebaseFirestore.instance
        .collection('purchaseGoodsReceipts')
        .add(receipt);

    for (final detail in _details) {
      await receiptDoc.collection('details').add(detail.toMap());
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
    appBar: AppBar(title: Text('Tambah Penerimaan')),
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
                        DropdownButtonFormField<DocumentReference>(
                          decoration: InputDecoration(labelText: 'Supplier'),
                          items: _suppliers.map((doc) {
                            return DropdownMenuItem(
                              value: doc.reference,
                              child: Text(doc['name']),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedSupplier = val),
                          validator: (val) => val == null ? 'Wajib dipilih' : null,
                        ),
                        DropdownButtonFormField<DocumentReference>(
                          decoration: InputDecoration(labelText: 'Warehouse'),
                          items: _warehouses.map((doc) {
                            return DropdownMenuItem(
                              value: doc.reference,
                              child: Text(doc['name']),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedWarehouse = val),
                          validator: (val) => val == null ? 'Wajib dipilih' : null,
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
                                      item.unitName = value!.id == '1' ? 'pcs' : 'dus';
                                    }),
                                    decoration: InputDecoration(labelText: "Produk"),
                                    validator: (value) => value == null ? 'Pilih produk' : null,
                                  ),
                                  TextFormField(
                                    initialValue: item.price.toString(),
                                    decoration: InputDecoration(labelText: "Harga"),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => setState(() => item.price = int.tryParse(val) ?? 0),
                                    validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
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
                                  Text("Subtotal: ${item.subtotal}"),
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
                        Text("Grand Total: $grandTotal"),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveReceipt,
                          child: Text("Simpan Receipt"),
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
      'price': price,
      'qty': qty,
      'unit_name': unitName,
      'subtotal': subtotal,
    };
  }
}
