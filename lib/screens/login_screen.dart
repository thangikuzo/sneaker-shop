import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 1. Thêm các biến để lưu lỗi riêng cho từng ô
  String? _emailError;
  String? _passwordError;
  String? _generalError; // Lỗi chung (ví dụ: sai mật khẩu)

  bool isLoading = false;

  // 2. Hàm kiểm tra dữ liệu đầu vào
  bool _validateInput() {
    bool isValid = true;
    setState(() {
      // Reset lỗi trước khi kiểm tra
      _emailError = null;
      _passwordError = null;
      _generalError = null;

      // Kiểm tra Email
      if (_emailController.text.trim().isEmpty) {
        _emailError = "Vui lòng nhập Email"; // Hiện dòng đỏ
        isValid = false;
      } else if (!_emailController.text.contains("@")) {
        _emailError = "Email không hợp lệ";
        isValid = false;
      }

      // Kiểm tra Password
      if (_passwordController.text.trim().isEmpty) {
        _passwordError = "Vui lòng nhập Mật khẩu"; // Hiện dòng đỏ
        isValid = false;
      } else if (_passwordController.text.length < 6) {
        _passwordError = "Mật khẩu phải trên 6 ký tự";
        isValid = false;
      }
    });
    return isValid;
  }

  Future<void> _submit() async {
    // Gọi hàm kiểm tra, nếu có lỗi thì dừng lại luôn, không gửi lên Firebase
    if (!_validateInput()) {
      return;
    }

    setState(() { isLoading = true; });

    try {
      if (isLogin) {
        await AuthService().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await AuthService().signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        // In ra mã lỗi để bạn dễ debug
        print("Firebase Error Code: ${e.code}");

        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          // Gộp chung lỗi để hacker không dò được thông tin
          _generalError = "Sai Email hoặc Mật khẩu.";
        } else if (e.code == 'email-already-in-use') {
          _generalError = "Email này đã được đăng ký.";
        } else if (e.code == 'invalid-email') {
          _generalError = "Định dạng Email không hợp lệ.";
        } else {
          _generalError = "Lỗi: ${e.message}"; // Các lỗi khác
        }
      });
    } catch (e) {
      setState(() { _generalError = "Đã xảy ra lỗi không xác định."; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( // Thêm cái này để không bị che phím
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
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
                decoration: InputDecoration(
                  labelText: "Email",
                  // Hiển thị lỗi đỏ ở đây
                  errorText: _emailError,
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
                  // Hiển thị lỗi
                  errorText: _passwordError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),

              // Hiển thị lỗi chung (nếu có)
              if (_generalError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    _generalError!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    isLogin ? "LOG IN" : "SIGN UP",
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLogin ? "New member? " : "Have an account? "),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isLogin = !isLogin;
                        // Xóa sạch lỗi khi chuyển đổi màn hình
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
    );
  }
}