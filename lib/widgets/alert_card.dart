import 'package:flutter/material.dart';
import '../services/alert_service.dart';

class AlertCard extends StatelessWidget {
  final ParentAlert alert;

  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(alert.severity);
    final isResolved = alert.status.toLowerCase() == 'resolved';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isResolved ? const Color(0xFFF8FAFF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: severityColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: severityColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${alert.childName} • ${_formatTime(alert.timestamp)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isResolved ? Colors.green.withOpacity(0.15) : severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isResolved ? 'Resolved' : alert.severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isResolved ? Colors.green.shade700 : severityColor,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.summary,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 8),
          _infoRow('Reason', alert.reason),
          if (alert.type != null) _infoRow('Type', alert.type!),
          if (alert.participantType != null) _infoRow('Participant', alert.participantType!),
          if (alert.content != null && alert.content!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${alert.content}"',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          if (isResolved && alert.resolvedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Resolved ${_formatTime(alert.resolvedAt!)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hrs ago';
    }
    return '${difference.inDays} days ago';
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFE11D48);
      case 'medium':
        return const Color(0xFFF97316);
      case 'low':
        return const Color(0xFF0EA5E9);
      default:
        return Colors.redAccent;
    }
  }

  Widget _infoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
