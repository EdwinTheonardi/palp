import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/store_service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';

class EditReceiptPage extends StatefulWidget {
  final DocumentReference receiptRef;

  const EditReceiptPage({super.key, required this.receiptRef});

  @override
  State<EditReceiptPage> createState() => _EditReceiptPageState();
}

class _EditReceiptPageState extends State<EditReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final _formNumberController = TextEditingController();
  final _postDateController = TextEditingController();

  DocumentReference? _selectedSupplier;
  DocumentReference? _selectedWarehouse;
  List<DocumentSnapshot> _suppliers = [];
  List<DocumentSnapshot> _warehouses = [];
  List<DocumentSnapshot> _products = [];

  final List<_DetailItem> _details = [];

  bool _loading = true;
  DateTime? _postDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final receiptSnap = await widget.receiptRef.get();
      if (!receiptSnap.exists) return;

      final receiptData = receiptSnap.data() as Map<String, dynamic>;

      final storeCode = await StoreService.getStoreCode();
      if (storeCode == null) return;

      final storeQuery = await FirebaseFirestore.instance
          .collection('stores')
          .where('code', isEqualTo: storeCode)
          .limit(1)
          .get();

      if (storeQuery.docs.isEmpty) return;
      final storeRef = storeQuery.docs.first.reference;

      final supplierSnap = await FirebaseFirestore.instance
          .collection('suppliers')
          .where('store_ref', isEqualTo: storeRef)
          .get();

      final warehouseSnap = await FirebaseFirestore.instance
          .collection('warehouses')
          .where('store_ref', isEqualTo: storeRef)
          .get();

      final productSnap = await FirebaseFirestore.instance
          .collection('products')
          .where('store_ref', isEqualTo: storeRef)
          .get();

      final detailsSnap = await widget.receiptRef.collection('details').get();

      setState(() {
        _formNumberController.text = receiptData['no_form'] ?? '';
        _selectedSupplier = receiptData['supplier_ref'];
        _selectedWarehouse = receiptData['warehouse_ref'];
        _postDate = (receiptData['post_date'] as Timestamp).toDate();
        _postDateController.text = DateFormat('dd-MM-yyyy').format(_postDate!);
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
    } catch (e) {
      debugPrint('Error loading receipt data: $e');
    }
  }

  int get itemTotal => _details.fold(0, (sum, item) => sum + item.qty);
  int get grandTotal => _details.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _selectPostDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _postDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _postDate = picked;
        _postDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _updateReceipt() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSupplier == null ||
        _selectedWarehouse == null ||
        _details.isEmpty ||
        _postDate == null) {
      return;
    }

    final detailCollection = widget.receiptRef.collection('details');

    final oldDetails = await detailCollection.get();
    for (var doc in oldDetails.docs) {
      final data = doc.data();
      final productRef = data['product_ref'] as DocumentReference;
      final qty = data['qty'] as int;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final productSnap = await transaction.get(productRef);
        if (!productSnap.exists) return;

        final currentStock = productSnap.get('stock') ?? 0;
        transaction.update(productRef, {
          'stock': currentStock - qty,
        });
      });

      await doc.reference.delete();
    }

    final updatedData = {
      'no_form': _formNumberController.text.trim(),
      'grandtotal': grandTotal,
      'item_total': itemTotal,
      'supplier_ref': _selectedSupplier,
      'warehouse_ref': _selectedWarehouse,
      'post_date': Timestamp.fromDate(_postDate!),
      'updated_at': DateTime.now(),
    };

    await widget.receiptRef.update(updatedData);

    for (final detail in _details) {
      await detailCollection.add(detail.toMap());

      if (detail.productRef != null) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final productSnap = await transaction.get(detail.productRef!);
          if (!productSnap.exists) return;

          final currentStock = productSnap.get('stock') ?? 0;
          transaction.update(detail.productRef!, {
            'stock': currentStock + detail.qty,
          });
        });
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
                          GestureDetector(
                            onTap: _selectPostDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _postDateController,
                                decoration: InputDecoration(
                                  labelText: 'Tanggal Penerimaan',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Wajib dipilih' : null,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          DropdownSearch<DocumentSnapshot>(
                            items: _suppliers,
                            itemAsString: (doc) => doc['name'],
                            selectedItem: _suppliers.any((doc) => doc.reference == _selectedSupplier)
                                ? _suppliers.firstWhere((doc) => doc.reference == _selectedSupplier)
                                : null,
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(labelText: 'Supplier'),
                            ),
                            onChanged: (doc) => setState(() => _selectedSupplier = doc?.reference),
                            validator: (val) => val == null ? 'Wajib dipilih' : null,
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(hintText: 'Cari supplier...'),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          DropdownSearch<DocumentSnapshot>(
                            items: _warehouses,
                            itemAsString: (doc) => doc['name'],
                            selectedItem: _warehouses.any((doc) => doc.reference == _selectedWarehouse)
                                ? _warehouses.firstWhere((doc) => doc.reference == _selectedWarehouse)
                                : null,
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(labelText: 'Warehouse'),
                            ),
                            onChanged: (doc) => setState(() => _selectedWarehouse = doc?.reference),
                            validator: (val) => val == null ? 'Wajib dipilih' : null,
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(hintText: 'Cari warehouse...'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Produk', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    DropdownSearch<DocumentReference>(
                                      items: _products.map((doc) => doc.reference).toList(),
                                      selectedItem: item.productRef,
                                      itemAsString: (ref) {
                                        final product = _products.where((doc) => doc.reference == ref);
                                        return product.isNotEmpty ? product.first['name'] : '';
                                      },
                                      dropdownDecoratorProps: DropDownDecoratorProps(
                                        dropdownSearchDecoration: InputDecoration(labelText: 'Produk'),
                                      ),
                                      onChanged: (ref) {
                                        setState(() {
                                          item.productRef = ref;
                                          item.unitName = 'pcs';
                                        });
                                      },
                                      validator: (val) => val == null ? 'Pilih produk' : null,
                                      popupProps: PopupProps.menu(
                                        showSearchBox: true,
                                        searchFieldProps: TextFieldProps(
                                          decoration: InputDecoration(hintText: 'Cari produk...'),
                                        ),
                                      ),
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
                          Text("Grand Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0).format(grandTotal)}"),
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
