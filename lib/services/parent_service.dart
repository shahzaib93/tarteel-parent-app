import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildProfile {
  final String id;
  final String name;
  final String teacherName;
  final String? teacherId;
  final String nextClassTime;
  final int unreadMessages;
  final int alerts;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.teacherId,
    required this.nextClassTime,
    required this.unreadMessages,
    required this.alerts,
  });

  ChildProfile copyWith({
    String? name,
    String? teacherName,
    String? teacherId,
    String? nextClassTime,
    int? unreadMessages,
    int? alerts,
  }) {
    return ChildProfile(
      id: id,
      name: name ?? this.name,
      teacherName: teacherName ?? this.teacherName,
      teacherId: teacherId ?? this.teacherId,
      nextClassTime: nextClassTime ?? this.nextClassTime,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      alerts: alerts ?? this.alerts,
    );
  }
}

class ParentService with ChangeNotifier {
  ParentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Map<String, String> _teacherNameCache = {};

  List<ChildProfile> _children = const [];
  bool _loading = true;
  String? _error;

  List<ChildProfile> get children => _children;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadChildren() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      final parentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!parentDoc.exists) {
        throw Exception('Parent profile not found');
      }

      final parentData = parentDoc.data() ?? <String, dynamic>{};
      List<dynamic> childrenData = (parentData['children'] as List<dynamic>? ?? []);
      final List<ChildProfile> fetched = [];

      if (childrenData.isEmpty) {
        final linkedSnapshot = await _firestore
            .collection('users')
            .where('parentIds', arrayContainsAny: [user.uid, user.email])
            .get();
        if (linkedSnapshot.docs.isNotEmpty) {
          childrenData = linkedSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'childId': doc.id,
              'displayName': data['username'] ?? data['name'] ?? doc.id,
              'teacherId': data['assignedTeacher'],
            };
          }).toList();
        }
      }

      for (final child in childrenData) {
        Map<String, dynamic>? childMeta;
        String? childId;
        String? parentLinkedTeacherId;

        if (child is String) {
          childId = child;
        } else if (child is Map<String, dynamic>) {
          childMeta = child;
          childId = child['childId'] as String? ?? child['id'] as String? ?? child['uid'] as String? ?? child['displayName'] as String?;
          parentLinkedTeacherId = child['teacherId'] as String? ?? child['assignedTeacherId'] as String?;
        }

        if (childId == null) continue;

        final childSnap = await _firestore.collection('users').doc(childId).get();
        if (!childSnap.exists) continue;
        final data = childSnap.data() ?? <String, dynamic>{};

        final childName = _resolveChildName(childMeta, data, childId);
        final teacherId = parentLinkedTeacherId ??
            childMeta?['teacherId'] as String? ??
            childMeta?['assignedTeacher'] as String? ??
            childMeta?['assignedTeacherId'] as String? ??
            data['assignedTeacher'] as String? ??
            data['teacherId'] as String?;
        final teacherName = await _resolveTeacherName(
          childMeta,
          data,
          parentLinkedTeacherId: parentLinkedTeacherId,
          overrideTeacherId: teacherId,
        );
        fetched.add(
          ChildProfile(
            id: childId,
            name: childName,
            teacherName: teacherName,
            teacherId: teacherId,
            nextClassTime: _formatNextClass(data['nextClass']),
            unreadMessages: (data['unreadMessageCount'] ?? 0) as int,
            alerts: (data['activeAlertCount'] ?? 0) as int,
          ),
        );
      }

      _children = fetched;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _formatNextClass(dynamic nextClassData) {
    if (nextClassData is Map<String, dynamic>) {
      final timestamp = nextClassData['timestamp'];
      if (timestamp is Timestamp) {
        final dt = timestamp.toDate();
        return '${dt.month}/${dt.day} • ${_pad(dt.hour)}:${_pad(dt.minute)}';
      }
      if (timestamp is String) {
        return timestamp;
      }
    }
    return '--';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  String _resolveChildName(
    Map<String, dynamic>? childMeta,
    Map<String, dynamic> childData,
    String fallbackId,
  ) {
    final candidates = <String?>[
      _firstNameMatch(childData, const [
        'displayName',
        'name',
        'fullName',
        'studentName',
        'profileName',
        'username',
      ]),
      _firstNameMatch(childData['profile'] as Map<String, dynamic>?, const ['displayName', 'name', 'fullName', 'username']),
      _firstNameMatch(childData['student'] as Map<String, dynamic>?, const ['displayName', 'name']),
      _firstNameMatch(childMeta, const [
        'displayName',
        'name',
        'fullName',
        'childName',
        'studentName',
        'childDisplayName',
        'studentDisplayName',
        'username',
      ]),
      _firstNameMatch(childMeta?['profile'] as Map<String, dynamic>?, const ['displayName', 'name', 'fullName', 'username']),
      _firstNameMatch(childMeta?['child'] as Map<String, dynamic>?, const ['displayName', 'name', 'fullName']),
      _firstNameMatch(childMeta?['student'] as Map<String, dynamic>?, const ['displayName', 'name', 'fullName']),
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return fallbackId;
  }

  Future<String> _resolveTeacherName(
    Map<String, dynamic>? childMeta,
    Map<String, dynamic> childData, {
    String? parentLinkedTeacherId,
    String? overrideTeacherId,
  }) async {
    final directName = _firstNameMatch(childMeta, const [
          'teacherName',
          'assignedTeacherName',
          'teacherDisplayName',
          'teacherFullName',
        ]) ??
        _firstNameMatch(childMeta?['teacher'] as Map<String, dynamic>?, const ['displayName', 'name', 'fullName']) ??
        _firstNameMatch(childData, const ['assignedTeacherName', 'teacherName']) ??
        _firstNameMatch(childData['teacher'] as Map<String, dynamic>?, const ['displayName', 'name', 'fullName']);
    if (directName != null && directName.trim().isNotEmpty) {
      return directName;
    }

    final teacherId = overrideTeacherId ??
        parentLinkedTeacherId ??
        childMeta?['teacherId'] as String? ??
        childMeta?['assignedTeacherId'] as String? ??
        childMeta?['linkedTeacher'] as String? ??
        childData['assignedTeacher'] as String? ??
        childData['assignedTeacherId'] as String? ??
        childData['teacher'] as String?;

    if (teacherId == null) {
      return 'Teacher';
    }

    if (_teacherNameCache.containsKey(teacherId)) {
      return _teacherNameCache[teacherId]!;
    }

    final teacherSnap = await _firestore.collection('users').doc(teacherId).get();
    if (!teacherSnap.exists) {
      return 'Teacher';
    }

    final data = teacherSnap.data() ?? <String, dynamic>{};
    final name = _firstNameMatch(data, const ['displayName', 'name', 'fullName', 'firstName', 'profileName', 'username']) ??
        _firstNameMatch(data['profile'] as Map<String, dynamic>?, const ['displayName', 'name']) ??
        'Teacher';
    _teacherNameCache[teacherId] = name;
    return name;
  }

  String? _firstNameMatch(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
