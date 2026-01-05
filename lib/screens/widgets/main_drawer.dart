// File: main_drawer.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';

class MainDrawer extends StatelessWidget {
  final Function(int)? onTabSelect;

  const MainDrawer({super.key, this.onTabSelect});

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

              // Menu Items
              _buildMenuItem("Home", Icons.home_filled, () {
                Navigator.pop(context);
                if (onTabSelect != null) onTabSelect!(0);
              }),

              _buildMenuItem("My Wishlist", Icons.favorite_border, () {
                Navigator.pop(context);
                if (onTabSelect != null) onTabSelect!(1);
              }),

              _buildMenuItem("My Cart", Icons.shopping_bag_outlined, () {
                Navigator.pop(context);
                if (onTabSelect != null) onTabSelect!(3);
              }),

              _buildMenuItem("Profile", Icons.person_outline, () {
                Navigator.pop(context);
                if (onTabSelect != null) onTabSelect!(4);
              }),

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

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap, {bool isLogout = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 35),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: isLogout ? Colors.redAccent : Colors.white, size: 26),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                color: isLogout ? Colors.redAccent : Colors.white,
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