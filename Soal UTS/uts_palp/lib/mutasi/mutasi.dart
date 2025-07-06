import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/store_service.dart';

class MutationPage extends StatefulWidget {
  const MutationPage({super.key});

  @override
  _MutationPageState createState() => _MutationPageState();
}

class _MutationPageState extends State<MutationPage> {
  DocumentReference? productRef;
  DocumentReference? fromWarehouseRef;
  DocumentReference? toWarehouseRef;
  List<DocumentSnapshot> _products = [];
  List<DocumentSnapshot> _warehouses = [];

  String? selectedItem;
  String? fromWarehouse;
  String? toWarehouse;
  final TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final storeCode = await StoreService.getStoreCode();
      if (storeCode == null) return;

      final storeQuery =
          await FirebaseFirestore.instance
              .collection('stores')
              .where('code', isEqualTo: storeCode)
              .limit(1)
              .get();

      if (storeQuery.docs.isEmpty) return;
      final storeRef = storeQuery.docs.first.reference;

      final productSnap =
          await FirebaseFirestore.instance
              .collection('products')
              .where('store_ref', isEqualTo: storeRef)
              .get();

      final warehouseSnap =
          await FirebaseFirestore.instance
              .collection('warehouses')
              .where('store_ref', isEqualTo: storeRef)
              .get();

      setState(() {
        _products = productSnap.docs;
        _warehouses = warehouseSnap.docs;
      });
    } catch (e) {
      debugPrint('Error fetching dropdown data: $e');
    }
  }

  void submitMutation() async {
    if (productRef == null ||
        fromWarehouseRef == null ||
        toWarehouseRef == null ||
        quantityController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mohon lengkapi semua data')));
      return;
    }

    if (fromWarehouseRef == toWarehouseRef) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gudang asal dan tujuan tidak boleh sama')),
      );
      return;
    }

    final int? qty = int.tryParse(quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Jumlah harus angka yang valid')));
      return;
    }

    // Kurangin barang
    final fromWarehouseSnapshot = await FirebaseFirestore.instance
        .collection('warehouseStocks')
        .where('product_ref', isEqualTo: productRef)
        .where('warehouse_ref', isEqualTo: fromWarehouseRef)
        .limit(1)
        .get();
    
    if (fromWarehouseSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok di gudang asal tidak ditemukan')),
      );
      return;
    }

    final fromWarehouseDoc = fromWarehouseSnapshot.docs.first;
    final fromWarehouseQty = fromWarehouseDoc['qty'] ?? 0;

    if (fromWarehouseQty < qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok gudang asal tidak mencukupi')),
      );
      return;
    }

    await fromWarehouseDoc.reference.update({'qty': fromWarehouseQty - qty});

    // Tambahin Barang
    final toWarehouseSnapshot = await FirebaseFirestore.instance
        .collection('warehouseStocks')
        .where('product_ref', isEqualTo: productRef)
        .where('warehouse_ref', isEqualTo: toWarehouseRef)
        .limit(1)
        .get();

    if (toWarehouseSnapshot.docs.isNotEmpty) {
      final toWarehouseDoc = toWarehouseSnapshot.docs.first;
      final toWarehouseQty = toWarehouseDoc['qty'] ?? 0;
      await toWarehouseDoc.reference.update({'qty': toWarehouseQty + qty});
    }

    // Simulasi mutasi berhasil
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mutasi $productRef sebanyak $qty dari $fromWarehouseRef ke $toWarehouseRef berhasil',
        ),
      ),
    );

    // Reset form
    setState(() {
      productRef = null;
      fromWarehouseRef = null;
      toWarehouseRef = null;
      quantityController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mutasi Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<DocumentReference>(
              decoration: InputDecoration(labelText: 'Pilih Produk'),
              value: productRef,
              items: _products.map((doc) {
                return DropdownMenuItem<DocumentReference>(
                  value: doc.reference,
                  child: Text(doc['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  productRef = value;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<DocumentReference>(
              decoration: InputDecoration(labelText: 'Gudang Asal'),
              value: fromWarehouseRef,
              items: _warehouses.map((doc) {
                return DropdownMenuItem<DocumentReference>(
                  value: doc.reference,
                  child: Text(doc['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => fromWarehouseRef = value),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<DocumentReference>(
              decoration: InputDecoration(labelText: 'Gudang Tujuan'),
              value: toWarehouseRef,
              items: _warehouses.map((doc) {
                return DropdownMenuItem<DocumentReference>(
                  value: doc.reference,
                  child: Text(doc['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => toWarehouseRef = value),
            ),
            SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Jumlah'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: submitMutation,
              child: Text('Kirim Mutasi'),
            ),
          ],
        ),
      ),
    );
  }
}
