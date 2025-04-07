<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/products', function () {
    return response()->json([
        ['id' => 1, 'name' => 'Mango Sago', 'price' => 25000],
        ['id' => 2, 'name' => 'Nasi Kuning', 'price' => 15000]
    ]);
});

Route::get('/test', function() {
    return response()->json('test');
});

