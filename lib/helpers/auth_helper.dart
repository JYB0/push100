import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;

  static Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitialization ??= _googleSignIn.initialize();
  }

  static Future<UserCredential?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw StateError('Google Sign-In did not return an ID token.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return null;
        default:
          rethrow;
      }
    }
  }

  static Future<UserCredential?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    return await _auth.signInWithCredential(oauthCredential);
  }

  static Future<void> signOut() async {
    final user = _auth.currentUser;
    final bool isGoogleUser =
        user?.providerData.any((info) => info.providerId == 'google.com') ??
            false;

    if (isGoogleUser) {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    }

    await _auth.signOut();
  }
}
