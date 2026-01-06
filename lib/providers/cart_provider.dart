// File: cart_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shoe_model.dart';

class CartItem {
  final Shoe shoe;
  int quantity;

  CartItem({required this.shoe, this.quantity = 1});

  Map<String, dynamic> toMap() => {
    "shoe": shoe.toMap(),
    "quantity": quantity,
  };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    shoe: Shoe.fromMap(Map<String, dynamic>.from(map["shoe"])),
    quantity: map["quantity"] ?? 1,
  );
}

class CartProvider extends ChangeNotifier {
  static const _storageKey = "cart_items_v1";

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get totalQty => _items.fold(0, (sum, e) => sum + e.quantity);

  double get subTotal =>
      _items.fold(0, (sum, e) => sum + (e.shoe.price * e.quantity));

  double get shipping => _items.isEmpty ? 0 : 8.0; // tuỳ bạn
  double get total => subTotal + shipping;

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    final List decoded = jsonDecode(raw);
    _items
      ..clear()
      ..addAll(decoded.map((e) => CartItem.fromMap(Map<String, dynamic>.from(e))).toList());

    notifyListeners();
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_items.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<void> addToCart(Shoe shoe) async {
    final index = _items.indexWhere((e) => e.shoe.id == shoe.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(shoe: shoe, quantity: 1));
    }
    notifyListeners();
    await _saveCart();
  }

  Future<void> increaseQty(String shoeId) async {
    final index = _items.indexWhere((e) => e.shoe.id == shoeId);
    if (index < 0) return;
    _items[index].quantity++;
    notifyListeners();
    await _saveCart();
  }

  Future<void> decreaseQty(String shoeId) async {
    final index = _items.indexWhere((e) => e.shoe.id == shoeId);
    if (index < 0) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }

    notifyListeners();
    await _saveCart();
  }

  Future<void> removeItem(String shoeId) async {
    _items.removeWhere((e) => e.shoe.id == shoeId);
    notifyListeners();
    await _saveCart();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _saveCart();
  }
}
