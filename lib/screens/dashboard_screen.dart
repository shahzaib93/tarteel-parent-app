import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/parent_service.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../services/announcement_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/child_card.dart';
import '../widgets/alert_card.dart';
import '../widgets/active_call_banner.dart';
import '../widgets/announcement_card.dart';
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
        () async {
          await parentService.loadChildren();
          if (!mounted) return;
          final childIds = parentService.children.map((c) => c.id).toList();
          await alertService.loadAlerts(childIds: childIds);
          if (!mounted) return;
          callService.startListening();
          announcementService.loadAnnouncements();
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

    final screens = [
      _buildHome(auth, childrenService, alertsService, callsService, announcementService),
      _buildChildren(childrenService),
      _buildAlerts(alertsService),
      _buildSettings(auth),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF76a6f6),
                Color(0xFF5a8edb),
              ],
            ),
          ),
          child: SafeArea(
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    width: 40,
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Text(
                      'Tarteel-e-Quran',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined),
            selectedIcon: Icon(Icons.dashboard_customize),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.family_restroom_outlined),
            selectedIcon: Icon(Icons.family_restroom),
            label: 'Children',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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
  ) {
    final unread = children.children.fold<int>(0, (sum, c) => sum + c.unreadMessages);
    return SafeArea(
      child: Container(
        color: const Color(0xFFF8FAFF),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(auth, children, alerts),
            const SizedBox(height: 16),
            if (calls.loading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (calls.activeCalls.isNotEmpty) ...[
              const Text('Live Calls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              for (final call in calls.activeCalls) ...[
                ActiveCallBanner(call: call),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],
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
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Unread Messages',
                    subtitle: 'Across all children',
                    value: '$unread',
                    icon: Icons.mail_outline,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Upcoming Classes',
                    subtitle: 'Next 24h',
                    value: children.children.isEmpty ? '0' : '1+',
                    icon: Icons.schedule,
                    color: const Color(0xFFF97316),
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 24),
            const Text('Children', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (children.loading)
              const Center(child: CircularProgressIndicator())
            else if (children.children.isEmpty)
              _emptyState('No children linked yet.')
            else ...[
              for (final child in children.children) ...[
                ChildCard(
                  profile: child,
                  onTap: () => _openChildDetails(child),
                ),
                const SizedBox(height: 12),
              ]
            ],
            const SizedBox(height: 16),
            const Text('Recent Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (alerts.alerts.isEmpty)
              _emptyState('No alerts at this time.')
            else ...[
              for (final alert in alerts.alerts.take(3)) AlertCard(alert: alert),
            ],
            const SizedBox(height: 16),
            const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (announcements.loading)
              const Center(child: CircularProgressIndicator())
            else if (announcements.announcements.isEmpty)
              _emptyState('No new announcements.')
            else ...[
              for (final notice in announcements.announcements) ...[
                AnnouncementCard(announcement: notice),
                const SizedBox(height: 12),
              ]
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChildren(ParentService children) {
    return SafeArea(
      child: Container(
        color: const Color(0xFFF8FAFF),
        padding: const EdgeInsets.all(16),
        child: children.loading
            ? const Center(child: CircularProgressIndicator())
            : children.children.isEmpty
                ? _emptyState('No children linked. Contact support.')
                : ListView(
                    children: [
                      for (final child in children.children) ...[
                        ChildCard(
                          profile: child,
                          onTap: () => _openChildDetails(child),
                        ),
                        const SizedBox(height: 12),
                      ]
                    ],
                  ),
      ),
    );
  }

  Widget _buildAlerts(AlertService alerts) {
    final filteredAlerts = _filteredAlerts(alerts.alerts);
    return SafeArea(
      child: Container(
        color: const Color(0xFFF8FAFF),
        padding: const EdgeInsets.all(16),
        child: alerts.loading
            ? const Center(child: CircularProgressIndicator())
            : alerts.alerts.isEmpty
                ? _emptyState('Great news! No alerts to review.')
                : ListView(
                    children: [
                      _alertFilters(),
                      const SizedBox(height: 12),
                      if (filteredAlerts.isEmpty)
                        _emptyState('No ${_alertFilter.label} alerts right now.')
                      else
                        ...[
                          for (final alert in filteredAlerts) AlertCard(alert: alert),
                        ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildSettings(ParentAuthService auth) {
    final user = auth.currentUser;
    return SafeArea(
      child: Container(
        color: const Color(0xFFF8FAFF),
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? 'Parent', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            ),
          ],
        ),
      ),
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
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.family_restroom,
                  color: Colors.white,
                  size: 36,
                ),
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
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
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
