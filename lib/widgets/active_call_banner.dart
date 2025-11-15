import 'package:flutter/material.dart';

import '../services/call_service.dart';

class ActiveCallBanner extends StatelessWidget {
  final ActiveCall call;

  const ActiveCallBanner({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 10, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Text(call.status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              Text(_formatDuration(call.startedAt), style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _participantChip(Icons.person_outline, call.childName, label: 'Student'),
              const SizedBox(width: 12),
              _participantChip(Icons.school_outlined, call.teacherName, label: 'Teacher'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _participantChip(IconData icon, String value, {required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.indigo.shade400),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: Colors.indigo.shade400, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(DateTime start) {
    final duration = DateTime.now().difference(start);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return 'Live · $minutes:$seconds';
  }
}
