// File: lib/models/shoe_model.dart
import 'package:intl/intl.dart';

class Shoe {
  final String id;
  final String name;
  final double price; // Giá gốc bằng USD (lưu trong Firestore)
  final List<String> images;
  final String description;
  final String brand;

  // THÊM MỚI: Danh sách size có sẵn (ví dụ: ["39", "40", "41"])
  // Dùng String để dễ đồng bộ với key trong stock map
  final List<String> sizes;

  // THÊM MỚI: Số lượng tồn kho theo từng size
  // Ví dụ: {"39": 5, "40": 5, "41": 7, "42": 5}
  final Map<String, int> stock;

  Shoe({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.description,
    required this.brand,
    this.sizes = const [],
    this.stock = const {}, // Mặc định rỗng
  });

  // Giữ tương thích code cũ (lấy ảnh đầu tiên)
  String get image {
    if (images.isNotEmpty) return images[0];
    return "https://via.placeholder.com/300";
  }

  // ==================== HỖ TRỢ VNĐ ====================
  static const double usdToVndRate = 26300.0;

  static final NumberFormat vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  String get priceVND => vndFormat.format(price * usdToVndRate);

  double get priceInVND => price * usdToVndRate;

  String get priceUSD => "\$${price.toStringAsFixed(2)}";
  // ================================================

  // ==================== HỖ TRỢ SIZE & STOCK ====================
  bool get hasSizes => sizes.isNotEmpty;

  // Hiển thị danh sách size: 39, 40, 41
  String get sizesDisplay => sizes.join(', ');

  // Kiểm tra có size này không
  bool hasSize(String size) => sizes.contains(size);

  // Tổng số lượng tồn kho của sản phẩm
  int get totalStock => stock.values.fold(0, (sum, qty) => sum + qty);

  // Lấy số lượng tồn của một size cụ thể (nếu không có trả về 0)
  int stockOfSize(String size) => stock[size] ?? 0;

  // Kiểm tra sản phẩm còn hàng không
  bool get inStock => totalStock > 0;

  // Danh sách size còn hàng (có stock > 0)
  List<String> get availableSizes =>
      sizes.where((size) => stockOfSize(size) > 0).toList();

  // Hiển thị thông tin stock ngắn gọn (dùng trong UI admin)
  String get stockDisplay {
    if (stock.isEmpty) return "Chưa có stock";
    return stock.entries.map((e) => "${e.key}: ${e.value}").join(', ');
  }
  // ============================================================

  // ==================== FROM FIRESTORE ====================
  factory Shoe.fromFirestore(Map<String, dynamic> data, String id) {
    // Xử lý images (tương thích cũ và mới)
    List<String> imgList = [];
    if (data['images'] != null) {
      imgList = List<String>.from(data['images']);
    } else if (data['image'] != null) {
      imgList = [data['image']];
    }

    // Xử lý sizes (ưu tiên mảng string, fallback về num nếu có)
    List<String> sizeList = [];
    if (data['sizes'] != null) {
      sizeList = List<String>.from(data['sizes'].map((s) => s.toString()));
    }

    // Xử lý stock (Map<String, int>)
    Map<String, int> stockMap = {};
    if (data['stock'] != null) {
      stockMap = Map<String, int>.from(
        data['stock'].map((key, value) => MapEntry(key.toString(), value as int)),
      );
    }

    return Shoe(
      id: id,
      name: data['name'] ?? 'No Name',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      images: imgList,
      description: data['description'] ?? '',
      brand: data['brand'] ?? 'Unknown',
      sizes: sizeList,
      stock: stockMap,
    );
  }

  // ==================== TO MAP (lưu Firestore) ====================
  Map<String, dynamic> toMap() => {
    "name": name,
    "price": price,
    "images": images,
    "description": description,
    "brand": brand,
    "sizes": sizes,
    "stock": stock,
  };

  // ==================== FROM MAP (nếu dùng local) ====================
  factory Shoe.fromMap(Map<String, dynamic> map) => Shoe(
    id: map["id"] ?? "",
    name: map["name"] ?? "No Name",
    price: (map["price"] as num?)?.toDouble() ?? 0.0,
    images: List<String>.from(map["images"] ?? const []),
    description: map["description"] ?? "",
    brand: map["brand"] ?? "Unknown",
    sizes: map["sizes"] != null
        ? List<String>.from(map["sizes"].map((s) => s.toString()))
        : const [],
    stock: map["stock"] != null
        ? Map<String, int>.from(
      map["stock"].map((key, value) => MapEntry(key.toString(), value as int)),
    )
        : const {},
  );
}