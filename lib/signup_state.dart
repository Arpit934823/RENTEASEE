/// Holds in-memory data for a sign-up that is pending email verification.
/// Set BEFORE calling createUserWithEmailAndPassword so AuthWrapper can
/// detect the pending state and render OtpVerificationScreen directly.
class SignupState {
  static String? email;
  static String? password;
  static String? name;
  static String? role;

  static bool get hasPending => email != null;

  static void set({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    SignupState.email    = email;
    SignupState.password = password;
    SignupState.name     = name;
    SignupState.role     = role;
  }

  static void clear() {
    email = password = name = role = null;
  }
}
