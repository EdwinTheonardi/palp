<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Product;

class ProductController extends Controller
{
  public function index() {
    return response()->json(Product::all());
  }

  public function show($id) {
    $product = Product::find($id);

    return response()->json($product);
  }

  public function store(Request $request) {
    $validated = $request->validate([
      'name' => 'required|string|max:255',
      'price' => 'required|numeric|min:0',
      'photo' => 'nullable|string',
      'is_promo' => 'required|boolean',
    ]);

    $product = Product::create($validated);

    return response()->json([
      'message' => $product ? 'Produk berhasil ditambahkan' : 'Produk gagal ditambahkan'
    ]);
  }

  public function update(Request $request, $id) {
    $product = Product::find($id);

    if (!$product) {
      return response()->json(['message' => 'Produk tidak ditemukan'], 404);
    }

    $validated = $request->validate([
      'name' => 'sometimes|string|max:255',
      'price' => 'sometimes|numeric|min:0',
      'photo' => 'sometimes|string',
      'is_promo' => 'sometimes|boolean',
    ]);

    $product->update($validated);

    return response()->json(['message' => 'Produk berhasil diupdate']);
  }

  public function destroy($id) {
    $product = Product::find($id);

    if (!$product) {
      return response()->json(['message' => 'Produk tidak ditemukan'], 404);
    }

    $product->delete();

    return response()->json(['message' => 'Produk berhasil dihapus']);
  }
}
