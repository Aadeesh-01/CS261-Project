import 'package:cs261_project/screen/main_home_screen.dart';
import 'package:cs261_project/student/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'news_event_service.dart';
import 'news_event_model.dart';

class NewsEventScreen extends StatefulWidget {
  const NewsEventScreen({super.key});

  @override
  State<NewsEventScreen> createState() => _NewsEventScreenState();
}

class _NewsEventScreenState extends State<NewsEventScreen>
    with TickerProviderStateMixin {
  final NewsEventService service = NewsEventService();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  String type = "news";
  bool _showAddPost = false;

  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabRotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fabRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  void _toggleAddPost() {
    setState(() {
      _showAddPost = !_showAddPost;
      if (_showAddPost) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
        titleController.clear();
        descController.clear();
        type = "news";
      }
    });
  }

  void _addPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (titleController.text.trim().isEmpty ||
        descController.text.trim().isEmpty) {
      _showSnackBar('Please fill in all fields', Colors.orange);
      return;
    }

    final post = NewsEventPost(
      id: '', // Firestore will generate this
      title: titleController.text.trim(),
      description: descController.text.trim(),
      type: type,
      createdBy: user.uid,
      createdByName: user.displayName ?? "Distinguished Alumni",
      createdAt: DateTime.now(),
      imageUrl: '',
      likes: [],
      comments: [],
    );

    try {
      await service.addPost(post);
      _showSnackBar('Post published successfully', const Color(0xFFD4AF37));
      _toggleAddPost();
    } catch (e) {
      _showSnackBar('Failed to publish post', Colors.red);
    }
  }

  void _editPost(NewsEventPost post) {
    titleController.text = post.title;
    descController.text = post.description;
    type = post.type;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFFD4AF37),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Edit Post",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(titleController, "Title", Icons.title_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                  descController, "Description", Icons.description_outlined,
                  maxLines: 4),
              const SizedBox(height: 16),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      titleController.clear();
                      descController.clear();
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty ||
                          descController.text.trim().isEmpty) {
                        _showSnackBar(
                            'Please fill in all fields', Colors.orange);
                        return;
                      }

                      try {
                        await service.updatePost(post.id, {
                          "title": titleController.text.trim(),
                          "description": descController.text.trim(),
                          "type": type,
                        });
                        Navigator.pop(context);
                        titleController.clear();
                        descController.clear();
                        _showSnackBar('Post updated successfully',
                            const Color(0xFFD4AF37));
                      } catch (e) {
                        _showSnackBar('Failed to update post', Colors.red);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Save Changes"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deletePost(NewsEventPost post) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_outlined,
                  color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Delete Post",
              style: TextStyle(color: Color(0xFF2C3E50), fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${post.title}'? This action cannot be undone.",
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await service.deletePost(post.id);
                Navigator.pop(context);
                _showSnackBar('Post deleted successfully', Colors.red);
              } catch (e) {
                _showSnackBar('Failed to delete post', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = [
      {
        'value': 'news',
        'label': 'News',
        'icon': Icons.article_outlined,
        'color': const Color(0xFF6B73FF)
      },
      {
        'value': 'event',
        'label': 'Event',
        'icon': Icons.event_outlined,
        'color': const Color(0xFF9C88FF)
      },
      {
        'value': 'experience',
        'label': 'Experience',
        'icon': Icons.star_outline,
        'color': const Color(0xFFFF9F43)
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: types.map((typeData) {
            final isSelected = type == typeData['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => type = typeData['value'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (typeData['color'] as Color).withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? typeData['color'] as Color
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        typeData['icon'] as IconData,
                        color: isSelected
                            ? typeData['color'] as Color
                            : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        typeData['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? typeData['color'] as Color
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddPostPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _showAddPost ? null : 0,
      child: Container(
        padding: _showAddPost ? const EdgeInsets.all(24) : EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _showAddPost
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.create_outlined,
                          color: Color(0xFFD4AF37),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Create New Post",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                      titleController, "Title", Icons.title_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(
                      descController, "Description", Icons.description_outlined,
                      maxLines: 4),
                  const SizedBox(height: 16),
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _toggleAddPost,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addPost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Publish Post",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildPostCard(NewsEventPost post) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user?.uid == post.createdBy;

    final typeConfig = {
      'news': {
        'icon': Icons.article_outlined,
        'color': const Color(0xFF6B73FF)
      },
      'event': {'icon': Icons.event_outlined, 'color': const Color(0xFF9C88FF)},
      'experience': {
        'icon': Icons.star_outline,
        'color': const Color(0xFFFF9F43)
      },
    };

    final config = typeConfig[post.type] ?? typeConfig['news']!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (config['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    config['icon'] as IconData,
                    size: 18,
                    color: config['color'] as Color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.createdByName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            post.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: config['color'] as Color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            ' • ${_getTimeAgo(post.createdAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOwner) ...[
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: Colors.grey[600], size: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outlined,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editPost(post);
                      } else if (value == 'delete') {
                        _deletePost(post);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.favorite_border, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${post.likes.length}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(width: 24),
                Icon(Icons.comment_outlined, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${post.comments.length}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const Spacer(),
                Icon(Icons.share_outlined, size: 18, color: Colors.grey[600]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.article_outlined,
                size: 32,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Posts Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Be the first to share news and events with the alumni community",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // Royal App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF2C3E50),
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 18),
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => UserHomeScreen(),
                    )),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2C3E50),
                          Color(0xFF34495E),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'News & Events',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Stay connected with your alumni community',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Add Post Panel
              SliverToBoxAdapter(
                child: _buildAddPostPanel(),
              ),

              // Posts Feed
              StreamBuilder<List<NewsEventPost>>(
                stream: service.getPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: Color(0xFFD4AF37),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  }

                  final posts = snapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPostCard(posts[index]),
                      childCount: posts.length,
                    ),
                  );
                },
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: RotationTransition(
        turns: _fabRotationAnimation,
        child: FloatingActionButton(
          onPressed: _toggleAddPost,
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.white,
          elevation: 8,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showAddPost
                ? const Icon(Icons.close, key: ValueKey('close'))
                : const Icon(Icons.add, key: ValueKey('add')),
          ),
        ),
      ),
    );
  }
}
