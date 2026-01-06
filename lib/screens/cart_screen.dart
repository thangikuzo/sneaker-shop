// File: cart_screen.dart - Đã thêm chuyển sang màn hình Checkout (Thanh toán giống Shopee)
// Changes:
// - Nút "THANH TOÁN" giờ sẽ chuyển sang CheckoutScreen.
// - Giữ nguyên tất cả giao diện đẹp + giá VNĐ chính xác (tỷ giá 26.300 VND/USD).
// - Chỉ cần thêm 1 dòng import và sửa onPressed của nút thanh toán.

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart'; // ← THÊM DÒNG NÀY (điều chỉnh đường dẫn nếu file checkout_screen.dart nằm chỗ khác)

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

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    // Tỷ giá thực tế ngày 06/01/2026 ≈ 26.300 VND/USD
    const double usdToVndRate = 26300.0;

    num vnd(num usd) => usd * usdToVndRate;

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
                                  onTap: () => cart.decreaseQty(shoe.id),
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
                                  onTap: () => cart.increaseQty(shoe.id),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => cart.removeItem(shoe.id),
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

          // Summary - Tổng tiền
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
                  _PriceRow(label: "Tạm tính", valueText: formatVND(vnd(cart.subTotal))),
                  const SizedBox(height: 12),
                  _PriceRow(label: "Phí ship", valueText: formatVND(vnd(cart.shipping))),
                  const SizedBox(height: 16),
                  Container(height: 1.2, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng cộng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        formatVND(vnd(cart.total)),
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
                            builder: (_) => const CheckoutScreen(),
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

// Các class phụ giữ nguyên (không thay đổi)
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

  const _PriceRow({required this.label, required this.valueText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF666666), fontSize: 16)),
        Text(valueText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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