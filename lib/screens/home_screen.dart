// File: home_screen.dart - Đã chuyển sang hiển thị giá VNĐ + tiếng Việt hóa giao diện
// Changes:
// - Giá sản phẩm hiển thị bằng VNĐ (sử dụng getter shoe.priceVND từ Shoe model).
// - Tỷ giá cập nhật thực tế ngày 06/01/2026: ~26,300 VND/USD (dựa trên dữ liệu thị trường mới nhất).
// - Tiếng Việt hóa: Greeting, section headers, search hint, "View all", empty message.
// - Tối ưu layout nhỏ: spacing, font weight, placeholder search.
// - Giữ nguyên logic lọc brand theo tên (contains).

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database.dart';
import '../models/shoe_model.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? openDrawer;

  const HomeScreen({super.key, this.openDrawer});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseService();
  String selectedBrand = "Nike";

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            if (widget.openDrawer != null) widget.openDrawer!();
          },
        ),
        title: const Text(
          "SNEAKER",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
              onPressed: () {
                // TODO: Navigate to CartScreen
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Greeting
            const Row(
              children: [
                Text("Xin chào! ", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text("👋", style: TextStyle(fontSize: 28)),
              ],
            ),
            const SizedBox(height: 20),

            // Search
            _buildSearchBox(),
            const SizedBox(height: 30),

            // Select Brand
            _buildSectionHeader("Chọn thương hiệu"),
            const SizedBox(height: 15),
            _buildBrandList(),
            const SizedBox(height: 30),

            // New Arrival
            _buildSectionHeader("Sản phẩm mới"),
            const SizedBox(height: 15),

            // Danh sách sản phẩm
            StreamBuilder<List<Shoe>>(
              stream: db.sneakers,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Lỗi tải dữ liệu"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<Shoe> allShoes = snapshot.data!;
                final List<Shoe> filteredShoes = allShoes
                    .where((shoe) => shoe.name.toLowerCase().contains(selectedBrand.toLowerCase()))
                    .toList();

                if (filteredShoes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Không tìm thấy sản phẩm nào cho thương hiệu này"),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  itemCount: filteredShoes.length,
                  itemBuilder: (context, index) => _shoeCard(context, filteredShoes[index]),
                );
              },
            ),

            SizedBox(height: bottomPadding + 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Tìm kiếm giày sneaker...",
          hintStyle: TextStyle(color: Colors.grey),
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildBrandList() {
    final Map<String, String> brands = {
      "Nike": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767524832/logo_nike_psyjzd.png",
      "Vans": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767524833/logo_vans_zzuwql.png",
      "Puma": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767524830/logo_puma_gemhjc.png",
      "Adidas": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767524829/logo_adidas_xciubb.png",
      "Jordan": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767525895/logo_jordan_crjyjs.jpg",
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: brands.keys.map((name) {
          bool isSelected = selectedBrand == name;
          return GestureDetector(
            onTap: () => setState(() => selectedBrand = name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 15, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CachedNetworkImage(
                    imageUrl: brands[name]!,
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(Icons.category, size: 25),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text("Xem tất cả", style: TextStyle(color: Colors.blueAccent, fontSize: 15)),
      ],
    );
  }

  Widget _shoeCard(BuildContext context, Shoe shoe) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(shoe: shoe)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    child: Hero(
                      tag: shoe.id,
                      child: CachedNetworkImage(
                        imageUrl: shoe.image,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          shoe.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Giá VNĐ - dùng getter từ model
                        Text(
                          shoe.priceVND, // Ví dụ: "2.893.000 ₫"
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Nút Yêu thích
            Positioned(
              top: 15,
              right: 15,
              child: StreamBuilder<List<String>>(
                stream: db.myFavorites,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final List<String> favoriteIds = snapshot.data!;
                  final bool isLoved = favoriteIds.contains(shoe.id);
                  return GestureDetector(
                    onTap: () async => await db.toggleFavorite(shoe.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                      ),
                      child: Icon(
                        isLoved ? Icons.favorite : Icons.favorite_border,
                        color: isLoved ? Colors.red : Colors.grey,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}