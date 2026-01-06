// File: lib/providers/cart_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shoe_model.dart';

class CartItem {
  final Shoe shoe;
  final String selectedSize;
  int quantity;

  CartItem({
    required this.shoe,
    required this.selectedSize,
    this.quantity = 1,
  });

  double get totalPrice => shoe.price * quantity;

  Map<String, dynamic> toMap() => {
    "shoe": shoe.toMap(),
    "selectedSize": selectedSize,
    "quantity": quantity,
  };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    shoe: Shoe.fromMap(Map<String, dynamic>.from(map["shoe"])),
    selectedSize: map["selectedSize"] ?? "Unknown",
    quantity: map["quantity"] ?? 1,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CartItem &&
              runtimeType == other.runtimeType &&
              shoe.id == other.shoe.id &&
              selectedSize == other.selectedSize;

  @override
  int get hashCode => Object.hash(shoe.id, selectedSize);
}

class CartProvider extends ChangeNotifier {
  static const _storageKey = "cart_items_v2";

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get totalQty => _items.fold(0, (sum, e) => sum + e.quantity);

  double get subTotal => _items.fold(0, (sum, e) => sum + (e.shoe.price * e.quantity));

  double get shipping => _items.isEmpty ? 0 : 8.0;
  double get total => subTotal + shipping;

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      await _migrateFromV1(prefs);
      return;
    }

    final List decoded = jsonDecode(raw);
    _items
      ..clear()
      ..addAll(decoded.map((e) => CartItem.fromMap(Map<String, dynamic>.from(e))).toList());

    notifyListeners();
  }

  Future<void> _migrateFromV1(SharedPreferences prefs) async {
    final oldRaw = prefs.getString("cart_items_v1");
    if (oldRaw == null || oldRaw.isEmpty) return;

    final List oldDecoded = jsonDecode(oldRaw);
    final oldItems = oldDecoded.map((e) {
      final map = Map<String, dynamic>.from(e);
      return CartItem(
        shoe: Shoe.fromMap(Map<String, dynamic>.from(map["shoe"])),
        selectedSize: "One Size",
        quantity: map["quantity"] ?? 1,
      );
    }).toList();

    _items.addAll(oldItems);
    notifyListeners();
    await _saveCart();
    await prefs.remove("cart_items_v1");
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_items.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, raw);
  }

  // === THÊM 1 ĐÔI (giữ nguyên để tương thích cũ) ===
  Future<void> addToCart({
    required Shoe shoe,
    required String selectedSize,
  }) async {
    await addMultipleToCart(shoe: shoe, selectedSize: selectedSize, quantity: 1);
  }

  // === THÊM NHIỀU ĐÔI CÙNG LÚC (MỚI) ===
  Future<void> addMultipleToCart({
    required Shoe shoe,
    required String selectedSize,
    required int quantity,
  }) async {
    if (quantity <= 0) return;

    final existingIndex = _items.indexWhere(
          (item) => item.shoe.id == shoe.id && item.selectedSize == selectedSize,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        shoe: shoe,
        selectedSize: selectedSize,
        quantity: quantity,
      ));
    }

    notifyListeners();
    await _saveCart();
  }

  // Tăng số lượng
  Future<void> increaseQty(String shoeId, String size) async {
    final index = _items.indexWhere(
          (e) => e.shoe.id == shoeId && e.selectedSize == size,
    );
    if (index < 0) return;

    _items[index].quantity++;
    notifyListeners();
    await _saveCart();
  }

  // Giảm số lượng
  Future<void> decreaseQty(String shoeId, String size) async {
    final index = _items.indexWhere(
          (e) => e.shoe.id == shoeId && e.selectedSize == size,
    );
    if (index < 0) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }

    notifyListeners();
    await _saveCart();
  }

  // Xóa item
  Future<void> removeItem(String shoeId, String size) async {
    _items.removeWhere((e) => e.shoe.id == shoeId && e.selectedSize == size);
    notifyListeners();
    await _saveCart();
  }

  // Xóa toàn bộ
  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _saveCart();
  }
}