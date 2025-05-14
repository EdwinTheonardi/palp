import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditReceiptPage extends StatefulWidget {
  final DocumentReference receiptRef;

  const EditReceiptPage({super.key, required this.receiptRef});

  @override
  State<EditReceiptPage> createState() => _EditReceiptPageState();
}

class _EditReceiptPageState extends State<EditReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final _formNumberController = TextEditingController();

  DocumentReference? _selectedSupplier;
  DocumentReference? _selectedWarehouse;
  List<DocumentSnapshot> _suppliers = [];
  List<DocumentSnapshot> _warehouses = [];
  List<DocumentSnapshot> _products = [];

  final List<_DetailItem> _details = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final receiptSnap = await widget.receiptRef.get();
    if (!receiptSnap.exists) return;

    final receiptData = receiptSnap.data() as Map<String, dynamic>;

    final supplierSnap = await FirebaseFirestore.instance.collection('suppliers').get();
    final warehouseSnap = await FirebaseFirestore.instance.collection('warehouses').get();
    final productSnap = await FirebaseFirestore.instance.collection('products').get();

    final detailsSnap = await widget.receiptRef.collection('details').get();

    setState(() {
      _formNumberController.text = receiptData['no_form'] ?? '';
      _selectedSupplier = receiptData['supplier_ref'];
      _selectedWarehouse = receiptData['warehouse_ref'];
      _suppliers = supplierSnap.docs;
      _warehouses = warehouseSnap.docs;
      _products = productSnap.docs;

      _details.clear();
      for (var doc in detailsSnap.docs) {
        final data = doc.data();
        _details.add(_DetailItem(
          products: _products,
          productRef: data['product_ref'],
          price: data['price'],
          qty: data['qty'],
          unitName: data['unit_name'],
          docId: doc.id,
        ));
      }

      _loading = false;
    });
  }

  int get itemTotal => _details.fold(0, (sum, item) => sum + item.qty);
  int get grandTotal => _details.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _updateReceipt() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSupplier == null ||
        _selectedWarehouse == null ||
        _details.isEmpty) {
      return;
    }

    final updatedData = {
      'no_form': _formNumberController.text.trim(),
      'grandtotal': grandTotal,
      'item_total': itemTotal,
      'supplier_ref': _selectedSupplier,
      'warehouse_ref': _selectedWarehouse,
      'updated_at': DateTime.now(),
    };

    await widget.receiptRef.update(updatedData);

    final detailCollection = widget.receiptRef.collection('details');

    // Hapus semua detail lama
    final oldDetails = await detailCollection.get();
    for (var doc in oldDetails.docs) {
      await doc.reference.delete();
    }

    // Tambahkan detail baru
    for (final detail in _details) {
      await detailCollection.add(detail.toMap());
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
      appBar: AppBar(title: Text('Edit Penerimaan')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KIRI
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _formNumberController,
                            decoration: InputDecoration(labelText: 'No. Form'),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Wajib diisi' : null,
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<DocumentReference>(
                            decoration: InputDecoration(labelText: 'Supplier'),
                            value: _selectedSupplier,
                            items: _suppliers.map((doc) {
                              return DropdownMenuItem(
                                value: doc.reference,
                                child: Text(doc['name']),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedSupplier = val),
                            validator: (val) =>
                                val == null ? 'Wajib dipilih' : null,
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<DocumentReference>(
                            decoration: InputDecoration(labelText: 'Warehouse'),
                            value: _selectedWarehouse,
                            items: _warehouses.map((doc) {
                              return DropdownMenuItem(
                                value: doc.reference,
                                child: Text(doc['name']),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedWarehouse = val),
                            validator: (val) =>
                                val == null ? 'Wajib dipilih' : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 24),
                    // KANAN
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Produk',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
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
                                        item.unitName = value!.id == '1'
                                            ? 'pcs'
                                            : 'dus';
                                      }),
                                      decoration:
                                          InputDecoration(labelText: "Produk"),
                                      validator: (value) =>
                                          value == null ? 'Pilih produk' : null,
                                    ),
                                    TextFormField(
                                      initialValue: item.price.toString(),
                                      decoration:
                                          InputDecoration(labelText: "Harga"),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) => setState(() =>
                                          item.price = int.tryParse(val) ?? 0),
                                      validator: (val) => val == null ||
                                              val.isEmpty
                                          ? 'Wajib diisi'
                                          : null,
                                    ),
                                    TextFormField(
                                      initialValue: item.qty.toString(),
                                      decoration:
                                          InputDecoration(labelText: "Jumlah"),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) => setState(() =>
                                          item.qty = int.tryParse(val) ?? 1),
                                      validator: (val) => val == null ||
                                              val.isEmpty
                                          ? 'Wajib diisi'
                                          : null,
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
                            onPressed: _updateReceipt,
                            child: Text("Update Receipt"),
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
  int price;
  int qty;
  String unitName;
  String? docId;
  final List<DocumentSnapshot> products;

  _DetailItem({
    required this.products,
    this.productRef,
    this.price = 0,
    this.qty = 1,
    this.unitName = 'unit',
    this.docId,
  });

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
