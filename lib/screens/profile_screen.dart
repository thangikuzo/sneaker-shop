import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  // Biến nhận lệnh "Quay về Home" từ MainScreen truyền vào
  final VoidCallback? onBackToHome;

  const ProfileScreen({super.key, this.onBackToHome});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();

  String _email = "";
  String _avatarUrl = "https://i.pravatar.cc/300";
  bool _isLoading = false;

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Tải dữ liệu từ Firebase
  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    _email = currentUser!.email ?? "";
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _nameController.text = data['fullName'] ?? "";
        _phoneController.text = data['phone'] ?? "";
        _addressController.text = data['address'] ?? "";
        _dobController.text = data['dob'] ?? "";
        if (data['avatar'] != null && data['avatar'].isNotEmpty) {
          _avatarUrl = data['avatar'];
        }
      }
    } catch (e) {
      print("Lỗi tải profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Lưu dữ liệu lên Firebase
  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'dob': _dobController.text.trim(),
        'email': _email,
        'avatar': _avatarUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dobController.text = "${picked.day}/${picked.month}/${picked.year}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy chiều cao phần an toàn dưới đáy màn hình
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // --- NÚT BACK ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // Nếu có hàm quay về Home thì gọi hàm đó
            if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await AuthService().signOut();
              // main.dart sẽ tự động chuyển về LoginScreen
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 4),
                      image: DecorationImage(image: NetworkImage(_avatarUrl), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Form nhập liệu
            _buildTextField("Họ và Tên", "Nhập tên của bạn", _nameController, Icons.person_outline),
            const SizedBox(height: 15),
            _buildTextField("Gmail", "", null, Icons.email_outlined, readOnly: true, initialValue: _email),
            const SizedBox(height: 15),
            _buildTextField("Số điện thoại", "Nhập SĐT", _phoneController, Icons.phone_outlined, inputType: TextInputType.phone),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: _buildTextField("Ngày sinh", "Chọn ngày sinh", _dobController, Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 15),
            _buildTextField("Địa chỉ", "Nhập địa chỉ giao hàng", _addressController, Icons.location_on_outlined),

            const SizedBox(height: 40),

            // Nút Lưu
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("CẬP NHẬT THÔNG TIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            // --- KHOẢNG TRỐNG CHỐNG CHE NỘI DUNG ---
            SizedBox(height: 100 + bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController? controller, IconData icon,
      {bool readOnly = false, String? initialValue, TextInputType inputType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.black54),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
          ),
        ),
      ],
    );
  }
}