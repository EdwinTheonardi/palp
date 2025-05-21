import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/store_service.dart';

class EditProductPage extends StatefulWidget {
  final DocumentReference productRef;

  const EditProductPage({super.key, required this.productRef});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final productSnap = await widget.productRef.get();
      if (!productSnap.exists) return;

      final productData = productSnap.data() as Map<String, dynamic>;

      setState(() {
        _productNameController.text = productData['name'] ?? '';

        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading product data: $e');
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedData = {
      'name': _productNameController.text.trim(),
    };

    await widget.productRef.update(updatedData);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Product')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _productNameController,
                      decoration: InputDecoration(labelText: 'Nama Product'),
                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateProduct,
                      child: Text("Simpan Product"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}