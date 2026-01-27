import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Registro de usuario
  static Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Enviar email de verificación
    await credential.user?.sendEmailVerification();
    
    return credential;
  }

  // Login
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Logout
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reenviar email de verificación
  static Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Obtener usuario actual
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Verificar si el email está confirmado
  static Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Actualizar estado
      return user.emailVerified;
    }
    return false;
  }

  // Stream de cambios de autenticación
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}