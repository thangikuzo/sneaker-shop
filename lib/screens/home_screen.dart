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

  // Mặc định chọn Nike, nhưng khi load từ Firebase có thể sẽ cần xử lý thêm nếu muốn dynamic hoàn toàn
  String selectedBrand = "Adidas";
  String searchText = "";

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
            const Row(
              children: [
                Text("Xin chào! ", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text("👋", style: TextStyle(fontSize: 28)),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Ô TÌM KIẾM
            _buildSearchBox(),
            const SizedBox(height: 30),

            // 2. DANH SÁCH HÃNG (LẤY TỪ FIREBASE)
            _buildSectionHeader("Chọn thương hiệu"),
            const SizedBox(height: 15),
            _buildBrandList(), // <--- Đã sửa thành StreamBuilder
            const SizedBox(height: 30),

            // 3. DANH SÁCH SẢN PHẨM
            _buildSectionHeader(searchText.isEmpty ? "Sản phẩm mới" : "Kết quả tìm kiếm"),
            const SizedBox(height: 15),

            StreamBuilder<List<Shoe>>(
              stream: db.sneakers,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<Shoe> allShoes = snapshot.data!;

                // --- LOGIC LỌC ĐÃ SỬA LẠI ---
                final List<Shoe> filteredShoes = allShoes.where((shoe) {
                  // A. Nếu đang tìm kiếm: Tìm theo TÊN (Bất kể hãng nào)
                  if (searchText.isNotEmpty) {
                    return shoe.name.toLowerCase().contains(searchText.toLowerCase());
                  }

                  // B. Nếu không tìm kiếm: Lọc theo TRƯỜNG BRAND trong Database
                  // So sánh shoe.brand với selectedBrand (Không phân biệt hoa thường)
                  return shoe.brand.trim().toLowerCase() == selectedBrand.trim().toLowerCase();
                }).toList();
                // ---------------------------

                if (filteredShoes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off, size: 40, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(
                            searchText.isNotEmpty
                                ? "Không tìm thấy giày '$searchText'"
                                : "Chưa có sản phẩm hãng $selectedBrand",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
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

  // --- WIDGET CON: SEARCH BOX ---
  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // Bo tròn hình viên thuốc
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchText = value;
          });
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Tìm kiếm giày sneaker...",
          hintStyle: TextStyle(color: Colors.grey),
          icon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // --- WIDGET CON: BRAND LIST (STREAM TỪ FIREBASE) ---
  Widget _buildBrandList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.brands, // Lắng nghe collection 'brands'
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Lỗi tải hãng");
        if (!snapshot.hasData) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));

        final brandList = snapshot.data!;

        if (brandList.isEmpty) return const Text("Chưa có hãng nào");

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: brandList.map((brandData) {
              final String name = brandData['name'] ?? 'Unknown';
              final String imageUrl = brandData['image'] ?? '';

              bool isSelected = selectedBrand.toLowerCase() == name.toLowerCase();
              bool isSearching = searchText.isNotEmpty;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedBrand = name;
                    // searchText = ""; // Bỏ comment dòng này nếu muốn bấm Hãng thì xóa tìm kiếm
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 15, bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    // Nếu đang search thì không highlight hãng để tránh nhầm lẫn
                    color: isSelected && !isSearching ? Colors.black : Colors.white,
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
                      if (imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 28,
                          width: 28,
                          fit: BoxFit.contain,
                          // KHÔNG set color ở đây để giữ màu gốc của Logo
                          placeholder: (_, __) => const SizedBox(width: 28),
                          errorWidget: (_, __, ___) => const Icon(Icons.category, size: 20),
                        ),
                      const SizedBox(width: 10),
                      Text(
                        name,
                        style: TextStyle(
                          color: isSelected && !isSearching ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (searchText.isEmpty)
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
                // Ảnh sản phẩm
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    child: Hero(
                      tag: shoe.id,
                      child: CachedNetworkImage(
                        imageUrl: shoe.image, // Getter tự lấy ảnh đầu tiên
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),
                // Thông tin tên và giá
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
                          shoe.priceVND, // Hiển thị giá VNĐ
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Nút Yêu thích (Tim)
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