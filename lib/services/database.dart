// File: database.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shoe_model.dart';

class DatabaseService {
  final CollectionReference sneakerCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference favoritesCollection = FirebaseFirestore.instance.collection('favorites');

  // Lấy User ID hiện tại
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // 1. Hàm Thả tim / Bỏ tim
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

  // 2. Stream lắng nghe danh sách tim
  Stream<List<String>> get myFavorites {
    if (userId == null) return Stream.value([]);

    return favoritesCollection
        .doc(userId)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // 3. Stream lấy danh sách giày
  Stream<List<Shoe>> get sneakers {
    return sneakerCollection.snapshots().map(_sneakerListFromSnapshot);
  }

  // --- SỬA LỖI Ở ĐÂY ---
  List<Shoe> _sneakerListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      // Thay vì viết thủ công Shoe(id: ..., name: ...), ta dùng hàm fromFirestore cho gọn
      // Hàm này sẽ tự xử lý vụ image vs images luôn
      return Shoe.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
}