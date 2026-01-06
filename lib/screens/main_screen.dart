// File: main_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favorite_screen.dart';
import 'profile_screen.dart';
import 'widgets/bottom_bar.dart'; // Đảm bảo đường dẫn import đúng thư mục widget của bạn
import 'widgets/main_drawer.dart'; // Đảm bảo đường dẫn import đúng
import 'chat_screen.dart';
import 'cart_screen.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onTabChange(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(openDrawer: () => _scaffoldKey.currentState?.openDrawer()), // Tab 0


      FavoriteScreen(onBackToHome: () => _onTabChange(0)),                   // Tab 1

      const ChatBotScreen(),                                   // Tab 2
      const CartScreen(),                        // Tab 3
      ProfileScreen(onBackToHome: () => _onTabChange(0)),                    // Tab 4
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      extendBody: true,
      drawer: MainDrawer(
        onTabSelect: (index) {
          _onTabChange(index);
        },
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: _currentIndex,
        onTabChange: _onTabChange,
      ),
    );
  }
}