// File: lib/models/shoe_model.dart
import 'package:intl/intl.dart';

class Shoe {
  final String id;
  final String name;
  final double price; // Giá gốc bằng USD
  final List<String> images;
  final String description;
  final List<num> sizes; // ← MỚI: Danh sách size (ví dụ: [39, 40, 41])

  Shoe({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.description,
    this.sizes = const [], // mặc định rỗng nếu chưa có
  });

  // Giữ tương thích code cũ
  String get image {
    if (images.isNotEmpty) return images[0];
    return "https://via.placeholder.com/300";
  }

  // ==================== HỖ TRỢ VNĐ (CẬP NHẬT 06/01/2026) ====================
  static const double usdToVndRate = 26300.0;

  static final NumberFormat vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  String get priceVND => vndFormat.format(price * usdToVndRate);

  double get priceInVND => price * usdToVndRate;

  String get priceUSD => "\$${price.toStringAsFixed(2)}";
  // ======================================================================

  // ==================== HỖ TRỢ SIZE GIÀY ====================
  bool get hasSizes => sizes.isNotEmpty;

  // Hiển thị danh sách size đẹp (ví dụ: "39, 40, 41")
  String get sizesDisplay =>
      sizes.map((s) => s % 1 == 0 ? s.toInt().toString() : s.toString()).join(', ');

  // Kiểm tra có size cụ thể không (dùng cho tư vấn)
  bool hasSize(num size) => sizes.contains(size);
  // =========================================================

  factory Shoe.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> imgList = [];
    if (data['images'] != null) {
      imgList = List<String>.from(data['images']);
    } else if (data['image'] != null) {
      imgList = [data['image']];
    }

    List<num> sizeList = [];
    if (data['sizes'] != null) {
      sizeList = List<num>.from(data['sizes']);
    }

    return Shoe(
      id: id,
      name: data['name'] ?? 'No Name',
      price: (data['price'] as num).toDouble(),
      images: imgList,
      description: data['description'] ?? '',
      sizes: sizeList,
    );
  }

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "price": price,
    "images": images,
    "description": description,
    "sizes": sizes, // nếu cần lưu local
  };

  factory Shoe.fromMap(Map<String, dynamic> map) => Shoe(
    id: map["id"] ?? "",
    name: map["name"] ?? "No Name",
    price: (map["price"] as num?)?.toDouble() ?? 0.0,
    images: List<String>.from(map["images"] ?? const []),
    description: map["description"] ?? "",
    sizes: map["sizes"] != null ? List<num>.from(map["sizes"]) : [],
  );
}