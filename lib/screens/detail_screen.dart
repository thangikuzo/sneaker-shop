// File: detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/shoe_model.dart';

class DetailScreen extends StatefulWidget {
  final Shoe shoe;
  const DetailScreen({super.key, required this.shoe});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Biến theo dõi trang ảnh hiện tại (mặc định là 0)
  int _activePage = 0;

  @override
  Widget build(BuildContext context) {
    // Lấy chiều cao màn hình để chia tỷ lệ cho đẹp
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // AppBar trong suốt để nút Back nổi lên trên ảnh
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
            margin: const EdgeInsets.only(right: 15),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.black),
              onPressed: () {},
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // --- PHẦN 1: SLIDER ẢNH ---
          SizedBox(
            height: size.height * 0.45, // Chiếm 45% chiều cao màn hình
            width: double.infinity,
            child: Stack(
              children: [
                // PageView để lướt qua lại
                PageView.builder(
                  itemCount: widget.shoe.images.length,
                  onPageChanged: (index) {
                    setState(() => _activePage = index);
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0), // Padding để ảnh không sát lề
                      child: Hero(
                        tag: widget.shoe.id, // Hiệu ứng chuyển cảnh mượt
                        child: CachedNetworkImage(
                          imageUrl: widget.shoe.images[index],
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    );
                  },
                ),

                // Các chấm tròn (Indicators)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.shoe.images.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _activePage == index ? 24 : 8, // Cái nào đang chọn thì dài ra
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

          // --- PHẦN 2: THÔNG TIN CHI TIẾT ---
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 35, 25, 0),
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
                  // Tên giày
                  Text(
                    widget.shoe.name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 15),

                  // Giá và Đánh giá (Ví dụ)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${widget.shoe.price.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 24, color: Colors.blueAccent, fontWeight: FontWeight.w900),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 22),
                          SizedBox(width: 4),
                          Text("4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(" (230 reviews)", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Mô tả
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        widget.shoe.description,
                        style: const TextStyle(color: Colors.grey, fontSize: 16, height: 1.6),
                      ),
                    ),
                  ),

                  // Nút Add to Cart
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C1C1C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 5,
                      ),
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, color: Colors.white),
                          SizedBox(width: 10),
                          Text("ADD TO CART", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}