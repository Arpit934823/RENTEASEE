import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'screens/login_signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landlord_dashboard_screen.dart';
import 'screens/dashboards/property_manager_dashboard_screen.dart';

/// AuthWrapper controls all cold-start and auth-state-driven routing.
///
/// Key rule: if a user is logged in but has NOT verified their email,
/// we sign them out immediately and return them to the login screen.
/// The signup OTP flow handles its own navigation and keeps the user
/// signed out while waiting for verification.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        final firebaseUser = authSnap.data;

        // Not logged in → show Login
        if (firebaseUser == null) {
          return const LoginSignupScreen();
        }

        // ── Email verification gate ──────────────────────────────────────────
        // If user is logged in but email is NOT verified, sign them out
        // immediately. This prevents new sign-up accounts from bypassing
        // the OTP verification screen.
        if (!firebaseUser.emailVerified) {
          // Sign out asynchronously — will trigger another stream event
          // that results in null user → LoginSignupScreen with a message.
          Future.microtask(() => FirebaseAuth.instance.signOut());
          return const _SplashLoader(); // Show splash while signing out
        }

        // ── Verified user: fetch their Firestore profile ─────────────────────
        return StreamBuilder<AppUser?>(
          stream: AuthService.getUserStream(firebaseUser.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _SplashLoader();
            }

            final appUser = userSnap.data;

            // Verified Auth account but no Firestore doc → create profile
            if (appUser == null) {
              return const LoginSignupScreen(needsProfile: true);
            }

            // Route to correct dashboard based on role
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
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
