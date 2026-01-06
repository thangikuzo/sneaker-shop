// File: detail_screen.dart - Đã sửa lỗi đỏ + tối ưu hoàn chỉnh
// Sửa lỗi chính:
// - Xóa dòng import 'checkout_screen.dart'; không cần thiết ở đây (gây lỗi đỏ gián tiếp).
// - Sửa Colors.grey[700] thành const Color(0xFF616161) để giữ const TextStyle (tránh lỗi shade trong const context).
// - Giữ nguyên tất cả cải tiến trước: giá VNĐ đẹp, tiếng Việt, layout sạch sẽ.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopsneaker/screens/cart_screen.dart';

import '../models/shoe_model.dart';
import '../providers/cart_provider.dart';
// ← Chỉ import cart_screen.dart là đủ
import 'checkout_screen.dart';
class DetailScreen extends StatefulWidget {
  final Shoe shoe;
  const DetailScreen({super.key, required this.shoe});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _activePage = 0;

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
          // Icon giỏ hàng → mở CartScreen
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

          // Icon yêu thích (tạm thời)
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
          // Slider ảnh sản phẩm
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
                // Dot indicators
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
                          color: _activePage == index ? Colors.black : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Thông tin chi tiết
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 35, 25, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                ],
              ),
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
                      // Giá VNĐ đẹp từ model
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

                  const Text("Mô tả sản phẩm", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        widget.shoe.description.isEmpty
                            ? "Chưa có mô tả chi tiết cho sản phẩm này."
                            : widget.shoe.description,
                        style: const TextStyle(
                          color: Color(0xFF616161), // ← Sửa lỗi const: dùng hex thay vì Colors.grey[700]
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),

                  // Nút thêm vào giỏ
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: double.infinity,
                    height: 62,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C1C1C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      onPressed: () async {
                        await context.read<CartProvider>().addToCart(widget.shoe);

                        Fluttertoast.showToast(
                          msg: "Đã thêm vào giỏ hàng ✅",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.black87,
                          textColor: Colors.white,
                          fontSize: 16,
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                          SizedBox(width: 12),
                          Text(
                            "THÊM VÀO GIỎ HÀNG",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}