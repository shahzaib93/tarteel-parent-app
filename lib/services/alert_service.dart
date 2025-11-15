import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@immutable
class ParentAlert {
  final String id;
  final String childName;
  final String summary;
  final DateTime timestamp;
  final String status;
  final String severity;
  final DateTime? resolvedAt;
  final String reason;
  final String? content;
  final String? participantType;
  final String? type;

  const ParentAlert({
    required this.id,
    required this.childName,
    required this.summary,
    required this.timestamp,
    required this.status,
    required this.severity,
    this.resolvedAt,
    required this.reason,
    this.content,
    this.participantType,
    this.type,
  });
}

class AlertService with ChangeNotifier {
  AlertService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  List<ParentAlert> _alerts = const [];
  bool _loading = false;
  String? _error;

  List<ParentAlert> get alerts => _alerts;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAlerts({List<String>? childIds}) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

      final idsToQuery = childIds?.where((id) => id.isNotEmpty).toList();

      if (idsToQuery != null && idsToQuery.isNotEmpty) {
        for (final childId in idsToQuery) {
          final snapshot = await _firestore
              .collection('safety_alerts')
              .where('studentId', isEqualTo: childId)
              .limit(30)
              .get();
          docs.addAll(snapshot.docs);
        }
      }

      if (docs.isEmpty) {
        final snapshot = await _firestore
            .collection('safety_alerts')
            .where('parentId', whereIn: [user.uid, user.email])
            .limit(30)
            .get();
        docs.addAll(snapshot.docs);
      }

      docs.sort((a, b) {
        final at = _readTimestamp(a.data()['timestamp']);
        final bt = _readTimestamp(b.data()['timestamp']);
        return bt.compareTo(at);
      });

      _alerts = docs.take(30).map((doc) {
        final data = doc.data();
        final childName = data['childDisplayName'] ?? data['childName'] ?? 'Child';
        final summary = data['summary'] ?? data['reason'] ?? 'Alert triggered.';
        final timestamp = _readTimestamp(data['timestamp']);
        final status = (data['status'] as String?) ??
            (data['resolvedAt'] != null ? 'resolved' : 'active');
        final severity = (data['severity'] as String?) ?? 'medium';
        final resolvedAt = _readTimestamp(data['resolvedAt']);
        final reason = data['reason'] as String? ?? summary;
        final content = data['content'] as String? ?? data['transcript'] as String?;
        final participantType = data['participantType'] as String?;
        final type = data['type'] as String?;
        return ParentAlert(
          id: doc.id,
          childName: childName,
          summary: summary,
          timestamp: timestamp,
          status: status,
          severity: severity,
          resolvedAt: resolvedAt,
          reason: reason,
          content: content,
          participantType: participantType,
          type: type,
        );
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  DateTime _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

}
