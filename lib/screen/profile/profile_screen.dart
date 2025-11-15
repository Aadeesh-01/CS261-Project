import 'dart:async';
import 'package:cs261_project/screen/profile/profile_edit_screen.dart';
import 'package:cs261_project/model/profile_model.dart';
import 'package:cs261_project/service/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final String instituteId;
  const ProfileScreen({super.key, required this.instituteId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final ProfileService _profileService;
  bool _isLoading = true;
  Profile? _profile;
  String? _userDocumentId;
  String? _role; // from participants
  double _completion = 0.0;
  StreamSubscription<Profile?>? _profileSub; // live updates
  int _avatarBustToken =
      DateTime.now().millisecondsSinceEpoch; // forces image refresh

  late AnimationController _animationController;
  late AnimationController _avatarAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _avatarScaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize services BEFORE kicking off async loads to avoid late init errors
    _profileService = ProfileService(instituteId: widget.instituteId);
    _loadInitialData();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _avatarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _avatarScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _avatarAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _avatarAnimationController.forward();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _animationController.dispose();
    _avatarAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      return;
    }

    final uid = user.uid;
    _userDocumentId = uid;
    try {
      await _loadRole(uid);
      await _loadProfile(uid);
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Failed loading profile for $uid: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProfile(String uid) async {
    // Use stream subscription for live updates
    _profileSub?.cancel();
    _profileSub = _profileService.getProfileStream(uid).listen((profile) {
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _completion = _computeCompletion(profile, _role);
        _isLoading = false;
        // If picture changed, update bust token to force Image.network refresh
        if (profile?.picture != null) {
          _avatarBustToken = DateTime.now().millisecondsSinceEpoch;
        }
      });
    }, onError: (e) {
      debugPrint('🔴 profile stream error: $e');
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _loadRole(String uid) async {
    try {
      _role = await _profileService.getUserRole(uid);
    } catch (e) {
      debugPrint('⚠️ Failed to fetch role: $e');
    }
  }

  double _computeCompletion(Profile? p, String? role) {
    if (p == null) return 0.0;
    int total = 5; // base fields
    int have = 0;

    bool has(String? s) => s != null && s.trim().isNotEmpty;

    if (has(p.name)) have++;
    if (has(p.year)) have++;
    if (has(p.interest)) have++;
    if (has(p.bio) && (p.bio!.trim().length >= 20)) have++;
    if (has(p.picture)) have++;

    if (role == 'alumni') {
      total += 2; // minimal alumni-specific
      if (has(p.company)) have++;
      if (has(p.position)) have++;
    } else if (role == 'student') {
      total += 2;
      if (has(p.semester)) have++;
      if (has(p.branch)) have++;
    }

    return (have / total).clamp(0.0, 1.0);
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final name = _profile?.name ?? "Distinguished Alumni";
    // Cache-busted avatar URL
    String? url = _profile?.picture;
    if (url != null) {
      url = url.contains('?')
          ? '$url&v=$_avatarBustToken'
          : '$url?v=$_avatarBustToken';
    }

    return ScaleTransition(
      scale: _avatarScaleAnimation,
      child: GestureDetector(
        onTap: url != null ? () => _showImageDialog(url!) : null,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: url == null
                ? const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: url != null
                ? Image.network(
                    url,
                    key: ValueKey(url),
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                  )
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontSize: 42,
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      String title, String? value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value != null && value.isNotEmpty ? value : "Not provided",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: value != null && value.isNotEmpty
                        ? const Color(0xFF2C3E50)
                        : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    final bio = _profile?.bio;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B73FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 20,
                  color: Color(0xFF6B73FF),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            bio != null && bio.isNotEmpty ? bio : "No biography provided yet",
            style: TextStyle(
              fontSize: 14,
              color: bio != null && bio.isNotEmpty
                  ? const Color(0xFF2C3E50)
                  : Colors.grey[500],
              height: 1.5,
              fontStyle: bio == null || bio.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFD4AF37),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading your profile...',
                      style: TextStyle(
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _profile == null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_off_outlined,
                            size: 32,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No Profile Found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Your profile data could not be loaded",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit_outlined),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (_userDocumentId == null) return;
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileEditScreen(
                                    userDocumentId: _userDocumentId!,
                                    instituteId: widget.instituteId,
                                    role:
                                        _role, // pass role so student/alumni fields appear immediately
                                  ),
                                ),
                              );
                              if (updated == true && _userDocumentId != null) {
                                // Optimistic completion; stream will deliver fresh data
                                if (mounted) {
                                  setState(() {
                                    _isLoading =
                                        false; // keep showing existing data until stream update
                                  });
                                }
                              }
                            },
                            label: const Text('Create / Update Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: CustomScrollView(
                          slivers: [
                            // Custom App Bar with Hero Profile
                            SliverAppBar(
                              expandedHeight: 280,
                              floating: false,
                              pinned: true,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              automaticallyImplyLeading: false,
                              actions: [
                                Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Color(0xFFD4AF37),
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      if (_userDocumentId == null) return;

                                      final updated = await Navigator.push<
                                              bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProfileEditScreen(
                                              userDocumentId: _userDocumentId!,
                                              instituteId: widget.instituteId,
                                              // pass role for conditional fields
                                              // if role unknown, editor can still work with base fields
                                              role: _role,
                                            ),
                                          ));

                                      if (updated == true &&
                                          _userDocumentId != null) {
                                        // We rely on stream; optimistic UI
                                        if (mounted) setState(() {});
                                      }
                                    },
                                  ),
                                ),
                              ],
                              flexibleSpace: FlexibleSpaceBar(
                                background: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(0xFF2C3E50)
                                            .withOpacity(0.8),
                                        const Color(0xFF34495E)
                                            .withOpacity(0.6),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 16),
                                      _buildProfileAvatar(),
                                      const SizedBox(height: 16),
                                      Text(
                                        _profile?.name ?? "Your Name",
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white,
                                          letterSpacing: 1.1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Content
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Moved progress + year/role chip below header to prevent overflow
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 24),
                                      child: Column(
                                        children: [
                                          LinearProgressIndicator(
                                            value: _completion,
                                            color: const Color(0xFFD4AF37),
                                            backgroundColor: Colors.grey[300],
                                            minHeight: 6,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFD4AF37)
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFFD4AF37)
                                                            .withOpacity(0.4),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  _profile?.year != null &&
                                                          _profile!
                                                              .year!.isNotEmpty
                                                      ? (_role == 'student'
                                                          ? 'Graduation Year: ${_profile!.year}'
                                                          : _role == 'alumni'
                                                              ? 'Class of ${_profile!.year}'
                                                              : _profile!.year!)
                                                      : (_role == 'student'
                                                          ? 'Graduation Year'
                                                          : _role == 'alumni'
                                                              ? 'Alumni'
                                                              : 'Profile'),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        const Color(0xFF2C3E50)
                                                            .withOpacity(0.85),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Completion: ${(_completion * 100).round()}%',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_role != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.verified_user,
                                                size: 18,
                                                color: Color(0xFFD4AF37)),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Role: ${_role!}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    // Personal Information Section
                                    _buildSectionTitle('Personal Details'),
                                    const SizedBox(height: 20),

                                    _buildInfoCard(
                                      'Roll Number',
                                      _profile?.rollNo,
                                      Icons.badge_outlined,
                                      const Color(0xFF9C88FF),
                                    ),

                                    _buildInfoCard(
                                      'Graduation Year',
                                      _profile?.year,
                                      Icons.school_outlined,
                                      const Color(0xFF10AC84),
                                    ),

                                    _buildInfoCard(
                                      'Interests & Skills',
                                      _profile?.interest,
                                      Icons.stars_outlined,
                                      const Color(0xFFFF9F43),
                                    ),

                                    if (_role == 'alumni') ...[
                                      _buildInfoCard(
                                        'Company',
                                        _profile?.company,
                                        Icons.business_outlined,
                                        const Color(0xFF6B73FF),
                                      ),
                                      _buildInfoCard(
                                        'Position',
                                        _profile?.position,
                                        Icons.work_outline,
                                        const Color(0xFF9C88FF),
                                      ),
                                      _buildInfoCard(
                                        'City',
                                        _profile?.city,
                                        Icons.location_city_outlined,
                                        const Color(0xFF10AC84),
                                      ),
                                      _buildInfoCard(
                                        'LinkedIn',
                                        _profile?.linkedin,
                                        Icons.link_outlined,
                                        const Color(0xFFFF9F43),
                                      ),
                                    ] else if (_role == 'student') ...[
                                      _buildInfoCard(
                                        'Semester',
                                        _profile?.semester,
                                        Icons.timelapse_outlined,
                                        const Color(0xFF6B73FF),
                                      ),
                                      _buildInfoCard(
                                        'Branch',
                                        _profile?.branch,
                                        Icons.account_tree_outlined,
                                        const Color(0xFF9C88FF),
                                      ),
                                    ],

                                    const SizedBox(height: 32),

                                    // About Section
                                    _buildSectionTitle('Biography'),
                                    const SizedBox(height: 20),
                                    _buildBioSection(),

                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
