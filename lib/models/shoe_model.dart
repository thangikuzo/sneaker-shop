// File: shoe_model.dart
class Shoe {
  final String id;
  final String name;
  final double price;

  // 1. Thay vì lưu 1 ảnh, ta lưu danh sách ảnh
  final List<String> images;

  final String description;

  Shoe({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.description,
  });

  // 2. THỦ THUẬT: Tạo getter "image" để code cũ ở Home/Wishlist không bị lỗi
  // Khi Home gọi shoe.image, nó sẽ tự động lấy ảnh đầu tiên trong mảng images
  String get image {
    if (images.isNotEmpty) {
      return images[0]; // Trả về ảnh đầu tiên làm ảnh đại diện
    }
    return "https://via.placeholder.com/300"; // Ảnh rỗng nếu không có dữ liệu
  }

  factory Shoe.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> imgList = [];

    // Ưu tiên lấy mảng 'images' nếu có
    if (data['images'] != null) {
      imgList = List<String>.from(data['images']);
    }
    // Nếu không có mảng, kiểm tra xem có ảnh đơn 'image' cũ không
    else if (data['image'] != null) {
      imgList = [data['image']];
    }
    // Nếu không có gì cả
    else {
      imgList = [];
    }

    return Shoe(
      id: id,
      name: data['name'] ?? 'No Name',
      price: (data['price'] as num).toDouble(),
      images: imgList, // Lưu vào list
      description: data['description'] ?? '',
    );
  }
}