import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/store_service.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AddInvoicePage extends StatefulWidget {
  const AddInvoicePage({super.key});

  @override
  State<AddInvoicePage> createState() => _AddInvoicePageState();
}

class _AddInvoicePageState extends State<AddInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _formNumberController = TextEditingController();
  final _shippingCostController = TextEditingController();
  final _postDateController = TextEditingController();
  final _dueDateController = TextEditingController();

  DateTime? _postDate;
  DateTime? _dueDate;
  String? _selectedPaymentType;

  List<DocumentSnapshot> _products = [];

  final List<String> _paymentType = ['Cash', 'N/15', 'N/30', 'N/60', 'N/90'];
  final List<_DetailItem> _details = [];

  @override
  void initState() {
    super.initState();
    _setInitialNoForm();
    _fetchProducts();
    _postDate = DateTime.now();
    _updatePostDateController(); 
  }

  Future<void> _fetchProducts() async {
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

  void _updatePostDateController() {
    _postDateController.text = _postDate == null
        ? ''
        : DateFormat('dd-MM-yyyy').format(_postDate!);
  }

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
        _updatePostDateController();
      });
    }
  }

  Future<String> generateNoForm() async {
    final now = DateTime.now();
    final startOfDayLocal = DateTime(now.year, now.month, now.day);
    final endOfDayLocal = startOfDayLocal.add(Duration(days: 1));
    final startOfDayUtc = startOfDayLocal.toUtc();
    final endOfDayUtc = endOfDayLocal.toUtc();

    final snapshot = await FirebaseFirestore.instance
        .collection('purchaseInvoices')
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
        .where('created_at', isLessThan: Timestamp.fromDate(endOfDayUtc))
        .get();

    final count = snapshot.docs.length + 1;
    final code = 'FB${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${count.toString().padLeft(4, '0')}';
    return code;
  }

  Future<void> _setInitialNoForm() async {
    final generatedCode = await generateNoForm();
    setState(() {
      _formNumberController.text = generatedCode;
    });
  }

  void _updateDueDate() {
    if (_postDate == null || _selectedPaymentType == null) return;
    int days = 0;
    switch (_selectedPaymentType) {
      case 'N/15': days = 15; break;
      case 'N/30': days = 30; break;
      case 'N/60': days = 60; break;
      case 'N/90': days = 90; break;
    }
    _dueDate = _postDate!.add(Duration(days: days));
    _dueDateController.text = DateFormat('dd/MM/yyyy').format(_dueDate!);
  }

  int get itemTotal => _details.fold(0, (sum, item) => sum + item.qty);
  int get grandTotal => _details.fold(0, (sum, item) => sum + item.subtotal) + (int.tryParse(_shippingCostController.text) ?? 0);

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate() || _details.isEmpty || _postDate == null) return;

    final storeCode = await StoreService.getStoreCode();
    if (storeCode == null) return;

    final storeQuery = await FirebaseFirestore.instance
        .collection('stores')
        .where('code', isEqualTo: storeCode)
        .limit(1)
        .get();

    if (storeQuery.docs.isEmpty) return;
    final storeRef = storeQuery.docs.first.reference;

    final invoice = {
      'created_at': Timestamp.now(),
      'due_date': _dueDate,
      'grandtotal': grandTotal,
      'no_invoice': _formNumberController.text.trim(),
      'payment_type': _selectedPaymentType,
      'post_date': Timestamp.fromDate(_postDate!),
      'shipping_cost': int.tryParse(_shippingCostController.text) ?? 0,
      'store_ref': storeRef
    };

    final invoiceDoc = await FirebaseFirestore.instance
        .collection('purchaseInvoices')
        .add(invoice);

    for (final detail in _details) {
      await invoiceDoc.collection('details').add(detail.toMap());

      if (detail.productRef != null) {
        final productSnapshot = await detail.productRef!.get();
        final productData = productSnapshot.data() as Map<String, dynamic>?;
        if (productData != null) {
          final updatedStock = (productData['stock'] ?? 0) + detail.qty;
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
      _details[index].dispose();
      _details.removeAt(index);
    });
  }

  @override
  void dispose() {
    _formNumberController.dispose();
    _shippingCostController.dispose();
    _dueDateController.dispose();
    for (var detail in _details) {
      detail.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Invoice')),
      body: _products.isEmpty
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
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          TextFormField(
                            controller: _formNumberController,
                            readOnly: true,
                            decoration: InputDecoration(labelText: 'No. Faktur'),
                          ),
                          GestureDetector(
                            onTap: _selectPostDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Tanggal',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                controller: TextEditingController(
                                  text: _postDate == null
                                      ? ''
                                      : DateFormat('dd-MM-yyyy').format(_postDate!),
                                ),
                                validator: (_) => _postDate == null ? 'Wajib dipilih' : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Tipe Pembayaran'),
                            value: _selectedPaymentType,
                            items: _paymentType.map((type) {
                              return DropdownMenuItem(value: type, child: Text(type));
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPaymentType = val;
                                _updateDueDate();
                              });
                            },
                            validator: (val) => val == null ? 'Pilih salah satu' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dueDateController,
                            readOnly: true,
                            decoration: InputDecoration(labelText: 'Jatuh Tempo'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _shippingCostController,
                            decoration: InputDecoration(labelText: 'Biaya Pengiriman'),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 32),

                    // KANAN
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
                                    DropdownSearch<DocumentReference>(
                                      items: _products.map((doc) => doc.reference).toList(),
                                      selectedItem: item.productRef,
                                      itemAsString: (ref) {
                                        final found = _products.where((doc) => doc.reference == ref);
                                        return found.isNotEmpty ? found.first['name'] : '';
                                      },
                                      dropdownDecoratorProps: DropDownDecoratorProps(
                                        dropdownSearchDecoration: InputDecoration(labelText: "Produk"),
                                      ),
                                      onChanged: (ref) {
                                        setState(() {
                                          item.productRef = ref;
                                          item.updatePriceFromProduct();
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
                                      controller: item.priceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(labelText: 'Harga'),
                                      onChanged: (val) =>
                                          setState(() => item.price = int.tryParse(val) ?? 0),
                                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                                    ),
                                    TextFormField(
                                      controller: item.qtyController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(labelText: 'Jumlah'),
                                      onChanged: (val) =>
                                          setState(() => item.qty = int.tryParse(val) ?? 1),
                                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                                    ),
                                    const SizedBox(height: 8),
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
                            label: Text("Tambah Produk"),
                          ),
                          const SizedBox(height: 16),
                          Text("Item Total: $itemTotal"),
                          Text("Grand Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(grandTotal)}"),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _saveInvoice,
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

  final TextEditingController priceController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(text: '1');

  _DetailItem({required this.products});

  void updatePriceFromProduct() {
    if (productRef == null) return;
    final productDoc = products.firstWhere((doc) => doc.reference == productRef);
    final data = productDoc.data() as Map<String, dynamic>;
    price = data['price'] ?? 0;
    priceController.text = price.toString();
  }

  int get subtotal => price * qty;

  Map<String, dynamic> toMap() {
    final productDoc = products.firstWhere((doc) => doc.reference == productRef);
    return {
      'product_ref': productRef,
      'product_name': productDoc['name'],
      'price': price,
      'qty': qty,
      'unit_name': unitName,
      'subtotal': subtotal,
    };
  }

  void dispose() {
    priceController.dispose();
    qtyController.dispose();
  }
}
