import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ParentAuthService with ChangeNotifier {
  ParentAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? _error;
  String? get error => _error;
  bool _loading = false;
  bool get loading => _loading;

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'Unable to sign in');
      }

      final parentDoc = await _firestore.collection('users').doc(user.uid).get();
      final role = parentDoc.data()?['role'];

      if (role != 'parent') {
        await _auth.signOut();
        const errorMessage = 'This account is not registered as a parent';
        _error = errorMessage;
        _loading = false;
        notifyListeners();
        return {'success': false, 'error': errorMessage};
      }

      _loading = false;
      notifyListeners();
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }

      _error = errorMessage;
      _loading = false;
      notifyListeners();
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      final errorMessage = 'An unexpected error occurred';
      _error = errorMessage;
      _loading = false;
      notifyListeners();
      return {'success': false, 'error': errorMessage};
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
