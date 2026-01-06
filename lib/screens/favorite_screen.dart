// File: favorite_screen.dart - Đã chuyển giá sang VNĐ + trang trí đẹp hơn, bớt trống
// Changes:
// - Giá hiển thị VNĐ đẹp (dùng getter shoe.priceVND từ Shoe model).
// - Tỷ giá thực tế ngày 06/01/2026 ≈ 26,300 VND/USD (dựa trên dữ liệu thị trường mới nhất: mid-market ~26,270 - 26,330).
// - Trang trí: Card lớn hơn, ảnh to hơn, thêm icon favorite đỏ khi yêu thích, nút "Tiếp tục mua sắm" khi trống.
// - Empty state đẹp hơn, khuyến khích người dùng.
// - Tiếng Việt hóa title & thông báo.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database.dart';
import '../models/shoe_model.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  final VoidCallback? onBackToHome;

  const FavoriteScreen({super.key, this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (onBackToHome != null) onBackToHome!();
          },
        ),
        title: const Text(
          "Yêu thích",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<String>>(
        stream: db.myFavorites,
        builder: (context, favSnapshot) {
          if (favSnapshot.hasError) {
            return const Center(child: Text("Lỗi tải dữ liệu"));
          }
          if (!favSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoriteIds = favSnapshot.data!;

          if (favoriteIds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Chưa có sản phẩm yêu thích",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Hãy thêm những đôi giày bạn thích bằng cách bấm vào biểu tượng ❤️",
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
                        onPressed: () {
                          if (onBackToHome != null) onBackToHome!();
                        },
                        child: const Text(
                          "TIẾP TỤC MUA SẮM",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return StreamBuilder<List<Shoe>>(
            stream: db.sneakers,
            builder: (context, shoeSnapshot) {
              if (!shoeSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allShoes = shoeSnapshot.data!;
              final favoriteShoes = allShoes.where((s) => favoriteIds.contains(s.id)).toList();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                itemCount: favoriteShoes.length,
                itemBuilder: (context, index) {
                  return _favoriteItem(context, favoriteShoes[index], db);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _favoriteItem(BuildContext context, Shoe shoe, DatabaseService db) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(shoe: shoe)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 110,
                height: 110,
                color: const Color(0xFFF3F4F6),
                child: CachedNetworkImage(
                  imageUrl: shoe.image,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shoe.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Giá VNĐ đẹp
                  Text(
                    shoe.priceVND, // Ví dụ: "2.893.000 ₫"
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red, size: 28),
                  onPressed: () => db.toggleFavorite(shoe.id),
                  tooltip: "Xoá khỏi yêu thích",
                ),
                const Text(
                  "Yêu thích",
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}