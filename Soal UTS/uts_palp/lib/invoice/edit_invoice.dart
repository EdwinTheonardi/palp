// EditInvoicePage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/store_service.dart';
import 'package:dropdown_search/dropdown_search.dart';

class EditInvoicePage extends StatefulWidget {
  final DocumentReference invoiceRef;

  const EditInvoicePage({super.key, required this.invoiceRef});

  @override
  State<EditInvoicePage> createState() => _EditInvoicePageState();
}

class _EditInvoicePageState extends State<EditInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _formNumberController = TextEditingController();
  final _shippingCostController = TextEditingController();
  final _dueDateController = TextEditingController();

  DateTime? _postDate;
  DateTime? _dueDate;
  String? _selectedPaymentType;

  List<DocumentSnapshot> _products = [];
  final List<String> _paymentType = ['Cash', 'N/15', 'N/30', 'N/60', 'N/90'];
  final List<_DetailItem> _details = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final invoiceSnap = await widget.invoiceRef.get();
      if (!invoiceSnap.exists) return;
      final invoiceData = invoiceSnap.data() as Map<String, dynamic>;

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

      final detailsSnap = await widget.invoiceRef.collection('details').get();

      setState(() {
        _formNumberController.text = invoiceData['no_invoice'] ?? '';
        _shippingCostController.text = (invoiceData['shipping_cost'] ?? 0).toString();
        _selectedPaymentType = invoiceData['payment_type'];
        _postDate = (invoiceData['post_date'] as Timestamp).toDate();
        _dueDate = (invoiceData['due_date'] as Timestamp).toDate();
        _dueDateController.text = DateFormat('dd/MM/yyyy').format(_dueDate!);

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
      debugPrint('Error loading invoice: $e');
    }
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

  Future<void> _updateInvoice() async {
    if (!_formKey.currentState!.validate() || _details.isEmpty || _postDate == null) return;

    final detailCollection = widget.invoiceRef.collection('details');

    final oldDetails = await detailCollection.get();
    for (var doc in oldDetails.docs) {
      final data = doc.data();
      final productRef = data['product_ref'] as DocumentReference;
      final qty = data['qty'] as int;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final productSnap = await transaction.get(productRef);
        final currentStock = productSnap.get('stock') ?? 0;
        transaction.update(productRef, {'stock': currentStock - qty});
      });

      await doc.reference.delete();
    }

    final updatedData = {
      'no_invoice': _formNumberController.text.trim(),
      'grandtotal': grandTotal,
      'item_total': itemTotal,
      'payment_type': _selectedPaymentType,
      'post_date': Timestamp.fromDate(_postDate!),
      'due_date': _dueDate,
      'shipping_cost': int.tryParse(_shippingCostController.text) ?? 0,
      'updated_at': DateTime.now(),
    };

    await widget.invoiceRef.update(updatedData);

    for (final detail in _details) {
      await detailCollection.add(detail.toMap());

      if (detail.productRef != null) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final productSnap = await transaction.get(detail.productRef!);
          final currentStock = productSnap.get('stock') ?? 0;
          transaction.update(detail.productRef!, {'stock': currentStock + detail.qty});
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
      appBar: AppBar(title: Text('Edit Invoice')),
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
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          TextFormField(
                            controller: _formNumberController,
                            readOnly: true,
                            decoration: InputDecoration(labelText: 'No. Faktur'),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _postDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _postDate = picked;
                                  _updateDueDate();
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: _postDate == null
                                      ? ''
                                      : DateFormat('dd-MM-yyyy').format(_postDate!),
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Tanggal',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                validator: (_) => _postDate == null ? 'Wajib dipilih' : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(labelText: 'Tipe Pembayaran'),
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
                            validator: (val) => val == null ? 'Wajib dipilih' : null,
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
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Biaya Pengiriman'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 32),
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
                                      controller: item.priceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(labelText: 'Harga'),
                                      onChanged: (val) => setState(() => item.price = int.tryParse(val) ?? 0),
                                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                                    ),
                                    TextFormField(
                                      controller: item.qtyController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(labelText: 'Jumlah'),
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
                          Text("Grand Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(grandTotal)}"),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _updateInvoice,
                            child: Text("Update Invoice"),
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

  final TextEditingController priceController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();

  _DetailItem({
    required this.products,
    this.productRef,
    this.price = 0,
    this.qty = 1,
    this.unitName = 'unit',
    this.docId,
  }) {
    priceController.text = price.toString();
    qtyController.text = qty.toString();
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

  void updatePriceFromProduct() {
    if (productRef == null) return;
    final productDoc = products.firstWhere((doc) => doc.reference == productRef);
    final data = productDoc.data() as Map<String, dynamic>;
    price = data['price'] ?? 0;
    priceController.text = price.toString();
  }

  void dispose() {
    priceController.dispose();
    qtyController.dispose();
  }
}