// File: lib/services/database.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shoe_model.dart';

class DatabaseService {
  final CollectionReference sneakerCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference favoritesCollection = FirebaseFirestore.instance.collection('favorites');
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference brandCollection = FirebaseFirestore.instance.collection('brands');

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // ==================== 1. QUẢN LÝ SẢN PHẨM (ADMIN) ====================

  Future<void> addShoe(Shoe shoe) async {
    DocumentReference docRef = sneakerCollection.doc();
    await docRef.set(shoe.toMap()..['id'] = docRef.id);
  }

  Future<void> updateShoe(Shoe shoe) async {
    await sneakerCollection.doc(shoe.id).update(shoe.toMap());
  }

  Future<void> deleteShoe(String id) async {
    await sneakerCollection.doc(id).delete();
  }

  // ==================== 2. QUẢN LÝ HÃNG ====================
  Stream<List<Map<String, dynamic>>> get brands {
    return brandCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  Future<void> addBrand(String name, String imageUrl) async {
    await brandCollection.doc(name).set({
      'name': name,
      'image': imageUrl,
    });
  }

  Future<void> deleteBrand(String id) async {
    await brandCollection.doc(id).delete();
  }

  Future<void> updateBrand(String oldName, String newName, String newImage) async {
    if (oldName == newName) {
      await brandCollection.doc(oldName).update({'image': newImage});
    } else {
      await brandCollection.doc(newName).set({'name': newName, 'image': newImage});
      await brandCollection.doc(oldName).delete();
    }
  }

  // ==================== 3. QUẢN LÝ NGƯỜI DÙNG ====================
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

  // ==================== 4. FAVORITE ====================
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

  // ==================== 5. LẤY DANH SÁCH GIÀY ====================
  Stream<List<Shoe>> get sneakers {
    return sneakerCollection.snapshots().map(_sneakerListFromSnapshot);
  }

  List<Shoe> _sneakerListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Shoe.fromFirestore(data, doc.id);
    }).toList();
  }

  // ==================== 6. GIẢM STOCK KHI ĐẶT HÀNG ====================
  Future<void> decreaseStock(String shoeId, String size, int quantity) async {
    if (quantity <= 0) return;

    final docRef = sneakerCollection.doc(shoeId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception("Sản phẩm không tồn tại!");
      }

      final data = snapshot.data() as Map<String, dynamic>;
      // An toàn: nếu không có field stock → tạo map rỗng
      final currentStockMap = Map<String, dynamic>.from(data['stock'] ?? {});

      final currentQty = (currentStockMap[size] as num?)?.toInt() ?? 0;
      if (currentQty < quantity) {
        throw Exception("Không đủ hàng size $size! (Còn $currentQty)");
      }

      currentStockMap[size] = currentQty - quantity;

      // Xóa size nếu hết hàng (tùy chọn, giúp dọn dẹp dữ liệu)
      if (currentStockMap[size] == 0) {
        currentStockMap.remove(size);
      }

      transaction.update(docRef, {'stock': currentStockMap});
    });
  }
}