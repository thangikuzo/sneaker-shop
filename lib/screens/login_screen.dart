import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // [MỚI] Import để lưu data user
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true; // Trạng thái đang là Login hay Register
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Biến lưu lỗi hiển thị lên UI
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  bool isLoading = false;

  // 1. Hàm kiểm tra dữ liệu đầu vào (Validation)
  bool _validateInput() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;

      // Validate Email
      if (_emailController.text.trim().isEmpty) {
        _emailError = "Vui lòng nhập Email";
        isValid = false;
      } else if (!_emailController.text.contains("@")) {
        _emailError = "Email không hợp lệ";
        isValid = false;
      }

      // Validate Password
      if (_passwordController.text.trim().isEmpty) {
        _passwordError = "Vui lòng nhập Mật khẩu";
        isValid = false;
      } else if (_passwordController.text.length < 6) {
        _passwordError = "Mật khẩu phải trên 6 ký tự";
        isValid = false;
      }
    });
    return isValid;
  }

  // 2. Hàm xử lý Submit
  Future<void> _submit() async {
    // Nếu validate sai thì dừng ngay
    if (!_validateInput()) return;

    setState(() { isLoading = true; });

    try {
      if (isLogin) {
        // --- LOGIC ĐĂNG NHẬP ---
        await AuthService().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Đăng nhập thành công -> Stream trong main.dart sẽ tự chuyển màn hình
      } else {
        // --- LOGIC ĐĂNG KÝ ---
        await AuthService().signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // [QUAN TRỌNG] Tạo User Document trên Firestore ngay khi đăng ký
        // Để sau này vào Profile hoặc check quyền Admin không bị lỗi
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': _emailController.text.trim(),
            'role': 'user', // Mặc định là user thường
            'createdAt': Timestamp.now(),
            'fullName': '', // Để trống để update sau bên Profile
            'phone': '',
            'address': '',
            'avatar': '',
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        print("Firebase Auth Error: ${e.code}"); // Log để debug

        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _generalError = "Sai Email hoặc Mật khẩu.";
        } else if (e.code == 'email-already-in-use') {
          _generalError = "Email này đã được đăng ký.";
        } else if (e.code == 'invalid-email') {
          _generalError = "Định dạng Email không hợp lệ.";
        } else if (e.code == 'weak-password') {
          _generalError = "Mật khẩu quá yếu.";
        } else {
          _generalError = "Lỗi đăng nhập: ${e.message}";
        }
      });
    } catch (e) {
      setState(() { _generalError = "Đã xảy ra lỗi không xác định. Vui lòng thử lại."; });
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center( // Center để căn giữa theo chiều dọc nếu màn hình lớn
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.black),
                const SizedBox(height: 20),
                Text(
                  isLogin ? "Welcome Back!" : "Create Account",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // --- Ô EMAIL ---
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress, // Bàn phím email
                  decoration: InputDecoration(
                    labelText: "Email",
                    errorText: _emailError, // Hiển thị lỗi nếu có
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 15),

                // --- Ô PASSWORD ---
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    errorText: _passwordError, // Hiển thị lỗi nếu có
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),

                // --- HIỂN THỊ LỖI CHUNG (TỪ FIREBASE) ---
                if (_generalError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _generalError!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 25),

                // --- NÚT SUBMIT ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: isLoading
                        ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                        : Text(
                      isLogin ? "LOG IN" : "SIGN UP",
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- CHUYỂN ĐỔI LOGIN / SIGNUP ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isLogin ? "New member? " : "Have an account? "),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLogin = !isLogin;
                          // Reset form khi chuyển tab
                          _emailError = null;
                          _passwordError = null;
                          _generalError = null;
                          _emailController.clear();
                          _passwordController.clear();
                        });
                      },
                      child: Text(
                        isLogin ? "Register now" : "Log in",
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}