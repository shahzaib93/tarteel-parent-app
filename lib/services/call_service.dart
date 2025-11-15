import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

@immutable
class ActiveCall {
  final String id;
  final String teacherName;
  final String childName;
  final String status;
  final DateTime startedAt;

  const ActiveCall({
    required this.id,
    required this.teacherName,
    required this.childName,
    required this.status,
    required this.startedAt,
  });
}

class CallStatusService with ChangeNotifier {
  CallStatusService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  List<ActiveCall> _activeCalls = const [];
  bool _loading = false;
  String? _error;

  List<ActiveCall> get activeCalls => _activeCalls;
  bool get loading => _loading;
  String? get error => _error;

  void startListening() {
    _subscription?.cancel();
    final user = _auth.currentUser;
    if (user == null) {
      _activeCalls = const [];
      _loading = false;
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    final query = _firestore
        .collection('call_sessions')
        .where('parentIds', arrayContains: user.uid)
        .where('status', whereIn: ['active', 'connected', 'ringing']);

    _subscription = query.snapshots().listen(
      (snapshot) {
        _activeCalls = snapshot.docs.map((doc) {
          final data = doc.data();
          return ActiveCall(
            id: doc.id,
            teacherName: _readName(data['teacherName']) ??
                _readNestedName(data['teacher']) ??
                'Teacher',
            childName: _readName(data['studentName']) ??
                _readNestedName(data['student']) ??
                'Student',
            status: (data['status'] as String?) ?? 'active',
            startedAt: _readTimestamp(data['startedAt']) ??
                _readTimestamp(data['startTime']) ??
                DateTime.now(),
          );
        }).toList();
        _loading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  String? _readName(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String? _readNestedName(dynamic data) {
    if (data is Map<String, dynamic>) {
      return _readName(data['displayName'] ?? data['name'] ?? data['fullName']);
    }
    return null;
  }

  DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
