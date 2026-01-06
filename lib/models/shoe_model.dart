import 'package:intl/intl.dart';
class Shoe {
  final String id;
  final String name;
  final double price; // Giá gốc bằng USD (lưu trong Firestore)
  final List<String> images;
  final String description;

  Shoe({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.description,
  });

  // Giữ tương thích code cũ
  String get image {
    if (images.isNotEmpty) return images[0];
    return "https://via.placeholder.com/300";
  }

  // ==================== HỖ TRỢ VNĐ (CẬP NHẬT 06/01/2026) ====================
  // Tỷ giá thực tế hôm nay ~26,300 - 26,330 → dùng 26,300 cho đẹp & ổn định
  static const double usdToVndRate = 26300.0;

  // Formatter tiền Việt Nam đẹp (2.893.000 ₫)
  static final NumberFormat vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0, // Không hiển thị phần thập phân
  );

  // Giá đã format sẵn để hiển thị trực tiếp
  String get priceVND => vndFormat.format(price * usdToVndRate);

  // Nếu cần số VND để tính toán (subtotal, total...)
  double get priceInVND => price * usdToVndRate;

  // Giữ lại USD nếu cần chuyển lại sau này
  String get priceUSD => "\$${price.toStringAsFixed(2)}";
  // ======================================================================

  factory Shoe.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> imgList = [];

    if (data['images'] != null) {
      imgList = List<String>.from(data['images']);
    } else if (data['image'] != null) {
      imgList = [data['image']];
    }

    return Shoe(
      id: id,
      name: data['name'] ?? 'No Name',
      price: (data['price'] as num).toDouble(),
      images: imgList,
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "price": price,
    "images": images,
    "description": description,
  };

  factory Shoe.fromMap(Map<String, dynamic> map) => Shoe(
    id: map["id"] ?? "",
    name: map["name"] ?? "No Name",
    price: (map["price"] as num?)?.toDouble() ?? 0.0,
    images: List<String>.from(map["images"] ?? const []),
    description: map["description"] ?? "",
  );
}