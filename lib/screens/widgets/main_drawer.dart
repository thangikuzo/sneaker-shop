// File: main_drawer.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/database.dart'; // Import DatabaseService
import '../adminscreen.dart';


class MainDrawer extends StatefulWidget {
  final Function(int)? onTabSelect;

  const MainDrawer({super.key, this.onTabSelect});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  String userRole = 'user'; // Mặc định là user thường

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // Hàm kiểm tra quyền từ Firebase
  void _checkUserRole() async {
    String role = await DatabaseService().getUserRole();
    if (mounted) {
      setState(() {
        userRole = role;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(
                child: CachedNetworkImage(
                  imageUrl: "https://res.cloudinary.com/dyhexxo9t/image/upload/v1767627745/logo_nike_white_dnir6c.png",
                  width: 160,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                ),
              ),
              const SizedBox(height: 60),

              // --- Menu Items ---

              _buildMenuItem("Home", Icons.home_filled, () {
                Navigator.pop(context);
                if (widget.onTabSelect != null) widget.onTabSelect!(0);
              }),

              _buildMenuItem("My Wishlist", Icons.favorite_border, () {
                Navigator.pop(context);
                if (widget.onTabSelect != null) widget.onTabSelect!(1);
              }),

              _buildMenuItem("My Cart", Icons.shopping_bag_outlined, () {
                Navigator.pop(context);
                if (widget.onTabSelect != null) widget.onTabSelect!(3);
              }),

              _buildMenuItem("Profile", Icons.person_outline, () {
                Navigator.pop(context);
                if (widget.onTabSelect != null) widget.onTabSelect!(4);
              }),

              // --- [NEW] MỤC ADMIN (Chỉ hiện nếu role là admin) ---
              if (userRole == 'admin')
                _buildMenuItem(
                  "Admin Dashboard",
                  Icons.admin_panel_settings,
                      () {
                    Navigator.pop(context); // Đóng drawer
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminScreen())
                    );
                  },
                  customColor: Colors.amber, // Màu vàng nổi bật cho Admin
                ),
              // ----------------------------------------------------

              _buildMenuItem("Settings", Icons.settings_outlined, () {}),

              const Spacer(),

              _buildMenuItem("Logout", Icons.logout, () async {
                Navigator.pop(context);
                await AuthService().signOut();
              }, isLogout: true),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Đã cập nhật để hỗ trợ customColor
  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap, {bool isLogout = false, Color? customColor}) {
    // Xác định màu sắc: Nếu có customColor thì dùng, nếu là Logout thì đỏ, còn lại là trắng
    Color itemColor = customColor ?? (isLogout ? Colors.redAccent : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 35),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: 26),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                color: itemColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}