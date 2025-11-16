import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/parent_service.dart';
import '../services/child_history_service.dart';

class ChildDetailScreen extends StatelessWidget {
  final ChildProfile profile;

  const ChildDetailScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final historyService = Provider.of<ChildHistoryService>(context, listen: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return _buildDesktopLayout(context, historyService);
        } else {
          return _buildMobileLayout(context, historyService);
        }
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ChildHistoryService historyService) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Teacher: ${profile.teacherName}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _infoChip(Icons.message_outlined, '${profile.unreadMessages} unread'),
                const SizedBox(width: 8),
                _infoChip(Icons.schedule, profile.nextClassTime),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Call Logs
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Call History', Icons.call_outlined),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _ChildCallLogs(childId: profile.id, service: historyService),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right column - Messages
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Messages', Icons.message_outlined),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _ChildMessages(
                          childId: profile.id,
                          teacherId: profile.teacherId,
                          service: historyService,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4F46E5), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4F46E5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ChildHistoryService historyService) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white30, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'C',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profile.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.school_outlined, size: 16, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  profile.teacherName,
                                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMobileInfoChip(Icons.message_outlined, '${profile.unreadMessages} unread'),
                                const SizedBox(width: 8),
                                _buildMobileInfoChip(Icons.schedule, profile.nextClassTime),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    labelColor: const Color(0xFF667eea),
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: const Color(0xFF667eea),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Call History'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Messages'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _ChildCallLogs(childId: profile.id, service: historyService),
              _ChildMessages(
                childId: profile.id,
                teacherId: profile.teacherId,
                service: historyService,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class _ChildCallLogs extends StatelessWidget {
  final String childId;
  final ChildHistoryService service;

  const _ChildCallLogs({required this.childId, required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CallLogEntry>>(
      stream: service.callLogs(childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final calls = snapshot.data ?? const [];
        if (calls.isEmpty) {
          return const Center(child: Text('No calls yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final call = calls[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: call.status == 'completed'
                            ? Colors.green
                            : call.status == 'missed'
                                ? Colors.red
                                : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        call.status.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(_formatDate(call.startTime), style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Teacher: ${call.teacherName}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(_formatDuration(call), style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: calls.length,
        );
      },
    );
  }

  String _formatDate(DateTime time) {
    return '${time.month}/${time.day}/${time.year} • ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(CallLogEntry call) {
    if (call.duration == null) return 'In progress';
    final duration = call.duration!;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (minutes == 0) {
      return '${duration.inSeconds}s';
    }
    return '$minutes:$seconds min';
  }
}

class _ChildMessages extends StatelessWidget {
  final String childId;
  final String? teacherId;
  final ChildHistoryService service;

  const _ChildMessages({
    required this.childId,
    required this.teacherId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    if (teacherId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Messages will appear once this child is assigned to a teacher.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final conversationId = _buildConversationId(childId, teacherId!);
    return StreamBuilder<List<MessageEntry>>(
      stream: service.conversationMessages(conversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final messages = snapshot.data ?? const [];
        if (messages.isEmpty) {
          return const Center(child: Text('No messages to display.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final message = messages[index];
            final isTeacher = message.senderRole.toLowerCase().contains('teacher');
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isTeacher ? const Color(0xFFEEF2FF) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isTeacher ? Icons.school_outlined : Icons.person_outline,
                        size: 18,
                        color: Colors.indigo.shade400,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${message.senderName} • ${_formatRelative(message.timestamp)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.message,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: messages.length,
        );
      },
    );
  }

  String _formatRelative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      if (diff.inMinutes <= 0) {
        return 'Just now';
      }
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${time.month}/${time.day}/${time.year}';
  }

  String _buildConversationId(String a, String b) {
    final participants = [a, b]..sort();
    return participants.join('_');
  }
}
