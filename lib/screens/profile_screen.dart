// File: lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'order_history_screen.dart';

class ProfileScreen extends StatefulWidget {
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
  String _role = "user";

  bool _isLoading = false;
  bool _isEditing = false;

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);

    _email = currentUser!.email ?? "";

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = data['fullName'] ?? "";
          _phoneController.text = data['phone'] ?? "";
          _addressController.text = data['address'] ?? "";
          _dobController.text = data['dob'] ?? "";
          _role = data['role'] ?? "user";

          if (data['avatar'] != null && data['avatar'].isNotEmpty) {
            _avatarUrl = data['avatar'];
          }
        });
      }
    } catch (e) {
      print("Lỗi tải profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'dob': _dobController.text.trim(),
        'avatar': _avatarUrl,
      }, SetOptions(merge: true));

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dobController.text = "${picked.day}/${picked.month}/${picked.year}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bool isAdmin = _role == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Tài khoản", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (widget.onBackToHome != null) widget.onBackToHome!();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async => await AuthService().signOut(),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 3),
                      image: DecorationImage(image: NetworkImage(_avatarUrl), fit: BoxFit.cover),
                    ),
                  ),
                  if (isAdmin)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.verified, color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _nameController.text.isEmpty ? "Chưa đặt tên" : _nameController.text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isAdmin ? "Quản trị viên" : "Khách hàng",
              style: TextStyle(color: isAdmin ? Colors.blue[700] : Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isEditing = !_isEditing),
                icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.black),
                label: Text(_isEditing ? "Hủy chỉnh sửa" : "Chỉnh sửa thông tin cá nhân", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isEditing) ...[
              _buildEditableField("Họ và tên", _nameController, Icons.person_outline),
              const SizedBox(height: 15),
              _buildEditableField("Số điện thoại", _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: _buildEditableField("Ngày sinh", _dobController, Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 15),
              _buildEditableField("Địa chỉ giao hàng", _addressController, Icons.location_on_outlined),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],

            // === MENU CẬP NHẬT ===
            _buildMenuItem(Icons.receipt_long_outlined, "Lịch sử đơn hàng", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            }),
            _buildMenuItem(Icons.favorite_border, "Sản phẩm yêu thích", () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng đang phát triển")));
            }),
            _buildMenuItem(Icons.card_giftcard, "Săn Voucher", () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng đang phát triển")));
            }),
            _buildMenuItem(Icons.notifications_outlined, "Thông báo", () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng đang phát triển")));
            }),
            _buildMenuItem(Icons.help_outline, "Hỗ trợ khách hàng", () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng đang phát triển")));
            }),
            _buildMenuItem(Icons.settings_outlined, "Cài đặt", () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng đang phát triển")));
            }),

            SizedBox(height: 50 + bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black54),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      leading: Icon(icon, color: Colors.black87, size: 26),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}