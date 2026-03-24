import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'signup_state.dart';
import 'screens/login_signup_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landlord_dashboard_screen.dart';
import 'screens/dashboards/property_manager_dashboard_screen.dart';

/// AuthWrapper is the single routing authority for the entire app.
///
/// Routing rules:
///   1. Waiting for auth  → SplashLoader
///   2. No user           → LoginSignupScreen
///   3. User, NOT verified, SignupState pending → OtpVerificationScreen
///   4. User, NOT verified, no pending state   → sign out + SplashLoader
///   5. User verified, no Firestore profile    → LoginSignupScreen(needsProfile)
///   6. User verified, has profile             → role dashboard
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // 1. Still connecting
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        final firebaseUser = authSnap.data;

        // 2. Not logged in
        if (firebaseUser == null) {
          return const LoginSignupScreen();
        }

        // 3 & 4. Logged in but email NOT verified
        if (!firebaseUser.emailVerified) {
          if (SignupState.hasPending) {
            // Active sign-up flow — show the verification screen
            return OtpVerificationScreen(
              email:    SignupState.email!,
              password: SignupState.password!,
              name:     SignupState.name!,
              role:     SignupState.role!,
            );
          }
          // Stale / unexpected unverified session — kill it
          Future.microtask(() => FirebaseAuth.instance.signOut());
          return const _SplashLoader();
        }

        // 5 & 6. Verified — fetch Firestore profile
        return StreamBuilder<AppUser?>(
          stream: AuthService.getUserStream(firebaseUser.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _SplashLoader();
            }

            final appUser = userSnap.data;

            if (appUser == null) {
              // Verified auth account but no profile doc yet
              return const LoginSignupScreen(needsProfile: true);
            }

            switch (appUser.currentRole) {
              case 'landlord':
                return const LandlordDashboardScreen();
              case 'property_manager':
                return const PropertyManagerDashboardScreen();
              default:
                return const HomeScreen();
            }
          },
        );
      },
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13A4EC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_work_rounded, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'RentEase',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
