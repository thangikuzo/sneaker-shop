// File: lib/screens/detail_screen.dart - Đã thêm chọn size (3 size từ Firestore) + bắt buộc chọn size mới thêm giỏ
// Tính năng mới:
// - Hiển thị 3 nút size đẹp (ví dụ: 39 40 41) nếu sản phẩm có sizes.
// - Bấm chọn size → nút đen lên, nổi bật.
// - Bắt buộc chọn size mới được bấm "THÊM VÀO GIỎ HÀNG".
// - Nếu chưa có size trong Firestore → hiển thị thông báo "Chưa có size".
// - Khi thêm giỏ → toast báo rõ "Đã thêm size XX vào giỏ hàng".

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopsneaker/screens/cart_screen.dart';

import '../models/shoe_model.dart';
import '../providers/cart_provider.dart';
 // Đúng tên project của bạn

class DetailScreen extends StatefulWidget {
  final Shoe shoe;
  const DetailScreen({super.key, required this.shoe});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _activePage = 0;
  String? _selectedSize; // ← Biến lưu size người dùng chọn

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const BackButton(color: Colors.black),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.black),
              onPressed: () {
                Fluttertoast.showToast(
                  msg: "Chức năng yêu thích đang phát triển",
                  gravity: ToastGravity.CENTER,
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: size.height * 0.48,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: widget.shoe.images.length,
                  onPageChanged: (index) => setState(() => _activePage = index),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Hero(
                        tag: widget.shoe.id,
                        child: CachedNetworkImage(
                          imageUrl: widget.shoe.images[index],
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (_, __, ___) => const Icon(Icons.error, size: 50),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.shoe.images.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        height: 8,
                        width: _activePage == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _activePage == index ? Colors.black : const Color(0xFFA0A0A0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 35, 25, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shoe.name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.shoe.priceVND,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 24),
                            SizedBox(width: 6),
                            Text("4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            SizedBox(width: 4),
                            Text("(230 đánh giá)", style: TextStyle(color: Color(0xFF888888), fontSize: 15)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 30),

                    // === PHẦN CHỌN SIZE ===
                    const Text("Chọn size", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (widget.shoe.hasSizes) ...[
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: widget.shoe.sizes.map((sizeNum) {
                          final sizeStr = sizeNum % 1 == 0 ? sizeNum.toInt().toString() : sizeNum.toString();
                          final isSelected = _selectedSize == sizeStr;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedSize = sizeStr),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                                ],
                              ),
                              child: Text(
                                sizeStr,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedSize == null)
                        const Text("Vui lòng chọn size trước khi thêm vào giỏ", style: TextStyle(color: Colors.red, fontSize: 14)),
                    ] else
                      const Text("Sản phẩm này hiện chưa có size khả dụng", style: TextStyle(color: Colors.redAccent, fontSize: 16)),

                    const SizedBox(height: 30),

                    const Text("Mô tả sản phẩm", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      widget.shoe.description.isEmpty
                          ? "Chưa có mô tả chi tiết cho sản phẩm này."
                          : widget.shoe.description,
                      style: const TextStyle(color: Color(0xFF616161), fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 30),

                    // Nút thêm vào giỏ - chỉ enable khi đã chọn size
                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C1C1C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 8,
                        ),
                        onPressed: (widget.shoe.hasSizes && _selectedSize == null)
                            ? null // Disable nếu chưa chọn size
                            : () async {
                          await context.read<CartProvider>().addToCart(widget.shoe);

                          Fluttertoast.showToast(
                            msg: widget.shoe.hasSizes
                                ? "Đã thêm size $_selectedSize vào giỏ hàng ✅"
                                : "Đã thêm vào giỏ hàng ✅",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.black87,
                            textColor: Colors.white,
                            fontSize: 16,
                          );

                          // Reset chọn size sau khi thêm (tùy chọn)
                          setState(() => _selectedSize = null);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                            const SizedBox(width: 12),
                            Text(
                              widget.shoe.hasSizes
                                  ? (_selectedSize == null ? "CHỌN SIZE ĐỂ THÊM" : "THÊM VÀO GIỎ HÀNG")
                                  : "THÊM VÀO GIỎ HÀNG",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}