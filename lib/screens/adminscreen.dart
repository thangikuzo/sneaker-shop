import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database.dart';
import '../models/shoe_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "Sản phẩm", icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: "Hãng", icon: Icon(Icons.category_outlined)),
            Tab(text: "User", icon: Icon(Icons.people_alt_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductTab(),
          _buildBrandTab(), // Đã cập nhật tính năng Sửa/Xóa
          _buildUserTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.amber),
        label: const Text("Thêm Mới", style: TextStyle(color: Colors.white)),
        onPressed: () {
          // Tab 0: Thêm sản phẩm
          if (_tabController.index == 0) _showProductDialog(null);
          // Tab 1: Thêm hãng (Truyền null để báo là thêm mới)
          if (_tabController.index == 1) _showBrandDialog(null);
        },
      ),
    );
  }

  // ==================== TAB 1: QUẢN LÝ SẢN PHẨM ====================
  Widget _buildProductTab() {
    return StreamBuilder<List<Shoe>>(
      stream: db.sneakers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final shoes = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: shoes.length,
          itemBuilder: (context, index) {
            final shoe = shoes[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: shoe.image,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                title: Text(shoe.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("${shoe.brand} • ${shoe.priceVND}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    Text("ID: ${shoe.id}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') _showProductDialog(shoe);
                    if (value == 'delete') _confirmDelete(shoe.id);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text("Sửa")])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Xóa")])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== TAB 2: QUẢN LÝ HÃNG (ĐÃ CẬP NHẬT) ====================
  Widget _buildBrandTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.brands,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: Text("Đang tải..."));
        final brands = snapshot.data!;

        if (brands.isEmpty) return const Center(child: Text("Chưa có hãng nào"));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: brands.length,
          itemBuilder: (context, index) {
            final brand = brands[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                leading: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: brand['image'] ?? "",
                    width: 40, height: 40,
                    fit: BoxFit.contain,
                    errorWidget: (_,__,___) => const Icon(Icons.broken_image),
                  ),
                ),
                title: Text(brand['name'], style: const TextStyle(fontWeight: FontWeight.bold)),

                // [MỚI] Thêm nút Edit và Delete cho Hãng
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showBrandDialog(brand), // Truyền data hãng vào để sửa
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteBrand(brand['name']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== TAB 3: QUẢN LÝ USER ====================
  Widget _buildUserTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.allUsers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isAdmin = user['role'] == 'admin';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isAdmin ? Colors.black : Colors.grey[300],
                child: Icon(Icons.person, color: isAdmin ? Colors.amber : Colors.grey),
              ),
              title: Text(user['email'] ?? "No Email"),
              subtitle: Text(isAdmin ? "Admin System" : "Customer"),
              trailing: isAdmin ? const Icon(Icons.verified, color: Colors.blue) : null,
            );
          },
        );
      },
    );
  }

  // ==================== DIALOG THÊM / SỬA SẢN PHẨM ====================
  void _showProductDialog(Shoe? shoe) {
    final isEdit = shoe != null;
    final nameController = TextEditingController(text: shoe?.name);
    final priceController = TextEditingController(text: shoe?.price.toString());
    final brandController = TextEditingController(text: shoe?.brand ?? "Nike");
    final descController = TextEditingController(text: shoe?.description);
    final imagesController = TextEditingController(text: shoe?.images.join(", "));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Cập nhật sản phẩm" : "Thêm giày mới"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField(nameController, "Tên giày"),
              Row(
                children: [
                  Expanded(child: _inputField(priceController, "Giá (USD)", isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(brandController, "Hãng")),
                ],
              ),
              _inputField(imagesController, "Link ảnh (Phân cách bằng dấu phẩy)", maxLines: 3),
              _inputField(descController, "Mô tả", maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              List<String> imageList = imagesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              final newShoe = Shoe(
                id: isEdit ? shoe!.id : "",
                name: nameController.text,
                price: double.tryParse(priceController.text) ?? 0.0,
                images: imageList,
                description: descController.text,
                brand: brandController.text,
              );

              if (isEdit) {
                db.updateShoe(newShoe);
              } else {
                db.addShoe(newShoe);
              }
              Navigator.pop(context);
            },
            child: const Text("Lưu dữ liệu"),
          ),
        ],
      ),
    );
  }

  // ==================== [CẬP NHẬT] DIALOG THÊM / SỬA HÃNG ====================
  void _showBrandDialog(Map<String, dynamic>? brandData) {
    final isEdit = brandData != null;

    // Nếu là Edit thì điền sẵn dữ liệu cũ vào ô
    final nameController = TextEditingController(text: isEdit ? brandData['name'] : "");
    final imgController = TextEditingController(text: isEdit ? brandData['image'] : "");

    // Lưu tên cũ để dùng làm ID khi update
    final String oldName = isEdit ? brandData['name'] : "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Cập Nhật Hãng" : "Thêm Hãng Mới"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _inputField(nameController, "Tên Hãng (Ví dụ: Nike)"),
            _inputField(imgController, "Link Logo (URL)"),
            if (imgController.text.isNotEmpty && isEdit)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text("Lưu ý: Nếu đổi tên hãng, hệ thống sẽ xóa hãng cũ và tạo hãng mới.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              if (isEdit) {
                // Gọi hàm update đã viết trong database.dart
                await db.updateBrand(oldName, nameController.text.trim(), imgController.text.trim());
              } else {
                // Gọi hàm add
                await db.addBrand(nameController.text.trim(), imgController.text.trim());
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? "Cập nhật" : "Thêm mới"),
          )
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa giày?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              db.deleteShoe(id);
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // [MỚI] Dialog xác nhận xóa Hãng
  void _confirmDeleteBrand(String brandId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa Hãng này?"),
        content: const Text("Bạn có chắc chắn muốn xóa thương hiệu này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              db.deleteBrand(brandId);
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}