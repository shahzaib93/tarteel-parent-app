import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

@immutable
class AdminAnnouncement {
  final String id;
  final String title;
  final String message;
  final String category;
  final DateTime createdAt;

  const AdminAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
  });
}

class AnnouncementService with ChangeNotifier {
  AnnouncementService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  List<AdminAnnouncement> _announcements = const [];
  bool _loading = false;
  String? _error;

  List<AdminAnnouncement> get announcements => _announcements;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAnnouncements() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      final snapshot = await _firestore
          .collection('announcements')
          .where('isActive', isEqualTo: true)
          .where('audience', arrayContainsAny: ['parents', 'all'])
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      _announcements = snapshot.docs.map((doc) {
        final data = doc.data();
        return AdminAnnouncement(
          id: doc.id,
          title: data['title'] as String? ?? 'Announcement',
          message: data['message'] as String? ?? data['body'] as String? ?? 'Stay tuned for updates.',
          category: data['category'] as String? ?? 'General',
          createdAt: _readTimestamp(data['createdAt']) ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
