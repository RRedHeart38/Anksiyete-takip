import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthStatus _status = AuthStatus.Uninitialized;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  AuthProvider()
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.Unauthenticated;
    } else {
      _status = AuthStatus.Authenticated;
    }
    notifyListeners();
  }
  Future<bool> registerWithEmail(String email, String password) async {
    try {
      _status = AuthStatus.Authenticating;
      _errorMessage = null;
      notifyListeners();
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Auth state listener _onAuthStateChanged will handle status update
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _status = AuthStatus.Authenticating;
      _errorMessage = null;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      _status = AuthStatus.Authenticating;
      _errorMessage = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _status = AuthStatus.Unauthenticated;
        notifyListeners();
        return {'success': false, 'isNewUser': false};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      return {'success': true, 'isNewUser': isNewUser};

    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return {'success': false, 'isNewUser': false};
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _status = AuthStatus.Unauthenticated;
    notifyListeners();
  }
}