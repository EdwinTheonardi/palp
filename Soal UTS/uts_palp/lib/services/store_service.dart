import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreService {
  // Ambil data store dari Firebase
  static Future<Map<String, dynamic>?> fetchStoreFromFirebase(String storeCode) async {
    print("🔍 Mencari store dengan code: $storeCode");

    final snapshot = await FirebaseFirestore.instance
        .collection('stores')
        .where('code', isEqualTo: storeCode)
        .limit(1)
        .get();

    print("🔍 Snapshot ditemukan: ${snapshot.docs.length} dokumen.");

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      print("🔥 Data ditemukan: ${doc.data()}");
      return doc.data();
    } else {
      print("❌ Store dengan code $storeCode tidak ditemukan.");
      return null;
    }
  }

  // Simpan store ke SharedPreferences
  static Future<void> saveStore(String storeCode, String storeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storeCode', storeCode);
    await prefs.setString('storeName', storeName);
    print("💾 Store berhasil disimpan ke local storage.");
  }

  // Inisialisasi store: ambil dari Firebase lalu simpan ke lokal
  static Future<void> initStore(String storeCode) async {
    final data = await fetchStoreFromFirebase(storeCode);
    if (data != null) {
      await saveStore(storeCode, data['name']); // Simpan nama store yang diambil dari Firebase
    } else {
      throw Exception('Store tidak ditemukan di Firebase');
    }
  }

  // Akses data store dari SharedPreferences
  static Future<String?> getStoreCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('storeCode'); // Ambil storeCode dari local storage
  }

  static Future<String?> getStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('storeName'); // Ambil storeName dari local storage
  }

  // Fungsi untuk memuat store dari local storage
  static Future<void> loadStoreFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? storeCode = prefs.getString('storeCode');
    String? storeName = prefs.getString('storeName');

    if (storeCode != null && storeName != null) {
      print("💾 Data dari local storage - Code: $storeCode, Name: $storeName");
    } else {
      print("❌ Tidak ada data store di local storage.");
    }
  }
}
