// File: lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

/// Format tiền VNĐ đẹp: 2893000 → 2.893.000 ₫
String formatVND(num amount) {
  final s = amount.round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final posFromEnd = s.length - i;
    buffer.write(s[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
  }
  return "${buffer.toString()} ₫";
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _voucherController = TextEditingController();
  String _appliedVoucher = '';
  String _voucherMessage = '';

  // Danh sách voucher hợp lệ (bạn có thể mở rộng)
  final Map<String, Voucher> _vouchers = {
    'SALE10': Voucher(type: VoucherType.percent, value: 10, message: 'Giảm 10%'),
    'SALE20': Voucher(type: VoucherType.percent, value: 20, message: 'Giảm 20%'),
    'FREESHIP': Voucher(type: VoucherType.freeShip, value: 0, message: 'Miễn phí vận chuyển'),
  };

  void _applyVoucher() {
    final code = _voucherController.text.trim().toUpperCase();
    if (_vouchers.containsKey(code)) {
      setState(() {
        _appliedVoucher = code;
        _voucherMessage = _vouchers[code]!.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Áp dụng mã $_voucherMessage thành công!"), backgroundColor: Colors.green),
      );
    } else {
      setState(() {
        _appliedVoucher = '';
        _voucherMessage = 'Mã không hợp lệ';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mã giảm giá không hợp lệ"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    // Tỷ giá ngày 06/01/2026
    const double usdToVndRate = 26300.0;
    num vnd(num usd) => usd * usdToVndRate;

    // Tính giảm giá từ voucher
    double discountVND = 0;
    num shippingVND = vnd(cart.shipping); // mặc định phí ship

    if (_appliedVoucher.isNotEmpty) {
      final voucher = _vouchers[_appliedVoucher]!;
      if (voucher.type == VoucherType.percent) {
        discountVND = vnd(cart.subTotal) * (voucher.value / 100);
      } else if (voucher.type == VoucherType.freeShip) {
        shippingVND = 0;
      }
    }

    final totalVND = vnd(cart.subTotal) + shippingVND - discountVND;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const BackButton(color: Colors.black),
        ),
        title: const Text(
          "Giỏ hàng",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => cart.clear(),
              child: const Text(
                "Xoá hết",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? const _EmptyCart()
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = items[index];
                final shoe = item.shoe;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 100,
                          height: 100,
                          color: const Color(0xFFF3F4F6),
                          child: CachedNetworkImage(
                            imageUrl: shoe.image,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shoe.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Size: ${item.selectedSize}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              formatVND(vnd(shoe.price)),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _QtyBtn(
                                  icon: Icons.remove,
                                  onTap: () => cart.decreaseQty(shoe.id, item.selectedSize),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "${item.quantity}",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _QtyBtn(
                                  icon: Icons.add,
                                  onTap: () => cart.increaseQty(shoe.id, item.selectedSize),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => cart.removeItem(shoe.id, item.selectedSize),
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.redAccent,
                                  tooltip: "Xoá sản phẩm",
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Summary - Voucher + Tổng tiền
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -8)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nhập mã giảm giá
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _voucherController,
                          decoration: InputDecoration(
                            hintText: "Nhập mã giảm giá",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _applyVoucher,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 24)),
                        child: const Text("Áp dụng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (_voucherMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _voucherMessage,
                        style: TextStyle(
                          color: _appliedVoucher.isNotEmpty ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  _PriceRow(label: "Tạm tính", valueText: formatVND(vnd(cart.subTotal))),
                  const SizedBox(height: 12),
                  _PriceRow(label: "Phí ship", valueText: formatVND(shippingVND)),
                  if (discountVND > 0)
                    _PriceRow(label: "Giảm giá", valueText: "-${formatVND(discountVND)}", color: Colors.green),
                  const SizedBox(height: 16),
                  Container(height: 1.2, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng cộng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        formatVND(totalVND),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C1C1C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      onPressed: items.isEmpty
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(appliedVoucher: '',),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "THANH TOÁN",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum VoucherType { percent, freeShip }

class Voucher {
  final VoucherType type;
  final double value; // % hoặc 0 nếu free ship
  final String message;

  Voucher({required this.type, required this.value, required this.message});
}

// Các widget phụ giữ nguyên
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          elevation: 2,
        ),
        onPressed: onTap,
        child: Icon(icon, size: 20, color: Colors.black),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String valueText;
  final Color? color;

  const _PriceRow({required this.label, required this.valueText, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF666666), fontSize: 16)),
        Text(valueText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color ?? Colors.black)),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 70, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 32),
            const Text("Giỏ hàng đang trống", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "Hãy thêm những đôi giày bạn thích vào giỏ nhé!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "TIẾP TỤC MUA SẮM",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}