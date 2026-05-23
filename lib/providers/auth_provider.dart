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
      
      // Create user account - this automatically signs the user in
      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, 
          password: password
        );
      } catch (e) {
        // Type cast hatası veya diğer platform hatalarını yakala
        print('Firebase Auth platform hatası: $e');
        // Auth state listener'dan gelen güncellemeyi bekle
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Kullanıcının gerçekten kayıt olup olmadığını kontrol et
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          _status = AuthStatus.Authenticated;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Hesap oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.';
          _status = AuthStatus.Unauthenticated;
          notifyListeners();
          return false;
        }
      }
      
      // Verify user is signed in and update status immediately
      if (userCredential != null) {
        _status = AuthStatus.Authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Hesap oluşturulurken bir hata oluştu.';
        _status = AuthStatus.Unauthenticated;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Hesap oluşturulurken bir hata oluştu.';
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      // Genel hata yakalama
      print('Beklenmeyen hata: $e');
      _errorMessage = 'Hesap oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.';
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
      
      // Firebase Auth işlemini try-catch ile yakalıyoruz
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email, 
          password: password
        );
      } catch (e) {
        // Type cast hatası veya diğer platform hatalarını yakala
        print('Firebase Auth platform hatası: $e');
        // Auth state listener'dan gelen güncellemeyi bekle
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Kullanıcının gerçekten giriş yapıp yapmadığını kontrol et
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          _status = AuthStatus.Authenticated;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Giriş yapılırken bir hata oluştu. Lütfen tekrar deneyin.';
          _status = AuthStatus.Unauthenticated;
          notifyListeners();
          return false;
        }
      }
      
      // Verify user is signed in and update status immediately
      if (userCredential != null) {
        _status = AuthStatus.Authenticated;
        notifyListeners();
        return true;
      } else {
        // Eğer userCredential null ise, currentUser'ı kontrol et
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          _status = AuthStatus.Authenticated;
          notifyListeners();
          return true;
        }
        _status = AuthStatus.Unauthenticated;
        _errorMessage = 'Giriş yapılamadı.';
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Giriş yapılırken bir hata oluştu.';
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      // Genel hata yakalama
      print('Beklenmeyen hata: $e');
      _errorMessage = 'Giriş yapılırken bir hata oluştu. Lütfen tekrar deneyin.';
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

  // Anonymous sign-in to support onboarding before user registers
  Future<bool> signInAnonymously() async {
    try {
      if (_auth.currentUser != null) {
        _status = AuthStatus.Authenticated;
        notifyListeners();
        return true;
      }
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;
      _status = user != null ? AuthStatus.Authenticated : AuthStatus.Unauthenticated;
      notifyListeners();
      return user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Anonim oturum açılamadı';
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Anonim oturumda beklenmeyen hata';
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _status = AuthStatus.Unauthenticated;
    notifyListeners();
  }
  Future<bool> deleteUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Not: Kullanıcının son oturum açma zamanı eskiyse, Firebase sensitive işlem için
      // yeniden giriş isteyebilir (requiresRecentLogin).
      // Basitlik olması adına şimdilik direkt silmeyi deniyoruz.
      await user.delete();
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print("Kullanıcı silinemedi (Auth): $e");
      if (e.code == 'requires-recent-login') {
        _errorMessage = "Güvenlik gereği hesabı silmek için çıkış yapıp tekrar girmelisiniz.";
      } else {
        _errorMessage = "Hesap silinemedi: ${e.message}";
      }
      notifyListeners();
      return false;
    } catch (e) {
      print("Kullanıcı silinemedi (Bilinmeyen): $e");
      _errorMessage = "Beklenmeyen bir hata oluştu.";
      notifyListeners();
      return false;
    }
  }
}