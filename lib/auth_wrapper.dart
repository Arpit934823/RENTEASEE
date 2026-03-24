import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'screens/login_signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landlord_dashboard_screen.dart';
import 'screens/dashboards/property_manager_dashboard_screen.dart';

/// AuthWrapper is ONLY responsible for the cold-start routing decision.
/// It does NOT sign users out — that is handled by the login screen.
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

        // Logged in → fetch Firestore profile
        return StreamBuilder<AppUser?>(
          stream: AuthService.getUserStream(firebaseUser.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _SplashLoader();
            }

            final appUser = userSnap.data;

            // Logged in but no Firestore profile → show role-selection screen
            if (appUser == null) {
              return const LoginSignupScreen(needsProfile: true);
            }

            // Route to correct dashboard
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
