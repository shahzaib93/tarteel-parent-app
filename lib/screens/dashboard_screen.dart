import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/parent_service.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../services/announcement_service.dart';
import '../services/webrtc_service.dart';
import '../services/app_config_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/child_card.dart';
import '../widgets/alert_card.dart';
import '../widgets/active_call_banner.dart';
import '../widgets/announcement_card.dart';
import '../widgets/incoming_call_dialog.dart';
import '../widgets/video_call_screen.dart';
import 'child_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _initialized = false;
  int _selectedIndex = 0;
  _AlertFilter _alertFilter = _AlertFilter.active;
  bool _callScreenOpen = false;
  bool _incomingDialogVisible = false;
  BuildContext? _incomingDialogContext;

  void _closeIncomingDialog() {
    if (!_incomingDialogVisible) {
      return;
    }
    final dialogContext = _incomingDialogContext;
    if (dialogContext != null) {
      final navigator = Navigator.of(dialogContext, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
    _incomingDialogVisible = false;
    _incomingDialogContext = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final parentService = context.read<ParentService>();
        final alertService = context.read<AlertService>();
        final callService = context.read<CallStatusService>();
        final announcementService = context.read<AnnouncementService>();
        final webrtcService = context.read<WebRTCService>();
        final appConfigService = context.read<AppConfigService>();
        final authService = context.read<ParentAuthService>();
        () async {
          await parentService.loadChildren();
          if (!mounted) return;
          final childIds = parentService.children.map((c) => c.id).toList();
          await alertService.loadAlerts(childIds: childIds);
          if (!mounted) return;
          callService.startListening();
          announcementService.loadAnnouncements();

          // Initialize WebRTC service for incoming calls
          final user = authService.currentUser;
          if (user != null && mounted) {
            // Get socket URL and TURN config from Firestore
            final socketUrl = appConfigService.socketUrl;
            final turnConfig = appConfigService.turnConfig;

            if (turnConfig != null) {
              webrtcService.configureTurnServer(turnConfig);
            }

            webrtcService.connect(
              user.uid,
              user.displayName ?? 'Parent',
              socketUrl: socketUrl,
            );
          }
        }();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ParentAuthService>();
    final childrenService = context.watch<ParentService>();
    final alertsService = context.watch<AlertService>();
    final callsService = context.watch<CallStatusService>();
    final announcementService = context.watch<AnnouncementService>();
    final webrtcService = context.watch<WebRTCService>();

    if (webrtcService.isInCall && _incomingDialogVisible) {
      _closeIncomingDialog();
    }

    if (webrtcService.callerInfo == null && _incomingDialogVisible) {
      _closeIncomingDialog();
    }

    // Show incoming call dialog when a call arrives
    if (webrtcService.callerInfo != null && !webrtcService.isInCall && !_incomingDialogVisible) {
      _incomingDialogVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _incomingDialogVisible = false;
          _incomingDialogContext = null;
          return;
        }
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (dialogContext) {
            _incomingDialogContext = dialogContext;
            return const IncomingCallDialog();
          },
        ).whenComplete(() {
          _incomingDialogVisible = false;
          _incomingDialogContext = null;
        });
      });
    }

    if (webrtcService.isInCall && !_callScreenOpen) {
      _callScreenOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _callScreenOpen = false;
          return;
        }
        final navigator = Navigator.of(context, rootNavigator: true);
        await navigator.push(MaterialPageRoute(builder: (_) => const VideoCallScreen()));
        if (mounted) {
          setState(() {
            _callScreenOpen = false;
          });
        } else {
          _callScreenOpen = false;
        }
      });
    } else if (!webrtcService.isInCall && _callScreenOpen) {
      _callScreenOpen = false;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        final screens = [
          _buildHome(auth, childrenService, alertsService, callsService, announcementService, isDesktop),
          _buildChildren(childrenService, isDesktop),
          _buildAlerts(alertsService, isDesktop),
          _buildSettings(auth, isDesktop),
        ];

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                // Side Navigation
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                  extended: constraints.maxWidth > 1200,
                  minExtendedWidth: 220,
                  backgroundColor: Colors.white,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 48,
                          width: 48,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.family_restroom,
                            size: 48,
                            color: Color(0xFF76a6f6),
                          ),
                        ),
                        if (constraints.maxWidth > 1200) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Tarteel-e-Quran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const Text(
                            'Parent Portal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: 'Sign Out',
                          onPressed: () => auth.signOut(),
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.family_restroom_outlined),
                      selectedIcon: Icon(Icons.family_restroom),
                      label: Text('Children'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.warning_amber_outlined),
                      selectedIcon: Icon(Icons.warning_amber),
                      label: Text('Alerts'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Main Content
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFF),
                    child: Column(
                      children: [
                        _buildDesktopAppBar(auth),
                        Expanded(child: screens[_selectedIndex]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile layout
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFF),
            body: IndexedStack(index: _selectedIndex, children: screens),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMobileNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                      _buildMobileNavItem(1, Icons.family_restroom_outlined, Icons.family_restroom, 'Children'),
                      _buildMobileNavItem(2, Icons.notifications_outlined, Icons.notifications, 'Alerts'),
                      _buildMobileNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDesktopAppBar(ParentAuthService auth) {
    final name = auth.currentUser?.displayName ?? 'Parent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _getPageTitle(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          Text(
            'Welcome, $name',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: const Color(0xFF76a6f6),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'P',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Children';
      case 2:
        return 'Alerts';
      case 3:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildMobileNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667eea).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? const Color(0xFF667eea) : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF667eea) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChildDetails(ChildProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChildDetailScreen(profile: profile)),
    );
  }

  Widget _buildHome(
    ParentAuthService auth,
    ParentService children,
    AlertService alerts,
    CallStatusService calls,
    AnnouncementService announcements,
    bool isDesktop,
  ) {
    final unread = children.children.fold<int>(0, (sum, c) => sum + c.unreadMessages);

    if (isDesktop) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(auth, children, alerts),
            const SizedBox(height: 24),
            if (calls.activeCalls.isNotEmpty) ...[
              const Text('Live Calls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final call in calls.activeCalls)
                    SizedBox(width: 400, child: ActiveCallBanner(call: call)),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // Stats in a row for desktop
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Active Children',
                    subtitle: 'Linked to your account',
                    value: '${children.children.length}',
                    icon: Icons.family_restroom,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Unread Messages',
                    subtitle: 'Across all children',
                    value: '$unread',
                    icon: Icons.mail_outline,
                    color: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Upcoming Classes',
                    subtitle: 'Next 24h',
                    value: children.children.isEmpty ? '0' : '1+',
                    icon: Icons.schedule,
                    color: const Color(0xFFF97316),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Alerts',
                    subtitle: 'Last 48h',
                    value: '${alerts.alerts.length}',
                    icon: Icons.shield_outlined,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Two column layout for children and alerts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Children & Announcements
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Children', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      if (children.loading)
                        const Center(child: CircularProgressIndicator())
                      else if (children.children.isEmpty)
                        _emptyState('No children linked yet.')
                      else
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (final child in children.children)
                              SizedBox(
                                width: 350,
                                child: ChildCard(
                                  profile: child,
                                  onTap: () => _openChildDetails(child),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 32),
                      const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      if (announcements.loading)
                        const Center(child: CircularProgressIndicator())
                      else if (announcements.announcements.isEmpty)
                        _emptyState('No new announcements.')
                      else
                        ...announcements.announcements.map((notice) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AnnouncementCard(announcement: notice),
                            )),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right column - Alerts
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      if (alerts.alerts.isEmpty)
                        _emptyState('No alerts at this time.')
                      else
                        ...alerts.alerts.take(5).map((alert) => AlertCard(alert: alert)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return CustomScrollView(
      slivers: [
        // Modern gradient app bar
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 32,
                              height: 32,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.family_restroom,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good ${_getGreeting()}!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                auth.currentUser?.displayName ?? 'Parent',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () => setState(() => _selectedIndex = 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Quick stats row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickStat('${children.children.length}', 'Children'),
                          Container(width: 1, height: 30, color: Colors.white24),
                          _buildQuickStat('${alerts.alerts.length}', 'Alerts'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -16),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live calls
                    if (calls.activeCalls.isNotEmpty) ...[
                      _buildMobileSectionHeader('Live Now', Icons.videocam, Colors.red),
                      const SizedBox(height: 12),
                      for (final call in calls.activeCalls) ...[
                        ActiveCallBanner(call: call),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 8),
                    ],

                    // Children section
                    _buildMobileSectionHeader('Your Children', Icons.family_restroom, const Color(0xFF667eea)),
                    const SizedBox(height: 12),
                    if (children.loading)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (children.children.isEmpty)
                      _buildMobileEmptyState('No children linked yet', Icons.family_restroom_outlined)
                    else ...[
                      for (final child in children.children) ...[
                        _buildMobileChildCard(child),
                        const SizedBox(height: 12),
                      ]
                    ],

                    const SizedBox(height: 20),

                    // Alerts section
                    _buildMobileSectionHeader('Recent Alerts', Icons.shield_outlined, const Color(0xFFE11D48)),
                    const SizedBox(height: 12),
                    if (alerts.alerts.isEmpty)
                      _buildMobileEmptyState('No alerts at this time', Icons.check_circle_outline)
                    else ...[
                      for (final alert in alerts.alerts.take(3)) AlertCard(alert: alert),
                    ],

                    const SizedBox(height: 20),

                    // Announcements section
                    _buildMobileSectionHeader('Announcements', Icons.campaign_outlined, const Color(0xFFF97316)),
                    const SizedBox(height: 12),
                    if (announcements.loading)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (announcements.announcements.isEmpty)
                      _buildMobileEmptyState('No new announcements', Icons.campaign_outlined)
                    else ...[
                      for (final notice in announcements.announcements) ...[
                        AnnouncementCard(announcement: notice),
                        const SizedBox(height: 12),
                      ]
                    ],
                    const SizedBox(height: 80), // Bottom padding for nav bar
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileChildCard(ChildProfile child) {
    return GestureDetector(
      onTap: () => _openChildDetails(child),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.school_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          child.teacherName,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (child.unreadMessages > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${child.unreadMessages}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePageHeader(String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.family_restroom,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarteel-e-Quran',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildren(ParentService children, bool isDesktop) {
    if (isDesktop) {
      return Container(
        color: const Color(0xFFF8FAFF),
        padding: const EdgeInsets.all(24),
        child: children.loading
            ? const Center(child: CircularProgressIndicator())
            : children.children.isEmpty
                ? Center(child: _emptyState('No children linked. Contact support.'))
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final child in children.children)
                          SizedBox(
                            width: 400,
                            child: ChildCard(
                              profile: child,
                              onTap: () => _openChildDetails(child),
                            ),
                          ),
                      ],
                    ),
                  ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildMobilePageHeader('Children')),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -16),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: children.loading
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                    : children.children.isEmpty
                        ? _buildMobileEmptyState('No children linked yet', Icons.family_restroom_outlined)
                        : Column(
                            children: [
                              for (final child in children.children) ...[
                                _buildMobileChildCard(child),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 80),
                            ],
                          ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlerts(AlertService alerts, bool isDesktop) {
    final filteredAlerts = _filteredAlerts(alerts.alerts);

    if (isDesktop) {
      return Container(
        color: const Color(0xFFF8FAFF),
        padding: const EdgeInsets.all(24),
        child: alerts.loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _alertFilters(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredAlerts.isEmpty
                        ? Center(child: _emptyState('No ${_alertFilter.label} alerts right now.'))
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                for (final alert in filteredAlerts)
                                  SizedBox(width: 500, child: AlertCard(alert: alert)),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildMobilePageHeader('Alerts')),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -16),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: alerts.loading
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _alertFilters(),
                          const SizedBox(height: 16),
                          if (filteredAlerts.isEmpty)
                            _buildMobileEmptyState('No ${_alertFilter.label} alerts', Icons.check_circle_outline)
                          else ...[
                            for (final alert in filteredAlerts) AlertCard(alert: alert),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(ParentAuthService auth, bool isDesktop) {
    final user = auth.currentUser;

    if (isDesktop) {
      final content = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _settingsContent(user, auth),
              ],
            ),
          ),
        ],
      );

      return Container(
        color: const Color(0xFFF8FAFF),
        alignment: Alignment.topLeft,
        child: content,
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildMobilePageHeader('Profile')),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -16),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _settingsContent(user, auth),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingsContent(dynamic user, ParentAuthService auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.displayName ?? 'Parent',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: const TextStyle(color: Colors.black54)),
              if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(user.phoneNumber!, style: const TextStyle(color: Colors.black54)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                trailing: Text('1.0.0', style: TextStyle(color: Colors.grey.shade600)),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                onTap: () {},
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: auth.loading ? null : () async => auth.signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ParentAuthService auth, ParentService children, AlertService alerts) {
    final name = auth.currentUser?.displayName ?? 'Parent';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 46,
                height: 46,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.family_restroom, color: Colors.white, size: 36),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $name', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 4),
                const Text(
                  'Your children are learning safely',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _headerChip(Icons.child_care, '${children.children.length} children'),
                    _headerChip(Icons.warning_amber, '${alerts.alerts.length} alerts'),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.black54))),
    );
  }

  List<ParentAlert> _filteredAlerts(List<ParentAlert> alerts) {
    switch (_alertFilter) {
      case _AlertFilter.all:
        return alerts;
      case _AlertFilter.active:
        return alerts.where((a) => a.status.toLowerCase() != 'resolved').toList();
      case _AlertFilter.resolved:
        return alerts.where((a) => a.status.toLowerCase() == 'resolved').toList();
    }
  }

  Widget _alertFilters() {
    return Wrap(
      spacing: 8,
      children: _AlertFilter.values.map((filter) {
        final selected = filter == _alertFilter;
        return ChoiceChip(
          label: Text(filter.label),
          selected: selected,
          onSelected: (_) => setState(() => _alertFilter = filter),
        );
      }).toList(),
    );
  }
}

enum _AlertFilter { all, active, resolved }

extension on _AlertFilter {
  String get label {
    switch (this) {
      case _AlertFilter.all:
        return 'All';
      case _AlertFilter.active:
        return 'Active';
      case _AlertFilter.resolved:
        return 'Resolved';
    }
  }
}
