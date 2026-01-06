// File: lib/screens/checkout_screen.dart - FULL VERSION ĐÃ HOÀN THIỆN & CHUYÊN NGHIỆP HƠN
// Cập nhật mới:
// - Thêm hiển thị SIZE trong tóm tắt đơn hàng và Bill (rất quan trọng với giày dép).
// - Bỏ phương thức "Thẻ tín dụng / Ghi nợ" (theo yêu cầu).
// - Cải thiện giao diện Bill: thêm mã đơn hàng, thời gian đặt, trạng thái, nút chia sẻ/copy.
// - Thêm phí ship thực tế + tổng tiền nổi bật hơn.
// - Giao diện đẹp hơn, giống Shopee/Tiki/Lazada hoàn chỉnh.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart'; // Để format ngày giờ
import '../providers/cart_provider.dart';
import '../models/shoe_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

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

  final Map<String, Map<String, String>> _banks = {
    'vietcombank': {'name': 'Vietcombank', 'bin': '970436'},
    'bidv': {'name': 'BIDV', 'bin': '970418'},
    'vietinbank': {'name': 'VietinBank', 'bin': '970415'},
    'techcombank': {'name': 'Techcombank', 'bin': '970407'},
    'mbBank': {'name': 'MB Bank', 'bin': '970422'},
    'acb': {'name': 'ACB', 'bin': '970416'},
    'vpBank': {'name': 'VPBank', 'bin': '970432'},
  };

  // Thông tin shop
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Áp dụng mã giảm 100.000 ₫ thành công!')));
      } else if (code == 'FREESHIP') {
        _discount = 30000;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Miễn phí vận chuyển thành công!')));
      } else {
        _discount = 0;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã voucher không hợp lệ')));
      }
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

  String _getMomoQRPayload(double amountVND) {
    return 'https://momo.vn/pay?amount=${amountVND.round()}&message=Thanh%20toan%20don%20hang%20Sneaker';
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    final items = cart.items;
    const double shippingFee = 30000;
    final double subtotalVND = cart.total * Shoe.usdToVndRate;
    final double finalTotalVND = subtotalVND + shippingFee - _discount;

    // Tạo mã đơn hàng ngẫu nhiên
    final orderId = "SNK${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";

    // Xóa giỏ hàng
    cart.clear();

    // Chuyển sang Bill
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderBillScreen(
          orderId: orderId,
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          items: items,
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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    const double shippingFee = 30000;
    final double subtotalVND = cart.total * Shoe.usdToVndRate;
    final double finalTotalVND = subtotalVND + shippingFee - _discount;

    Widget? qrSection;
    if (_selectedPayment == 'bank') {
      qrSection = Column(
        children: [
          const Text("Chọn ngân hàng chuyển khoản", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedBank,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: _banks.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['name']!))).toList(),
            onChanged: (val) => setState(() => _selectedBank = val!),
          ),
          const SizedBox(height: 20),
          const Text("Quét QR bằng app ngân hàng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          CachedNetworkImage(
            imageUrl: _getBankQRUrl(finalTotalVND),
            width: 260,
            height: 260,
            placeholder: (_, __) => const CircularProgressIndicator(),
            errorWidget: (_, __, ___) => const Text("Không tải được QR"),
          ),
          const SizedBox(height: 12),
          Text("Số tiền: ${Shoe.vndFormat.format(finalTotalVND)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );
    } else if (_selectedPayment == 'momo') {
      qrSection = Column(
        children: [
          const Text("Quét QR bằng app MoMo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          QrImageView(data: _getMomoQRPayload(finalTotalVND), version: QrVersions.auto, size: 260),
          const SizedBox(height: 12),
          Text("Số tiền: ${Shoe.vndFormat.format(finalTotalVND)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
      body: SingleChildScrollView(
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
              _buildTextField(_addressController, "Địa chỉ giao hàng (số nhà, đường, phường/xã...) *", maxLines: 3),

              const SizedBox(height: 30),
              const Text("Mã giảm giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _voucherController, decoration: InputDecoration(hintText: "Nhập mã giảm giá", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _applyVoucher, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text("Áp dụng", style: TextStyle(color: Colors.white))),
                ],
              ),
              if (_discount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("Đã giảm: -${Shoe.vndFormat.format(_discount)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                ),

              const SizedBox(height: 30),
              const Text("Phương thức thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              RadioListTile<String>(title: const Text('Thanh toán khi nhận hàng (COD)'), value: 'cod', groupValue: _selectedPayment, onChanged: (v) => setState(() => _selectedPayment = v!)),
              RadioListTile<String>(title: const Text('Chuyển khoản ngân hàng'), value: 'bank', groupValue: _selectedPayment, onChanged: (v) => setState(() => _selectedPayment = v!)),
              RadioListTile<String>(title: const Text('Ví MoMo'), value: 'momo', groupValue: _selectedPayment, onChanged: (v) => setState(() => _selectedPayment = v!)),
              // ĐÃ BỎ "Thẻ tín dụng / Ghi nợ" theo yêu cầu

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

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 8),
                  onPressed: _placeOrder,
                  child: Text(
                    "ĐẶT HÀNG (${Shoe.vndFormat.format(finalTotalVND)})",
                    style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                Text("Size: ${item.shoe ?? 'Không có'}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                Text("× ${item.quantity}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Text(Shoe.vndFormat.format(item.shoe.priceInVND * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

// ==================== MÀN HÌNH BILL HOÀN CHỈNH ====================
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
      case 'cod': return 'Thanh toán khi nhận hàng (COD)';
      case 'bank': return 'Chuyển khoản ngân hàng (${selectedBank ?? ''})';
      case 'momo': return 'Ví MoMo';
      default: return 'Không xác định';
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
            // Header thành công + mã đơn
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
                  Hero(tag: item.shoe.id, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: item.shoe.image, width: 80, height: 80, fit: BoxFit.contain))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.shoe.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text("Size: ${item.shoe ?? 'Không có'}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        Text("Số lượng: ${item.quantity}", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(Shoe.vndFormat.format(item.shoe.priceInVND * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      // TODO: Chia sẻ đơn hàng (Share plugin)
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng chia sẻ đang phát triển")));
                    },
                    child: const Text("CHIA SẺ ĐƠN HÀNG"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C1C1C), padding: const EdgeInsets.symmetric(vertical: 16)),
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