import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange; // Hàm callback để báo cho màn hình cha biết

  const CustomBottomBar({
    super.key,
    required this.selectedIndex, // Phải truyền vào index hiện tại
    required this.onTabChange,   // Phải truyền vào hàm xử lý
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Truyền index tương ứng cho từng icon (0, 1, 2, 3, 4)
          _buildNavItem(Icons.home_filled, 0),
          _buildNavItem(Icons.favorite_border, 1),
          _buildNavItem(Icons.search, 2),
          _buildNavItem(Icons.shopping_cart_outlined, 3),
          _buildNavItem(Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabChange(index), // Khi bấm thì gọi hàm và gửi index ra ngoài
      child: Container(
        color: Colors.transparent, // Để vùng bấm rộng hơn, dễ bấm
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
              size: 28,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 5,
                width: 5,
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
              )
          ],
        ),
      ),
    );
  }
}