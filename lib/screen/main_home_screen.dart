import 'package:flutter/material.dart';
import 'package:cs261_project/screen/events_and_news/news_event_screen.dart';
import 'package:cs261_project/screen/search/search_screen.dart';
import 'package:cs261_project/screen/opportunities/opportunities_screen.dart';
import 'package:cs261_project/screen/mentorship/mentorship_screen.dart';
import 'package:cs261_project/screen/message/inbox_screen.dart';

class MainHomeScreen extends StatefulWidget {
  final String instituteId;
  const MainHomeScreen({super.key, required this.instituteId});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedCardIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Elegant Welcome Header
                _buildWelcomeHeader(),

                const SizedBox(height: 24),

                // Quick Stats Section
                _buildQuickStats(),

                const SizedBox(height: 32),

                // Royal Actions Section
                _buildRoyalActions(),

                const SizedBox(height: 40),

                // Recent Activities with Royal Touch
                _buildElegantActivities(),

                const SizedBox(height: 32),

                // Minimalist Features
                _buildMinimalFeatures(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nightlight_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                greetingIcon,
                color: const Color(0xFFD4AF37),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to Alumni Connect',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.amber[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your distinguished alumni network awaits',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      {'label': 'Alumni', 'value': '500+', 'icon': Icons.people_outline},
      {'label': 'Events', 'value': '12', 'icon': Icons.event_outlined},
      {'label': 'Jobs', 'value': '25', 'icon': Icons.work_outline},
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  stat['icon'] as IconData,
                  color: const Color(0xFF6B73FF),
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoyalActions() {
    final actions = [
      {
        'icon': Icons.people_alt_outlined,
        'title': 'Alumni Network',
        'subtitle': 'Connect with peers',
        'color': const Color(0xFF6B73FF),
        'count': '500+'
      },
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Events',
        'subtitle': 'Exclusive gatherings',
        'color': const Color(0xFF9C88FF),
        'count': '12'
      },
      {
        'icon': Icons.work_outline_outlined,
        'title': 'Opportunities',
        'subtitle': 'Career advancement',
        'color': const Color(0xFFFF9F43),
        'count': '25'
      },
      {
        'icon': Icons.school_outlined,
        'title': 'Mentorship',
        'subtitle': 'Wisdom exchange',
        'color': const Color(0xFF10AC84),
        'count': '50+'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Connect & Grow',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: const Color(0xFFD4AF37),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            final isSelected = _selectedCardIndex == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()..scale(isSelected ? 0.95 : 1.0),
              child: GestureDetector(
                onTap: () {
                  final title = action['title'] as String;
                  Widget? destination;
                  if (title == 'Events') {
                    destination =
                        NewsEventScreen(instituteId: widget.instituteId);
                  } else if (title == 'Alumni Network') {
                    destination = SearchScreen(instituteId: widget.instituteId);
                  } else if (title == 'Opportunities') {
                    destination =
                        OpportunitiesScreen(instituteId: widget.instituteId);
                  } else if (title == 'Mentorship') {
                    destination =
                        MentorshipScreen(instituteId: widget.instituteId);
                  }

                  if (destination != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => destination!),
                    );
                    return;
                  }

                  // Fallback animation (shouldn't trigger now)
                  setState(() => _selectedCardIndex = index);
                  Future.delayed(const Duration(milliseconds: 150), () {
                    setState(() => _selectedCardIndex = -1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feature coming soon'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFF2C3E50),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        (action['color'] as Color).withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (action['color'] as Color).withOpacity(0.5)
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? (action['color'] as Color).withOpacity(0.3)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: isSelected ? 15 : 20,
                        offset: Offset(0, isSelected ? 4 : 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    (action['color'] as Color).withOpacity(0.2),
                                    (action['color'] as Color).withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                action['icon'] as IconData,
                                size: 24,
                                color: action['color'] as Color,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (action['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                action['count'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: action['color'] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          action['title'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildElegantActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...List.generate(3, (index) {
          final activities = [
            {
              'title': 'Welcome to Excellence',
              'subtitle': 'Your distinguished journey begins',
              'time': '2m ago',
              'color': const Color(0xFFD4AF37),
              'icon': Icons.star_border_outlined,
            },
            {
              'title': 'Network Expanded',
              'subtitle': 'Connect with 500+ distinguished alumni',
              'time': '1h ago',
              'color': const Color(0xFF6B73FF),
              'icon': Icons.people_alt_outlined,
            },
            {
              'title': 'Exclusive Invitation',
              'subtitle': 'Annual Alumni Gala registration open',
              'time': '3h ago',
              'color': const Color(0xFF9C88FF),
              'icon': Icons.event_outlined,
            },
          ];

          final activity = activities[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (activity['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activity['icon'] as IconData,
                    size: 18,
                    color: activity['color'] as Color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  activity['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMinimalFeatures() {
    final features = [
      {
        'icon': Icons.search_outlined,
        'title': 'Discover Alumni',
        'color': const Color(0xFF6B73FF),
      },
      {
        'icon': Icons.chat_bubble_outline,
        'title': 'Private Conversations',
        'color': const Color(0xFF10AC84),
      },
      {
        'icon': Icons.military_tech_outlined,
        'title': 'Success Chronicles',
        'color': const Color(0xFFD4AF37),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 24),
        ...features.map((feature) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final title = feature['title'] as String;
                    Widget? destination;
                    if (title == 'Discover Alumni') {
                      destination =
                          SearchScreen(instituteId: widget.instituteId);
                    } else if (title == 'Private Conversations') {
                      destination =
                          InboxScreen(instituteId: widget.instituteId);
                    } else if (title == 'Success Chronicles') {
                      destination =
                          NewsEventScreen(instituteId: widget.instituteId);
                    }

                    if (destination != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => destination!),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Feature coming soon'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFF2C3E50),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          feature['icon'] as IconData,
                          size: 22,
                          color: feature['color'] as Color,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            feature['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
