import 'package:cs261_project/events_and_news/news_event_screen.dart';
import 'package:cs261_project/screen/auth.dart';
import 'package:cs261_project/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cs261_project/profile/profile_screen.dart';
import 'package:cs261_project/screen/main_home_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not found.")),
      );
    }

    final pages = [
      const MainHomeScreen(),
      const SearchScreen(),
      NewsEventScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildModernDrawer(context, user),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, "Home", 0),
              _buildNavItem(Icons.search_rounded, "Search", 1),
              _buildNavItem(Icons.article_rounded, "News", 2),
              _buildNavItem(Icons.person_rounded, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.blue[600] : Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue[600] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Alumni Connect';
      case 1:
        return 'Search Alumni';
      case 2:
        return 'News & Events';
      case 3:
        return 'My Profile';
      default:
        return 'Alumni Connect';
    }
  }

  Widget _buildModernDrawer(BuildContext context, User user) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[600]!, Colors.blue[700]!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Icon(Icons.person_rounded,
                          size: 32, color: Colors.grey[600])
                      : null,
                ),
                const SizedBox(height: 16),
                Text(user.displayName ?? "Alumni Member",
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 4),
                Text(user.email ?? "user@email.com",
                    style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildDrawerItem(Icons.home_rounded, "Home", () {
                  setState(() => _currentIndex = 0);
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.search_rounded, "Search Alumni", () {
                  setState(() => _currentIndex = 1);
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.article_rounded, "News & Events", () {
                  setState(() => _currentIndex = 2);
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.person_rounded, "My Profile", () {
                  setState(() => _currentIndex = 3);
                  Navigator.pop(context);
                }),
                const Divider(height: 32),
                _buildDrawerItem(Icons.settings_rounded, "Settings", () {}),
                _buildDrawerItem(
                    Icons.help_outline_rounded, "Help & Support", () {}),
                _buildDrawerItem(Icons.info_outline_rounded, "About", () {}),
              ],
            ),
          ),
          _buildDrawerItem(Icons.logout_rounded, "Logout", () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          }, textColor: Colors.red[600], iconColor: Colors.red[600]),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {Color? textColor, Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey[700]),
      title: Text(title,
          style: TextStyle(color: textColor ?? Colors.grey[800], fontSize: 15)),
      onTap: onTap,
    );
  }
}
