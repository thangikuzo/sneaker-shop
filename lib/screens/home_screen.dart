// File: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopsneaker/screens/detail_screen.dart';
import '../services/database.dart';
import '../models/shoe_model.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? openDrawer;

  const HomeScreen({super.key, this.openDrawer});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseService();
  String selectedBrand = "All"; // Mặc định hiển thị tất cả

  // Danh sách hãng có sẵn (logo)
  final Map<String, String> brandLogos = {
    "All": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767524832/logo_nike_psyjzd.png", // dùng tạm icon all
    "Nike": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767524832/logo_nike_psyjzd.png",
    "Vans": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767524833/logo_vans_zzuwql.png",
    "Puma": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767524830/logo_puma_gemhjc.png",
    "Adidas": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767524829/logo_adidas_xciubb.png",
    "Jordan": "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767525895/logo_jordan_crjyjs.jpg",
  };

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
          onPressed: widget.openDrawer,
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
                // TODO: Navigator.push to CartScreen
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
            const Row(
              children: [
                Text("Xin chào! ", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text("👋", style: TextStyle(fontSize: 28)),
              ],
            ),
            const SizedBox(height: 30),

            // Search Box (giữ nguyên)
            _buildSearchBox(),
            const SizedBox(height: 30),

            // Chọn thương hiệu
            _buildSectionHeader("Chọn thương hiệu"),
            const SizedBox(height: 15),
            _buildBrandList(),
            const SizedBox(height: 30),

            // Sản phẩm
            _buildSectionHeader("Sản phẩm mới"),
            const SizedBox(height: 15),

            // Danh sách sản phẩm realtime
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

                // Lọc theo hãng (nếu không phải "All")
                final List<Shoe> filteredShoes = allShoes.where((shoe) {
                  if (selectedBrand == "All") return true;
                  return shoe.brand == selectedBrand;
                }).toList();

                if (filteredShoes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        "Không có sản phẩm nào cho thương hiệu này",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: brandLogos.keys.map((brandName) {
          bool isSelected = selectedBrand == brandName;
          return GestureDetector(
            onTap: () => setState(() => selectedBrand = brandName),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 15, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (brandName != "All")
                    CachedNetworkImage(
                      imageUrl: brandLogos[brandName]!,
                      height: 32,
                      width: 32,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.category, size: 25),
                    )
                  else
                    const Icon(Icons.apps, color: Colors.black, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    brandName,
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
    final bool outOfStock = !shoe.inStock; // Dùng getter từ model
    final int availableSizeCount = shoe.availableSizes.length;

    return GestureDetector(
      onTap: outOfStock
          ? null // Không cho bấm nếu hết hàng
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(shoe: shoe)),
        );
      },
      child: Opacity(
        opacity: outOfStock ? 0.6 : 1.0, // Làm mờ nếu hết hàng
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10)),
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
                          Text(
                            shoe.priceVND,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                          ),
                          const SizedBox(height: 6),
                          if (!outOfStock)
                            Text(
                              "Còn $availableSizeCount size",
                              style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600),
                            )
                          else
                            const Text(
                              "Hết hàng",
                              style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Nút Favorite
              Positioned(
                top: 15,
                right: 15,
                child: StreamBuilder<List<String>>(
                  stream: db.myFavorites,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final favoriteIds = snapshot.data!;
                    final isLoved = favoriteIds.contains(shoe.id);
                    return GestureDetector(
                      onTap: outOfStock ? null : () => db.toggleFavorite(shoe.id),
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

              // Badge hết hàng (nếu cần nổi bật hơn)
              if (outOfStock)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: const Text(
                      "HẾT HÀNG",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}