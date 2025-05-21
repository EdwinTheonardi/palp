import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/store_service.dart';
import 'receipt/receipt.dart';
import 'supplier/supplier.dart';
import 'warehouse/warehouse.dart';
import 'product/product.dart';

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
      home: NavigationHomePage(),
    );
  }
}

class NavigationHomePage extends StatefulWidget {
  @override
  _NavigationHomePageState createState() => _NavigationHomePageState();
}

class _NavigationHomePageState extends State<NavigationHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ReceiptPage(),   // Halaman daftar penerimaan
    SupplierPage(),      // Halaman supplier
    WarehousePage(),     // Halaman warehouse
    ProductPage(),       // Halaman product
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Receipts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Suppliers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: 'Warehouses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
        ],
      ),
    );
  }
}
