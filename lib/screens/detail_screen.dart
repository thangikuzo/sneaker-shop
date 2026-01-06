// File: lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopsneaker/screens/cart_screen.dart';

import '../models/shoe_model.dart';
import '../providers/cart_provider.dart';

class DetailScreen extends StatefulWidget {
  final Shoe shoe;
  const DetailScreen({super.key, required this.shoe});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _activePage = 0;
  String? _selectedSize;
  int _quantity = 1;

  List<String> get availableSizes =>
      widget.shoe.sizes.where((size) => widget.shoe.stockOfSize(size) > 0).toList();

  bool get isInStock => widget.shoe.inStock;
  bool get canAddToCart => isInStock && _selectedSize != null && _quantity > 0;

  int get maxQuantity => _selectedSize != null ? widget.shoe.stockOfSize(_selectedSize!) : 0;

  // DỮ LIỆU MẪU ĐÁNH GIÁ (có khen, chê giá đắt/rẻ, size, chất lượng...)
  final List<Map<String, dynamic>> _reviews = [
    {
      "name": "Nguyễn Văn A",
      "rating": 5,
      "comment": "Giày đẹp, chất lượng tốt, đi rất êm chân. Đúng hàng auth, đáng tiền!",
      "date": "2 ngày trước",
    },
    {
      "name": "Trần Thị B",
      "rating": 4,
      "comment": "Đẹp lung linh nhưng giá hơi đắt so với store. Ship nhanh, đóng gói cẩn thận.",
      "date": "1 tuần trước",
    },
    {
      "name": "Lê Văn C",
      "rating": 3,
      "comment": "Size hơi nhỏ hơn bảng size US, mình đi 41 bình thường phải chọn 42 mới vừa. Chất lượng tạm ổn.",
      "date": "2 tuần trước",
    },
    {
      "name": "Phạm Thị D",
      "rating": 5,
      "comment": "Rẻ hơn store gần 1 triệu, hàng auth 100%. Sẽ ủng hộ shop dài dài!",
      "date": "1 tháng trước",
    },
    {
      "name": "Hoàng Văn E",
      "rating": 4,
      "comment": "Màu trắng đẹp nhưng dễ bẩn, may là dễ lau. Tổng thể rất ưng, đi thoải mái.",
      "date": "1 tháng trước",
    },
    {
      "name": "Vũ Minh F",
      "rating": 5,
      "comment": "Form giày chuẩn, nhẹ chân, đi cả ngày không mỏi. Shop tư vấn nhiệt tình.",
      "date": "2 tháng trước",
    },
  ];

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.black),
              onPressed: () => Fluttertoast.showToast(msg: "Chức năng yêu thích đang phát triển", gravity: ToastGravity.CENTER),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.48,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: widget.shoe.images.length,
                        onPageChanged: (value) => setState(() => _activePage = value),
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

                Container(
                  padding: const EdgeInsets.fromLTRB(25, 35, 25, 100),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
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
                          Text(
                            widget.shoe.priceVND,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 24),
                              const SizedBox(width: 6),
                              const Text("4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(width: 4),
                              Text("(${widget.shoe.totalStock} còn hàng)", style: const TextStyle(color: Color(0xFF888888), fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      const Text("Chọn size", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      if (widget.shoe.hasSizes) ...[
                        if (availableSizes.isEmpty)
                          const Center(child: Text("Hết hàng tất cả size", style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w600)))
                        else
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.shoe.sizes.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final sizeStr = widget.shoe.sizes[index].toString();
                                final stock = widget.shoe.stockOfSize(sizeStr);
                                final isAvailable = stock > 0;
                                final isSelected = _selectedSize == sizeStr;

                                return GestureDetector(
                                  onTap: isAvailable ? () => setState(() {
                                    _selectedSize = sizeStr;
                                    _quantity = 1;
                                  }) : null,
                                  child: Opacity(
                                    opacity: isAvailable ? 1.0 : 0.4,
                                    child: Container(
                                      width: 80,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.black : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300, width: isSelected ? 2 : 1),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                                      ),
                                      child: Center(
                                        child: Text(
                                          sizeStr,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 20),

                        if (_selectedSize != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Số lượng:", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 20),
                              _qtyButton(Icons.remove, () {
                                if (_quantity > 1) setState(() => _quantity--);
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text("$_quantity", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                              _qtyButton(Icons.add, () {
                                if (_quantity < maxQuantity) setState(() => _quantity++);
                              }),
                              const SizedBox(width: 12),
                              Text("Còn $maxQuantity đôi", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          ),

                        const SizedBox(height: 16),

                        if (_selectedSize == null && isInStock)
                          const Text("👆 Vui lòng chọn size để tiếp tục", style: TextStyle(color: Colors.red, fontSize: 15)),
                      ] else
                        const Text("Sản phẩm chưa có thông tin size", style: TextStyle(color: Colors.orangeAccent, fontSize: 16)),

                      const SizedBox(height: 30),

                      // === ĐÁNH GIÁ SẢN PHẨM VỚI DỮ LIỆU MẪU ===
                      const Text("Đánh giá sản phẩm", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          const Text("4.8", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text("(${_reviews.length} đánh giá)", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._reviews.map((review) => _buildReview(
                        review["name"],
                        review["rating"],
                        review["comment"],
                        review["date"],
                      )),

                      const SizedBox(height: 30),

                      const Text("Mô tả sản phẩm", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        widget.shoe.description.isEmpty ? "Chưa có mô tả chi tiết cho sản phẩm này." : widget.shoe.description,
                        style: const TextStyle(color: Color(0xFF616161), fontSize: 16, height: 1.6),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // NÚT THÊM GIỎ HÀNG FIXED BOTTOM
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(25, 12, 25, MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: SizedBox(
                height: 62,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAddToCart ? const Color(0xFF1C1C1C) : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: canAddToCart ? 10 : 0,
                  ),
                  onPressed: canAddToCart
                      ? () async {
                    await context.read<CartProvider>().addMultipleToCart(
                      shoe: widget.shoe,
                      selectedSize: _selectedSize!,
                      quantity: _quantity,
                    );

                    Fluttertoast.showToast(
                      msg: "Đã thêm $_quantity đôi size $_selectedSize vào giỏ hàng ✅",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.black87,
                      textColor: Colors.white,
                      fontSize: 16,
                    );

                    setState(() {
                      _selectedSize = null;
                      _quantity = 1;
                    });
                  }
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                      const SizedBox(width: 12),
                      Text(
                        isInStock
                            ? (_selectedSize == null ? "CHỌN SIZE ĐỂ ĐẶT HÀNG" : "THÊM $_quantity ĐÔI VÀO GIỎ")
                            : "HẾT HÀNG",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  // WIDGET HIỂN THỊ MỖI BÌNH LUẬN
  Widget _buildReview(String name, int rating, String comment, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 12),
              Row(
                children: List.generate(5, (i) => Icon(
                  Icons.star,
                  size: 18,
                  color: i < rating ? Colors.amber : Colors.grey.shade300,
                )),
              ),
              const Spacer(),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(fontSize: 15, height: 1.4)),
          const Divider(height: 30),
        ],
      ),
    );
  }
}