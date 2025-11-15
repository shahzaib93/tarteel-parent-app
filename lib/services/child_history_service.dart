import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@immutable
class CallLogEntry {
  final String id;
  final String teacherName;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;

  const CallLogEntry({
    required this.id,
    required this.teacherName,
    required this.status,
    required this.startTime,
    required this.endTime,
  });

  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;
}

@immutable
class MessageEntry {
  final String id;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;

  const MessageEntry({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
  });
}

class ChildHistoryService {
  ChildHistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CallLogEntry>> callLogs(String childId) {
    return _firestore
        .collection('calls')
        .where('studentId', isEqualTo: childId)
        .orderBy('startTime', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CallLogEntry(
          id: doc.id,
          teacherName: _readName(data['teacherName']) ?? 'Teacher',
          status: (data['status'] as String?) ?? 'completed',
          startTime: _readTimestamp(data['startTime']) ?? DateTime.now(),
          endTime: _readTimestamp(data['endTime']),
        );
      }).toList();
    });
  }

  Stream<List<MessageEntry>> conversationMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final meta = data['metadata'];
        final senderName = _readName(data['senderName']) ??
            _readName(meta is Map<String, dynamic> ? meta['senderName'] : null) ??
            _readName(data['teacherName']) ??
            _readName(data['studentName']) ??
            (data['senderId'] as String? ?? 'User');
        final senderRole = (data['senderRole'] as String?) ??
            (data['role'] as String?) ??
            'teacher';
        return MessageEntry(
          id: doc.id,
          senderName: senderName,
          senderRole: senderRole,
          message: (data['content'] as String?) ??
              (data['message'] as String?) ??
              (data['text'] as String?) ??
              '[No content]',
          timestamp: _readTimestamp(data['timestamp']) ?? DateTime.now(),
        );
      }).toList();
    });
  }

  String? _readName(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
