import 'package:flutter/material.dart';
import 'theme.dart';
import 'auth_wrapper.dart';
import 'screens/onboarding_carousel.dart';
import 'screens/login_signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_type_selection_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/landlord_dashboard_screen.dart';
import 'screens/dashboards/property_manager_dashboard_screen.dart';
import 'screens/add_property_screen.dart';
import 'screens/inquiries_screen.dart';
import 'screens/user_profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RentEaseeApp());
}

class RentEaseeApp extends StatelessWidget {
  const RentEaseeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // AuthWrapper handles auth state and routes automatically
      home: const AuthWrapper(),
      routes: {
        '/onboarding': (context) => const OnboardingCarousel(),
        '/login_signup': (context) => const LoginSignupScreen(),
        '/user_type_selection': (context) => const UserTypeSelectionScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
        '/home': (context) => const HomeScreen(),
        '/landlord_dashboard': (context) => const LandlordDashboardScreen(),
        '/property_manager_dashboard': (context) =>
            const PropertyManagerDashboardScreen(),
        '/add_property': (context) => const AddPropertyScreen(),
        '/inquiries': (context) => const InquiriesScreen(),
        '/user_profile': (context) => const UserProfileScreen(),
      },
    );
  }
}
