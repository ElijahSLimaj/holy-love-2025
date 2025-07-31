import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool isNewUser;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.isNewUser = false,
  });

  static const empty = AuthUser(id: '', email: '');

  bool get isEmpty => this == AuthUser.empty;
  bool get isNotEmpty => this != AuthUser.empty;
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of [AuthUser] which will emit the current user when
  /// the authentication state changes.
  ///
  /// Emits [AuthUser.empty] if the user is not authenticated.
  Stream<AuthUser> get user {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return AuthUser.empty;
      return await _mapFirebaseUserToAuthUser(firebaseUser);
    });
  }

  /// Returns the current cached user.
  /// Defaults to [AuthUser.empty] if there is no cached user.
  AuthUser get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return AuthUser.empty;
    
    // Note: This won't have the isNewUser flag for cached users
    return AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
    );
  }

  /// Signs in with Google and returns the [AuthUser].
  /// 
  /// Throws a [SignInWithGoogleFailure] if an exception occurs.
  Future<AuthUser> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw SignInWithGoogleCancelled();
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw SignInWithGoogleFailure('Failed to create user');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      // Create or update user document in Firestore
      await _createOrUpdateUserDocument(firebaseUser, isNewUser);
      
      return AuthUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        isNewUser: isNewUser,
      );
    } on FirebaseAuthException catch (e) {
      throw SignInWithGoogleFailure(e.message ?? 'An unknown error occurred');
    } catch (e) {
      throw SignInWithGoogleFailure(e.toString());
    }
  }

  /// Signs in with email and password and returns the [AuthUser].
  /// 
  /// Throws a [SignInWithEmailAndPasswordFailure] if an exception occurs.
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw SignInWithEmailAndPasswordFailure('Failed to sign in');
      }

      return await _mapFirebaseUserToAuthUser(firebaseUser);
    } on FirebaseAuthException catch (e) {
      throw SignInWithEmailAndPasswordFailure(
        e.message ?? 'An unknown error occurred',
      );
    } catch (e) {
      throw SignInWithEmailAndPasswordFailure(e.toString());
    }
  }

  /// Creates a new user account with email and password and returns the [AuthUser].
  /// 
  /// Throws a [SignUpWithEmailAndPasswordFailure] if an exception occurs.
  Future<AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw SignUpWithEmailAndPasswordFailure('Failed to create user');
      }

      // Create user document in Firestore
      await _createOrUpdateUserDocument(firebaseUser, true);

      return AuthUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        isNewUser: true,
      );
    } on FirebaseAuthException catch (e) {
      throw SignUpWithEmailAndPasswordFailure(
        e.message ?? 'An unknown error occurred',
      );
    } catch (e) {
      throw SignUpWithEmailAndPasswordFailure(e.toString());
    }
  }

  /// Signs out the current user.
  /// 
  /// Throws a [SignOutFailure] if an exception occurs.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw SignOutFailure(e.toString());
    }
  }

  /// Maps a [User] from Firebase Auth to an [AuthUser].
  Future<AuthUser> _mapFirebaseUserToAuthUser(User firebaseUser) async {
    // Check if user has completed onboarding
    final userDoc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    
    final isNewUser = !userDoc.exists || 
                     userDoc.data()?.containsKey('profileComplete') != true;
    
    return AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      isNewUser: isNewUser,
    );
  }

  /// Creates or updates user document in Firestore
  Future<void> _createOrUpdateUserDocument(User firebaseUser, bool isNewUser) async {
    final userRef = _firestore.collection('users').doc(firebaseUser.uid);
    
    final userData = <String, dynamic>{
      'email': firebaseUser.email,
      'displayName': firebaseUser.displayName,
      'photoURL': firebaseUser.photoURL,
      'lastSignIn': FieldValue.serverTimestamp(),
    };

    if (isNewUser) {
      userData.addAll({
        'createdAt': FieldValue.serverTimestamp(),
        'profileComplete': false,
      });
      await userRef.set(userData);
    } else {
      await userRef.update(userData);
    }
  }
}

/// Base class for authentication failures.
abstract class AuthFailure implements Exception {
  const AuthFailure(this.message);

  /// The associated error message.
  final String message;

  @override
  String toString() => message;
}

/// Thrown during the sign in with google process if a failure occurs.
class SignInWithGoogleFailure extends AuthFailure {
  const SignInWithGoogleFailure(super.message);
}

/// Thrown during the sign in with google process if cancelled by user.
class SignInWithGoogleCancelled extends AuthFailure {
  const SignInWithGoogleCancelled() : super('Google sign in was cancelled');
}

/// Thrown during the sign in with email and password process if a failure occurs.
class SignInWithEmailAndPasswordFailure extends AuthFailure {
  const SignInWithEmailAndPasswordFailure(super.message);
}

/// Thrown during the sign up with email and password process if a failure occurs.
class SignUpWithEmailAndPasswordFailure extends AuthFailure {
  const SignUpWithEmailAndPasswordFailure(super.message);
}

/// Thrown during the sign out process if a failure occurs.
class SignOutFailure extends AuthFailure {
  const SignOutFailure(super.message);
}