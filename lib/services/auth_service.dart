import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy user hiện tại (để biết ai đang online)
  User? get currentUser => _auth.currentUser;

  // Lắng nghe trạng thái: Đăng nhập hay chưa?
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng nhập
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Đăng ký
  Future<void> signUp({required String email, required String password}) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}