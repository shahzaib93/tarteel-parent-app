import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ParentAuthService with ChangeNotifier {
  ParentAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? _error;
  String? get error => _error;
  bool _loading = false;
  bool get loading => _loading;

  Future<void> signIn(String email, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Login failed';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
