import 'package:cs261_project/screen/events_and_news/news_event_screen.dart';
import 'package:cs261_project/screen/auth.dart';
import 'package:cs261_project/screen/message/inbox_screen.dart';
import 'package:cs261_project/screen/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cs261_project/screen/profile/profile_screen.dart';
import 'package:cs261_project/screen/main_home_screen.dart';
import 'package:cs261_project/service/algolia_service.dart'; // ✅ Added for testing Algolia

class UserHomeScreen extends StatefulWidget {
  final String instituteId;
  const UserHomeScreen({super.key, required this.instituteId});

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
      MainHomeScreen(instituteId: widget.instituteId),
      SearchScreen(instituteId: widget.instituteId),
      NewsEventScreen(instituteId: widget.instituteId),
      ProfileScreen(instituteId: widget.instituteId),
      InboxScreen(instituteId: widget.instituteId),
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

      // ✅ Added Floating Algolia Test Button
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey<int>(_currentIndex),
              child: pages[_currentIndex],
            ),
          ),

          // 🧪 Floating Test Button for Algolia API
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.green.shade600,
              icon: const Icon(Icons.cloud_outlined, color: Colors.white),
              label: const Text("Test Algolia",
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                print("🧪 Running Algolia API Test...");
                try {
                  final results = await AlgoliaService.search(
                    queryText: "Nitin", // 🔍 change to any name for testing
                    indexName: "profiles_index",
                    instituteId: widget.instituteId,
                  );

                  print("✅ Found ${results.length} results");
                  for (var r in results) {
                    print("→ ${r['name']} (${r['bio']})");
                  }

                  if (results.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No results found for this query."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Found ${results.length} results ✅"),
                        backgroundColor: Colors.green.shade600,
                      ),
                    );
                  }
                } catch (e) {
                  print("❌ Algolia Test Error: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          ),
        ],
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
              _buildNavItem(Icons.question_answer, "Inbox", 4)
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
          color:
              isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? Colors.green.shade600 : Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.green.shade600 : Colors.grey[600],
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
      case 4:
        return 'Inbox';
      default:
        return 'Alumni Connect';
    }
  }

  Widget _buildModernDrawer(BuildContext context, User user) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header with green theme
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade600, Colors.green.shade700],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Icon(Icons.person_rounded,
                            size: 40, color: Colors.green.shade600)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName ?? "Alumni Member",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? "user@email.com",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  Icons.home_rounded,
                  "Home",
                  () {
                    setState(() => _currentIndex = 0);
                    Navigator.pop(context);
                  },
                  isSelected: _currentIndex == 0,
                ),
                _buildDrawerItem(
                  Icons.search_rounded,
                  "Search Alumni",
                  () {
                    setState(() => _currentIndex = 1);
                    Navigator.pop(context);
                  },
                  isSelected: _currentIndex == 1,
                ),
                _buildDrawerItem(
                  Icons.article_rounded,
                  "News & Events",
                  () {
                    setState(() => _currentIndex = 2);
                    Navigator.pop(context);
                  },
                  isSelected: _currentIndex == 2,
                ),
                _buildDrawerItem(
                  Icons.person_rounded,
                  "My Profile",
                  () {
                    setState(() => _currentIndex = 3);
                    Navigator.pop(context);
                  },
                  isSelected: _currentIndex == 3,
                ),
                const Divider(height: 32, indent: 16, endIndent: 16),
                _buildDrawerItem(Icons.settings_rounded, "Settings", () {}),
                _buildDrawerItem(
                    Icons.help_outline_rounded, "Help & Support", () {}),
                _buildDrawerItem(Icons.info_outline_rounded, "About", () {}),
              ],
            ),
          ),

          // Logout Button
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: Colors.red.shade600),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey.shade700,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade800,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.green.shade600, size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }
}
