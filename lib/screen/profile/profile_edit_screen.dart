import 'dart:io';
import 'dart:async';

import 'package:cs261_project/model/profile_model.dart';
import 'package:cs261_project/service/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cs261_project/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditScreen extends StatefulWidget {
  final String instituteId;
  final String userDocumentId;
  final String? role; // optional role hint from caller (participants)
  const ProfileEditScreen({
    super.key,
    required this.userDocumentId,
    required this.instituteId,
    this.role,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final ProfileService _profileService;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController rollCtrl = TextEditingController();
  final TextEditingController interestCtrl = TextEditingController();
  final TextEditingController bioCtrl = TextEditingController();
  final TextEditingController yearCtrl = TextEditingController();
  // Role specific controllers
  final TextEditingController companyCtrl = TextEditingController();
  final TextEditingController positionCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController linkedinCtrl = TextEditingController();
  final TextEditingController semesterCtrl = TextEditingController();
  final TextEditingController branchCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _profilePicUrl;
  String? _role; // fetched from profile or user claims later

  late AnimationController _animationController;
  late AnimationController _avatarAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _avatarScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the service first...
    _profileService = ProfileService(instituteId: widget.instituteId);

    // Seed role from caller if provided (e.g., participants role)
    _role = widget.role ?? _role;

    // ...then you can safely use it.
    _loadProfile();
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
    _animationController.dispose();
    _avatarAnimationController.dispose();
    nameCtrl.dispose();
    rollCtrl.dispose();
    interestCtrl.dispose();
    bioCtrl.dispose();
    yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile(widget.userDocumentId);
    if (profile != null && mounted) {
      setState(() {
        nameCtrl.text = profile.name ?? '';
        rollCtrl.text = profile.rollNo ?? '';
        interestCtrl.text = profile.interest ?? '';
        bioCtrl.text = profile.bio ?? '';
        yearCtrl.text = profile.year ?? '';
        _profilePicUrl = profile.picture;
        _role = profile.role;
        companyCtrl.text = profile.company ?? '';
        positionCtrl.text = profile.position ?? '';
        cityCtrl.text = profile.city ?? '';
        linkedinCtrl.text = profile.linkedin ?? '';
        semesterCtrl.text = profile.semester ?? '';
        branchCtrl.text = profile.branch ?? '';
      });
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      setState(() => _isUploading = true);

      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile == null) return;

      File file = File(pickedFile.path);
      final user = FirebaseAuth.instance.currentUser!;

      // Use a unique filename per upload to avoid CDN/image cache showing old photo
      final ts = DateTime.now().millisecondsSinceEpoch;
      // Explicitly use the configured storage bucket to avoid stale/wrong default bucket
      final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
      final storage = FirebaseStorage.instanceFor(bucket: bucket);
      debugPrint('[ImageUpload] Using bucket: ${bucket ?? 'NULL'}');
      final storageRef =
          storage.ref('profile_pictures/${user.uid}/avatar_$ts.jpg');
      await storageRef.putFile(
        file,
        SettableMetadata(
          cacheControl: 'no-cache, max-age=0',
        ),
      );
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _profilePicUrl = downloadUrl;
      });

      _avatarAnimationController.reset();
      _avatarAnimationController.forward();
    } on FirebaseException catch (e, st) {
      debugPrint(
          "[ImageUpload] FirebaseException code=${e.code} message=${e.message}\n$st");
      String msg = 'Image upload failed';
      if (e.code == 'permission-denied' || e.code == 'unauthorized') {
        msg = 'No permission to upload to Storage. Check Firebase rules.';
      } else if (e.code == 'canceled') {
        msg = 'Upload canceled';
      } else if (e.code == 'object-not-found') {
        msg = 'Storage bucket/path not found';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint("[ImageUpload] Unknown error: $e\n$st");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Image upload failed"),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      debugPrint('[ProfileEdit] Save tapped');
      if (_isUploading) {
        debugPrint('[ProfileEdit] Blocking save: image still uploading');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please wait for the photo upload to finish'),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
      // Ensure role chosen if not coming from caller/profile
      if (_role == null) {
        debugPrint('[ProfileEdit] Blocking save: role is null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select your role (Student or Alumni)'),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
      setState(() => _isSaving = true);
      debugPrint('[ProfileEdit] Validation passed. Starting save...');

      try {
        final sw = Stopwatch()..start();
        final profile = Profile(
          uid: widget.userDocumentId,
          name: nameCtrl.text.trim(),
          rollNo: rollCtrl.text.trim(),
          interest: interestCtrl.text.trim(),
          bio: bioCtrl.text.trim(),
          year: yearCtrl.text.trim(),
          picture: _profilePicUrl,
          isProfileComplete: true,
          role: _role,
          company: _role == 'alumni' ? companyCtrl.text.trim() : null,
          position: _role == 'alumni' ? positionCtrl.text.trim() : null,
          city: _role == 'alumni' ? cityCtrl.text.trim() : null,
          linkedin: _role == 'alumni' ? linkedinCtrl.text.trim() : null,
          semester: _role == 'student' ? semesterCtrl.text.trim() : null,
          branch: _role == 'student' ? branchCtrl.text.trim() : null,
        );

        debugPrint('[ProfileEdit] Calling ProfileService.saveProfile');
        await _profileService
            .saveProfile(widget.userDocumentId, profile)
            .timeout(const Duration(seconds: 8));
        sw.stop();

        debugPrint(
            '[ProfileEdit] Save completed in ${sw.elapsedMilliseconds}ms');
        if (!mounted) return;

        // Pop back, telling previous screen to refresh
        Navigator.of(context).pop(true);
        if (sw.elapsedMilliseconds > 1500 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile saved'),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } on TimeoutException {
        debugPrint('[ProfileEdit] TimeoutException while saving');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Saving is taking too long. Check connection and try again.'),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('[ProfileEdit] Save error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Could not save profile"),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
          debugPrint('[ProfileEdit] Save finished; _isSaving=false');
        }
      }
    }
  }

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 20),
              _buildImageSourceOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                color: const Color(0xFF6B73FF),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              _buildImageSourceOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take a Photo',
                color: const Color(0xFF10AC84),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
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
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Color(0xFF2C3E50),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create your distinguished profile',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return ScaleTransition(
      scale: _avatarScaleAnimation,
      child: GestureDetector(
        onTap: _isUploading ? null : _showImageSourceActionSheet,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _profilePicUrl == null
                    ? const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _isUploading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : ClipOval(
                      child: _profilePicUrl != null
                          ? Image.network(
                              _profilePicUrl!,
                              key: ValueKey(_profilePicUrl),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            )
                          : const Icon(
                              Icons.person_outline,
                              size: 50,
                              color: Colors.white,
                            ),
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    bool isNumeric = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFD4AF37),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: validator ??
            (value) =>
                (value == null || value.isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildRoleSelector() {
    // If role already known (passed in or loaded from profile) skip selector
    if (_role != null) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          'Select Role',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            ChoiceChip(
              label: const Text('Student'),
              selected: _role == 'student',
              avatar: const Icon(Icons.school_outlined, size: 18),
              onSelected: (v) {
                if (v) setState(() => _role = 'student');
              },
            ),
            ChoiceChip(
              label: const Text('Alumni'),
              selected: _role == 'alumni',
              avatar: const Icon(Icons.workspace_premium_outlined, size: 18),
              onSelected: (v) {
                if (v) setState(() => _role = 'alumni');
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Selecting Student will show Semester & Branch fields. Selecting Alumni shows Company details.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Allow navigating back; if a long save is in-flight, still allow user to exit
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: _isLoading
            ? Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
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
                        'Loading profile...',
                        style: TextStyle(
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.w500,
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
                      child: Form(
                        key: _formKey,
                        child: CustomScrollView(
                          slivers: [
                            SliverAppBar(
                              expandedHeight: 200,
                              floating: false,
                              pinned: true,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              automaticallyImplyLeading: true,
                              leading: Container(
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
                                    Icons.arrow_back_ios,
                                    color: Color(0xFF2C3E50),
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              ),
                              flexibleSpace: FlexibleSpaceBar(
                                background: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(0xFF2C3E50)
                                            .withOpacity(0.05),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 20),
                                          _buildHeader(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    _buildProfileAvatar(),
                                    const SizedBox(height: 16),
                                    Text(
                                      nameCtrl.text.isNotEmpty
                                          ? nameCtrl.text
                                          : 'Your Name',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E50),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    // Role selector only if not pre-known
                                    _buildRoleSelector(),
                                    _buildTextField(
                                      controller: nameCtrl,
                                      label: 'Full Name',
                                      icon: Icons.person_outline,
                                      iconColor: const Color(0xFF6B73FF),
                                    ),
                                    _buildTextField(
                                      controller: rollCtrl,
                                      label: 'Roll Number',
                                      icon: Icons.school_outlined,
                                      iconColor: const Color(0xFF9C88FF),
                                      isNumeric: true,
                                    ),
                                    _buildTextField(
                                      controller: yearCtrl,
                                      label: 'Graduation Year',
                                      icon: Icons.calendar_today_outlined,
                                      iconColor: const Color(0xFF10AC84),
                                      isNumeric: true,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Enter graduation year';
                                        }
                                        final year = int.tryParse(v);
                                        if (year == null) {
                                          return 'Enter a valid year';
                                        }
                                        const int minYear = 1990;
                                        final int maxYear =
                                            DateTime.now().year + 6;
                                        if (year < minYear || year > maxYear) {
                                          return 'Year must be between $minYear and $maxYear';
                                        }
                                        return null;
                                      },
                                    ),
                                    _buildTextField(
                                      controller: interestCtrl,
                                      label: 'Interests & Skills',
                                      icon: Icons.stars_outlined,
                                      iconColor: const Color(0xFFFF9F43),
                                    ),
                                    _buildTextField(
                                      controller: bioCtrl,
                                      label: 'Biography',
                                      icon: Icons.edit_outlined,
                                      iconColor: const Color(0xFFD4AF37),
                                      maxLines: 3,
                                      validator: (v) {
                                        if (v == null || v.trim().length < 20) {
                                          return 'Bio must be at least 20 chars';
                                        }
                                        return null;
                                      },
                                    ),
                                    if (_role == 'alumni') ...[
                                      _buildTextField(
                                        controller: companyCtrl,
                                        label: 'Company',
                                        icon: Icons.business_outlined,
                                        iconColor: const Color(0xFF6B73FF),
                                      ),
                                      _buildTextField(
                                        controller: positionCtrl,
                                        label: 'Position',
                                        icon: Icons.work_outline,
                                        iconColor: const Color(0xFF9C88FF),
                                      ),
                                      _buildTextField(
                                        controller: cityCtrl,
                                        label: 'City',
                                        icon: Icons.location_city_outlined,
                                        iconColor: const Color(0xFF10AC84),
                                      ),
                                      _buildTextField(
                                        controller: linkedinCtrl,
                                        label: 'LinkedIn URL',
                                        icon: Icons.link_outlined,
                                        iconColor: const Color(0xFFFF9F43),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return null; // optional
                                          }
                                          final ok = v.startsWith('http');
                                          return ok
                                              ? null
                                              : 'Must start with http';
                                        },
                                      ),
                                    ] else if (_role == 'student') ...[
                                      _buildTextField(
                                        controller: semesterCtrl,
                                        label: 'Semester',
                                        icon: Icons.timelapse_outlined,
                                        iconColor: const Color(0xFF6B73FF),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Enter semester';
                                          }
                                          final num = int.tryParse(v);
                                          if (num == null ||
                                              num < 1 ||
                                              num > 12) {
                                            return '1-12 only';
                                          }
                                          return null;
                                        },
                                      ),
                                      _buildTextField(
                                        controller: branchCtrl,
                                        label: 'Branch',
                                        icon: Icons.account_tree_outlined,
                                        iconColor: const Color(0xFF9C88FF),
                                      ),
                                    ],
                                    const SizedBox(height: 40),
                                    Container(
                                      width: double.infinity,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFD4AF37),
                                            Color(0xFFB8860B)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFD4AF37)
                                                .withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          onTap:
                                              _isSaving ? null : _saveProfile,
                                          child: Center(
                                            child: _isSaving
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Complete Profile',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
