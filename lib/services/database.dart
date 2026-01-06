import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shoe_model.dart';

class DatabaseService {
  // Khai báo các Collection trên Firebase
  final CollectionReference sneakerCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference favoritesCollection = FirebaseFirestore.instance.collection('favorites');
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference brandCollection = FirebaseFirestore.instance.collection('brands');

  // Lấy User ID hiện tại
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // ==================== 1. QUẢN LÝ SẢN PHẨM (ADMIN) ====================

  Future<void> addShoe(Shoe shoe) async {
    DocumentReference docRef = sneakerCollection.doc();
    await docRef.set({
      'id': docRef.id,
      'name': shoe.name,
      'price': shoe.price,
      'images': shoe.images,
      'description': shoe.description,
      'brand': shoe.brand,
    });
  }

  Future<void> updateShoe(Shoe shoe) async {
    await sneakerCollection.doc(shoe.id).update({
      'name': shoe.name,
      'price': shoe.price,
      'images': shoe.images,
      'description': shoe.description,
      'brand': shoe.brand,
    });
  }

  Future<void> deleteShoe(String id) async {
    await sneakerCollection.doc(id).delete();
  }

  // ==================== 2. QUẢN LÝ HÃNG (ADMIN) - KHẮC PHỤC LỖI CỦA BẠN ====================

  // [MỚI] Hàm lấy danh sách hãng (Sửa lỗi getter 'brands')
  Stream<List<Map<String, dynamic>>> get brands {
    return brandCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  // [MỚI] Hàm thêm hãng mới (Sửa lỗi method 'addBrand')
  Future<void> addBrand(String name, String imageUrl) async {
    // Dùng tên hãng làm ID luôn để tránh trùng lặp
    await brandCollection.doc(name).set({
      'name': name,
      'image': imageUrl,
    });
  }
  Future<void> deleteBrand(String id) async {
    await brandCollection.doc(id).delete();
  }

  // Cập nhật hãng (Xử lý trường hợp đổi tên hãng -> Đổi luôn ID)
  Future<void> updateBrand(String oldName, String newName, String newImage) async {
    // Trường hợp 1: Tên không đổi, chỉ đổi ảnh
    if (oldName == newName) {
      await brandCollection.doc(oldName).update({
        'image': newImage,
      });
    }
    // Trường hợp 2: Đổi tên (tức là đổi ID)
    else {
      // 1. Tạo document mới với tên mới
      await brandCollection.doc(newName).set({
        'name': newName,
        'image': newImage,
      });
      // 2. Xóa document cũ
      await brandCollection.doc(oldName).delete();
    }
  }

  // ==================== 3. QUẢN LÝ NGƯỜI DÙNG & PHÂN QUYỀN ====================

  Future<String> getUserRole() async {
    if (userId == null) return 'user';
    try {
      DocumentSnapshot doc = await userCollection.doc(userId).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'] ?? 'user';
      }
    } catch (e) {
      print("Lỗi lấy role: $e");
    }
    return 'user';
  }

  Stream<List<Map<String, dynamic>>> get allUsers {
    return userCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList());
  }

  // ==================== 4. CÁC HÀM CHO USER (HOME/DETAIL) ====================

  Future<void> toggleFavorite(String shoeId) async {
    if (userId == null) return;
    final docRef = favoritesCollection.doc(userId).collection('items').doc(shoeId);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({'added_at': Timestamp.now()});
    }
  }

  Stream<List<String>> get myFavorites {
    if (userId == null) return Stream.value([]);
    return favoritesCollection
        .doc(userId)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<Shoe>> get sneakers {
    return sneakerCollection.snapshots().map(_sneakerListFromSnapshot);
  }

  List<Shoe> _sneakerListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return Shoe.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
}