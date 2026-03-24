import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Create or overwrite the Firestore user document.
  static Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    required List<String> roles,
    required String currentRole,
  }) async {
    await _users.doc(uid).set({
      'email': email,
      'name': name,
      'roles': roles,
      'currentRole': currentRole,
    });
  }

  /// Update only the currentRole field.
  static Future<void> updateCurrentRole(String uid, String newRole) async {
    await _users.doc(uid).update({'currentRole': newRole});
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// One-time fetch.
  static Future<AppUser?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  /// Live stream — used in Profile screen.
  static Stream<AppUser?> getUserStream(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return AppUser.fromMap(uid, snap.data()!);
    });
  }

  // ── Auth helpers ───────────────────────────────────────────────────────────

  static User? get currentUser => _auth.currentUser;

  static Future<void> signOut() => _auth.signOut();

  /// Route name for a given role key.
  static String routeForRole(String role) {
    switch (role) {
      case 'landlord':
        return '/landlord_dashboard';
      case 'property_manager':
        return '/property_manager_dashboard';
      default:
        return '/home';
    }
  }
}
