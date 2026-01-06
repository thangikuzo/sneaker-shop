// File: lib/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database.dart';
import '../models/shoe_model.dart';
import 'admin_orders_screen.dart'; // ← THÊM DÒNG NÀY

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
    _tabController = TabController(length: 4, vsync: this); // ← TĂNG TỪ 3 → 4 TAB
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          isScrollable: true, // Cho phép cuộn ngang khi nhiều tab
          tabs: const [
            Tab(text: "Sản phẩm", icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: "Hãng", icon: Icon(Icons.category_outlined)),
            Tab(text: "User", icon: Icon(Icons.people_alt_outlined)),
            Tab(text: "Đơn hàng", icon: Icon(Icons.receipt_long_outlined)), // ← TAB MỚI
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductTab(),
          _buildBrandTab(),
          _buildUserTab(),
          const AdminOrdersScreen(), // ← MÀN HÌNH QUẢN LÝ ĐƠN HÀNG
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.amber),
        label: const Text("Thêm Mới", style: TextStyle(color: Colors.white)),
        onPressed: () {
          if (_tabController.index == 0) _showProductDialog(null);
          if (_tabController.index == 1) _showBrandDialog(null);
        },
      ),
    );
  }

  // ==================== TAB SẢN PHẨM ====================
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
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(height: 6),
                    Text("${shoe.brand} • ${shoe.priceVND}",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text("Tổng stock: ${shoe.totalStock}", style: const TextStyle(fontSize: 13)),
                    Text(shoe.stockDisplay, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
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

  // ==================== TAB HÃNG ====================
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
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorWidget: (_,__,___) => const Icon(Icons.broken_image),
                  ),
                ),
                title: Text(brand['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showBrandDialog(brand),
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

  // ==================== TAB USER ====================
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

  // ==================== DIALOG SẢN PHẨM ====================
  void _showProductDialog(Shoe? shoe) {
    final isEdit = shoe != null;

    final nameController = TextEditingController(text: shoe?.name ?? '');
    final priceController = TextEditingController(text: shoe?.price.toString() ?? '');
    final brandController = TextEditingController(text: shoe?.brand ?? 'Nike');
    final descController = TextEditingController(text: shoe?.description ?? '');
    final imagesController = TextEditingController(text: shoe?.images.join(', ') ?? '');

    List<String> sizeList = List.from(shoe?.sizes ?? ['39', '40', '41', '42']);
    Map<String, int> stockMap = Map.from(shoe?.stock ?? {});

    for (var size in sizeList) {
      stockMap[size] ??= 0;
    }

    final ScrollController scrollController = ScrollController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final List<TextEditingController> sizeControllers = sizeList.map((s) => TextEditingController(text: s)).toList();
          final List<TextEditingController> stockControllers = sizeList.map((s) => TextEditingController(text: stockMap[s].toString())).toList();

          return AlertDialog(
            title: Text(isEdit ? "Cập nhật sản phẩm" : "Thêm sản phẩm mới",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.75,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _inputField(nameController, "Tên giày"),
                    Row(
                      children: [
                        Expanded(child: _inputField(priceController, "Giá (USD)", isNumber: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _inputField(brandController, "Hãng")),
                      ],
                    ),
                    _inputField(imagesController, "Link ảnh (cách nhau bằng dấu phẩy)", maxLines: 3),
                    _inputField(descController, "Mô tả sản phẩm", maxLines: 4),

                    const SizedBox(height: 20),
                    const Divider(thickness: 1.5),
                    const Text("Quản lý Size & Tồn kho",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),

                    ...List.generate(sizeList.length, (idx) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: sizeControllers[idx],
                                decoration: InputDecoration(
                                  labelText: "Size",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onChanged: (newSize) {
                                  newSize = newSize.trim();
                                  if (newSize.isNotEmpty) {
                                    String oldSize = sizeList[idx];
                                    sizeList[idx] = newSize;
                                    if (oldSize != newSize) {
                                      stockMap[newSize] = stockMap[oldSize] ?? 0;
                                      stockMap.remove(oldSize);
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: stockControllers[idx],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Số lượng tồn",
                                  hintText: "0",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onChanged: (value) {
                                  stockMap[sizeList[idx]] = int.tryParse(value) ?? 0;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 30),
                              onPressed: () {
                                setStateDialog(() {
                                  stockMap.remove(sizeList[idx]);
                                  sizeList.removeAt(idx);
                                  sizeControllers.removeAt(idx);
                                  stockControllers.removeAt(idx);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                        label: const Text("Thêm size mới", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          side: const BorderSide(color: Colors.black54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            sizeList.add('43');
                            stockMap['43'] = 0;
                            sizeControllers.add(TextEditingController(text: '43'));
                            stockControllers.add(TextEditingController(text: '0'));
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            scrollController.animateTo(
                              scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  List<String> imageList = imagesController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  sizeList = sizeList.where((s) => s.trim().isNotEmpty).toList();

                  final newShoe = Shoe(
                    id: isEdit ? shoe!.id : "",
                    name: nameController.text.trim(),
                    price: double.tryParse(priceController.text) ?? 0.0,
                    images: imageList,
                    description: descController.text.trim(),
                    brand: brandController.text.trim(),
                    sizes: sizeList,
                    stock: stockMap,
                  );

                  if (isEdit) {
                    db.updateShoe(newShoe);
                  } else {
                    db.addShoe(newShoe);
                  }

                  Navigator.pop(context);
                },
                child: Text(isEdit ? "Cập nhật" : "Thêm sản phẩm",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== DIALOG HÃNG ====================
  void _showBrandDialog(Map<String, dynamic>? brandData) {
    final isEdit = brandData != null;
    final nameController = TextEditingController(text: isEdit ? brandData['name'] : "");
    final imgController = TextEditingController(text: isEdit ? brandData['image'] : "");
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              if (isEdit) {
                await db.updateBrand(oldName, nameController.text.trim(), imgController.text.trim());
              } else {
                await db.addBrand(nameController.text.trim(), imgController.text.trim());
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? "Cập nhật" : "Thêm mới", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== XÓA SẢN PHẨM & HÃNG ====================
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

  // ==================== INPUT FIELD ====================
  Widget _inputField(TextEditingController controller, String label, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}