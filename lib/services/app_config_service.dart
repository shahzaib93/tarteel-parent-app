import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AppConfigService with ChangeNotifier {
  AppConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const List<String> _collectionCandidates = ['appConfig', 'appconfig'];
  static const String _document = 'webrtc';

  final FirebaseFirestore _firestore;
  Map<String, dynamic>? _config;
  String? _activeCollection;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  Map<String, dynamic>? get rawConfig => _config;

  Future<void> initialize() async {
    await _loadConfig();
    _subscription = _firestore
        .collection(_activeCollection ?? _collectionCandidates.first)
        .doc(_document)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _config = _normalizeConfig(snapshot.data()!);
        notifyListeners();
      }
    });
  }

  Future<void> _loadConfig() async {
    DocumentSnapshot<Map<String, dynamic>>? snapshot;
    for (final candidate in _collectionCandidates) {
      final doc = await _firestore.collection(candidate).doc(_document).get();
      if (doc.exists && doc.data() != null) {
        snapshot = doc;
        _activeCollection = candidate;
        break;
      }
    }

    if (snapshot == null) {
      throw StateError('App config document appConfig/appconfig webrtc not found');
    }

    _config = _normalizeConfig(snapshot.data()!);
    notifyListeners();
  }

  Map<String, dynamic> _normalizeConfig(Map<String, dynamic> data) {
    final turn = data['turn'] ?? data['turnServer'] ?? data['turnConfig'];
    return {
      'socketUrl': data['socketUrl'] as String?,
      'apiBaseUrl': data['apiBaseUrl'] as String?,
      'turn': _normalizeTurn(turn),
      'raw': data,
    };
  }

  Map<String, dynamic>? _normalizeTurn(dynamic turn) {
    if (turn == null) return null;
    if (turn is List) {
      if (turn.isEmpty) return null;
      final first = turn.first;
      return first is Map<String, dynamic> ? Map<String, dynamic>.from(first) : null;
    }
    if (turn is Map<String, dynamic>) {
      return Map<String, dynamic>.from(turn);
    }
    return null;
  }

  String get socketUrl {
    final url = _config?['socketUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('socketUrl missing in appconfig/webrtc');
    }
    return url;
  }

  Map<String, dynamic>? get turnConfig {
    return _config?['turn'] as Map<String, dynamic>?;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
