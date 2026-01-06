// File: lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';
import '../models/shoe_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required String appliedVoucher});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _voucherController = TextEditingController();

  String _selectedPayment = 'cod';
  String _selectedBank = 'vietcombank';
  double _discount = 0.0;
  bool _isPlacingOrder = false;

  final Map<String, Map<String, String>> _banks = {
    'vietcombank': {'name': 'Vietcombank', 'bin': '970436'},
    'bidv': {'name': 'BIDV', 'bin': '970418'},
    'vietinbank': {'name': 'VietinBank', 'bin': '970415'},
    'techcombank': {'name': 'Techcombank', 'bin': '970407'},
    'mbBank': {'name': 'MB Bank', 'bin': '970422'},
    'acb': {'name': 'ACB', 'bin': '970416'},
    'vpBank': {'name': 'VPBank', 'bin': '970432'},
  };

  final String shopAccountNo = '1234567890';
  final String shopAccountName = 'SHOP SNEAKER';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  void _applyVoucher() {
    final code = _voucherController.text.trim().toUpperCase();
    setState(() {
      if (code == 'SHOPEE10') {
        _discount = 100000;
      } else if (code == 'FREESHIP') {
        _discount = 30000;
      } else {
        _discount = 0;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_discount > 0 ? 'Áp dụng mã thành công!' : 'Mã không hợp lệ')),
      );
    });
  }

  String _getBankQRUrl(double amountVND) {
    final bank = _banks[_selectedBank]!;
    final name = bank['name']!.toLowerCase().replaceAll(' ', '');
    return 'https://img.vietqr.io/image/$name-$shopAccountNo-compact2.png?'
        'amount=${amountVND.round()}&'
        'addInfo=Thanh%20toan%20don%20hang%20Sneaker&'
        'accountName=${Uri.encodeComponent(shopAccountName)}';
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPlacingOrder = true);

    final cart = context.read<CartProvider>();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập")));
      setState(() => _isPlacingOrder = false);
      return;
    }

    final List<CartItem> orderItems = List.from(cart.items);

    try {
      // GIẢM STOCK REALTIME (1 transaction)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        Map<String, Map<String, int>> stockUpdates = {};

        for (var item in orderItems) {
          if (item.shoe.id.isEmpty) continue;

          final shoeId = item.shoe.id;
          final size = item.selectedSize;
          final qty = item.quantity;

          stockUpdates.putIfAbsent(shoeId, () => {});
          stockUpdates[shoeId]![size] = (stockUpdates[shoeId]![size] ?? 0) + qty;
        }

        for (var entry in stockUpdates.entries) {
          final shoeId = entry.key;
          final sizeQtyMap = entry.value;

          final docRef = FirebaseFirestore.instance.collection('products').doc(shoeId);
          final snapshot = await transaction.get(docRef);

          if (!snapshot.exists) throw Exception("Sản phẩm không tồn tại!");

          final data = snapshot.data() as Map<String, dynamic>;
          final currentStockMap = Map<String, dynamic>.from(data['stock'] ?? {});

          for (var sizeEntry in sizeQtyMap.entries) {
            final size = sizeEntry.key;
            final qtyToSubtract = sizeEntry.value;

            final currentQty = (currentStockMap[size] as num?)?.toInt() ?? 0;
            if (currentQty < qtyToSubtract) throw Exception("Không đủ hàng size $size!");

            currentStockMap[size] = currentQty - qtyToSubtract;
            if (currentStockMap[size] == 0) currentStockMap.remove(size);
          }

          transaction.update(docRef, {'stock': currentStockMap});
        }
      });

      // TÍNH TIỀN
      const double shippingFee = 30000;
      final double subtotalVND = cart.subTotal * Shoe.usdToVndRate;
      final double finalTotalVND = subtotalVND + shippingFee - _discount;

      // TẠO MÃ ĐƠN HÀNG
      final orderId = "SNK${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";

      // LƯU ĐƠN HÀNG VÀO COLLECTION 'orders'
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': currentUser.uid,
        'orderId': orderId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'items': orderItems.map((item) => {
          'shoeId': item.shoe.id,
          'shoeName': item.shoe.name,
          'shoeImage': item.shoe.image,
          'priceUSD': item.shoe.price,
          'selectedSize': item.selectedSize,
          'quantity': item.quantity,
          'totalPriceUSD': item.totalPrice,
        }).toList(),
        'subtotalVND': subtotalVND,
        'shippingFee': shippingFee,
        'discount': _discount,
        'totalVND': finalTotalVND,
        'paymentMethod': _selectedPayment,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // CLEAR GIỎ
      cart.clear();

      // CHUYỂN SANG BILL
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderBillScreen(
              orderId: orderId,
              name: _nameController.text,
              phone: _phoneController.text,
              address: _addressController.text,
              items: orderItems,
              subtotalVND: subtotalVND,
              shippingFee: shippingFee,
              discount: _discount,
              totalVND: finalTotalVND,
              paymentMethod: _selectedPayment,
              selectedBank: _selectedPayment == 'bank' ? _banks[_selectedBank]!['name']! : null,
              orderDate: DateTime.now(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đặt hàng thất bại: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    const double shippingFee = 30000;
    final double subtotalVND = cart.subTotal * Shoe.usdToVndRate;
    final double finalTotalVND = subtotalVND + shippingFee - _discount;

    Widget? qrSection;
    if (_selectedPayment == 'bank') {
      qrSection = Column(
        children: [
          const Text("Chọn ngân hàng", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedBank,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: _banks.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['name']!))).toList(),
            onChanged: (val) => setState(() => _selectedBank = val!),
          ),
          const SizedBox(height: 20),
          const Text("Quét QR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          CachedNetworkImage(
            imageUrl: _getBankQRUrl(finalTotalVND),
            width: 260,
            height: 260,
            placeholder: (_, __) => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 12),
          Text("Số tiền: ${Shoe.vndFormat.format(finalTotalVND)}", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
    } else if (_selectedPayment == 'momo') {
      qrSection = Column(
        children: [
          const Text("Quét QR MoMo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          QrImageView(data: '2|99|$shopAccountNo||0|0|${finalTotalVND.round()}|Thanh toan Sneaker', version: QrVersions.auto, size: 260),
          const SizedBox(height: 12),
          Text("Số tiền: ${Shoe.vndFormat.format(finalTotalVND)}", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text("Thanh toán", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Thông tin nhận hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextField(_nameController, "Họ và tên *"),
                  const SizedBox(height: 12),
                  _buildTextField(_phoneController, "Số điện thoại *", keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _buildTextField(_addressController, "Địa chỉ giao hàng *", maxLines: 3),

                  const SizedBox(height: 30),
                  const Text("Mã giảm giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _voucherController, decoration: InputDecoration(hintText: "Nhập mã", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      const SizedBox(width: 12),
                      ElevatedButton(onPressed: _applyVoucher, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text("Áp dụng", style: TextStyle(color: Colors.white))),
                    ],
                  ),
                  if (_discount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("Đã giảm: -${Shoe.vndFormat.format(_discount)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),

                  const SizedBox(height: 30),
                  const Text("Phương thức thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  RadioListTile<String>(title: const Text('Thanh toán khi nhận hàng (COD)'), value: 'cod', groupValue: _selectedPayment, onChanged: (v) => setState(() => _selectedPayment = v!)),
                  RadioListTile<String>(title: const Text('Chuyển khoản ngân hàng'), value: 'bank', groupValue: _selectedPayment, onChanged: (v) => setState(() => _selectedPayment = v!)),
                  RadioListTile<String>(title: const Text('Ví MoMo'), value: 'momo', groupValue: _selectedPayment, onChanged: (v) => setState(() => _selectedPayment = v!)),

                  if (qrSection != null) ...[const SizedBox(height: 30), qrSection],

                  const SizedBox(height: 30),
                  const Text("Tóm tắt đơn hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...items.map((item) => _buildOrderItem(item)),

                  const Divider(height: 40, thickness: 1),
                  _buildPriceRow("Tạm tính", Shoe.vndFormat.format(subtotalVND)),
                  _buildPriceRow("Phí vận chuyển", Shoe.vndFormat.format(shippingFee)),
                  if (_discount > 0) _buildPriceRow("Giảm giá voucher", "-${Shoe.vndFormat.format(_discount)}", color: Colors.green),
                  const Divider(thickness: 1),
                  _buildPriceRow("Tổng thanh toán", Shoe.vndFormat.format(finalTotalVND), fontSize: 22, bold: true, color: Colors.orange),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]),
              child: SizedBox(
                height: 62,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 10,
                  ),
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  child: _isPlacingOrder
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "ĐẶT HÀNG (${Shoe.vndFormat.format(finalTotalVND)})",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập $hint' : null,
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: item.shoe.image, width: 70, height: 70, fit: BoxFit.contain)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.shoe.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("Size: ${item.selectedSize}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                Text("× ${item.quantity}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Text(Shoe.vndFormat.format(item.totalPrice * Shoe.usdToVndRate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {double fontSize = 16, bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black)),
        ],
      ),
    );
  }
}

// ==================== ORDER BILL SCREEN (HOÀN CHỈNH & ĐẸP) ====================
class OrderBillScreen extends StatelessWidget {
  final String orderId;
  final String name;
  final String phone;
  final String address;
  final List<CartItem> items;
  final double subtotalVND;
  final double shippingFee;
  final double discount;
  final double totalVND;
  final String paymentMethod;
  final String? selectedBank;
  final DateTime orderDate;

  const OrderBillScreen({
    super.key,
    required this.orderId,
    required this.name,
    required this.phone,
    required this.address,
    required this.items,
    required this.subtotalVND,
    required this.shippingFee,
    required this.discount,
    required this.totalVND,
    required this.paymentMethod,
    this.selectedBank,
    required this.orderDate,
  });

  String _getPaymentText() {
    switch (paymentMethod) {
      case 'cod':
        return 'Thanh toán khi nhận hàng (COD)';
      case 'bank':
        return 'Chuyển khoản ngân hàng (${selectedBank ?? ''})';
      case 'momo':
        return 'Ví MoMo';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Đơn hàng của bạn", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header thành công
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 12),
                  const Text("Đặt hàng thành công!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text("Mã đơn hàng: $orderId", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Thời gian: ${dateFormat.format(orderDate)}", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text("Thông tin giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Người nhận: $name"),
                  Text("Số điện thoại: $phone"),
                  Text("Địa chỉ: $address"),
                  const SizedBox(height: 12),
                  Text("Phương thức thanh toán: ${_getPaymentText()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text("Chi tiết sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: item.shoe.image, width: 80, height: 80, fit: BoxFit.contain)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.shoe.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text("Size: ${item.selectedSize}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        Text("Số lượng: ${item.quantity}", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(Shoe.vndFormat.format(item.totalPrice * Shoe.usdToVndRate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            )),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Column(
                children: [
                  _buildPriceRow("Tạm tính", Shoe.vndFormat.format(subtotalVND)),
                  _buildPriceRow("Phí vận chuyển", Shoe.vndFormat.format(shippingFee)),
                  if (discount > 0) _buildPriceRow("Giảm giá", "-${Shoe.vndFormat.format(discount)}", color: Colors.green),
                  const Divider(),
                  _buildPriceRow("Tổng thanh toán", Shoe.vndFormat.format(totalVND), fontSize: 22, bold: true, color: Colors.orange),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng chia sẻ đang phát triển")));
                    },
                    child: const Text("CHIA SẺ ĐƠN HÀNG"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text("HOÀN TẤT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {double fontSize = 16, bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black)),
        ],
      ),
    );
  }
}

// OrderBillScreen giữ nguyên như trước (bạn đã có)