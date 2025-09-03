import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Check if user is currently signed in
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      print('🔍 Google Sign-In check error: $e');
      return false;
    }
  }

  /// Sign in with Google
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      print('🔍 Starting Google Sign-In...');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        print('🔍 Google Sign-In successful: ${account.email}');
        return account;
      } else {
        print('🔍 Google Sign-In cancelled by user');
        return null;
      }
    } catch (e) {
      print('🔍 Google Sign-In error: $e');
      return null;
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    try {
      print('🔍 Signing out from Google...');
      await _googleSignIn.signOut();
      print('🔍 Google Sign-Out successful');
    } catch (e) {
      print('🔍 Google Sign-Out error: $e');
    }
  }

  /// Get current user
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      print('🔍 Get current user error: $e');
      return null;
    }
  }

  /// Get user authentication data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final account = await getCurrentUser();
      if (account != null) {
        final auth = await account.authentication;
        return {
          'id': account.id,
          'email': account.email,
          'displayName': account.displayName,
          'photoUrl': account.photoUrl,
          'accessToken': auth.accessToken,
          'idToken': auth.idToken,
        };
      }
      return null;
    } catch (e) {
      print('🔍 Get user data error: $e');
      return null;
    }
  }
}

