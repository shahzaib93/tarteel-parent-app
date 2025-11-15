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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text(
                'Teacher: ${profile.teacherName}',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Calls', icon: Icon(Icons.call_outlined)),
              Tab(text: 'Messages', icon: Icon(Icons.message_outlined)),
            ],
          ),
        ),
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
    );
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
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
    return '$minutes:${seconds} min';
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
                color: isTeacher ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  )
                ],
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
