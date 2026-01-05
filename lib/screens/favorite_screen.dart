// File: favorite_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database.dart';
import '../models/shoe_model.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  // Thêm biến callback
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
        // --- SỬA NÚT BACK ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // Khi bấm back thì gọi hàm chuyển về Home
            if (onBackToHome != null) {
              onBackToHome!();
            }
          },
        ),
        title: const Text("My Wishlist", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<String>>(
        stream: db.myFavorites,
        builder: (context, favSnapshot) {
          if (favSnapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));
          if (!favSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          final favoriteIds = favSnapshot.data!;

          if (favoriteIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Chưa có sản phẩm yêu thích", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return StreamBuilder<List<Shoe>>(
            stream: db.sneakers,
            builder: (context, shoeSnapshot) {
              if (!shoeSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final allShoes = shoeSnapshot.data!;
              final favoriteShoes = allShoes.where((s) => favoriteIds.contains(s.id)).toList();

              // Thêm padding dưới cùng để không bị che bởi bottom bar
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(shoe: shoe))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: CachedNetworkImage(imageUrl: shoe.image, fit: BoxFit.contain),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shoe.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text("\$${shoe.price}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                db.toggleFavorite(shoe.id);
              },
            )
          ],
        ),
      ),
    );
  }
}