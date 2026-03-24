import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';

class LoginSignupScreen extends StatefulWidget {
  /// When true, the user is already authenticated in Firebase Auth
  /// but has no Firestore profile yet. Skip to role selection directly.
  final bool needsProfile;

  const LoginSignupScreen({super.key, this.needsProfile = false});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late bool _isLogin;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedRole;

  static const _roles = [
    {
      'key': 'tenant',
      'label': 'Tenant',
      'subtitle': 'Looking for a place to rent',
      'icon': Icons.person_rounded,
    },
    {
      'key': 'landlord',
      'label': 'Landlord',
      'subtitle': 'Managing owned properties',
      'icon': Icons.real_estate_agent_rounded,
    },
    {
      'key': 'property_manager',
      'label': 'Property Manager',
      'subtitle': 'Managing properties for others',
      'icon': Icons.apartment_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    // If needsProfile, the user is already signed in — jump to sign-up mode
    // (which shows role selection only) so they can complete their profile.
    _isLogin = !widget.needsProfile;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Called when the user is already signed in but needs to create their
  /// Firestore profile (role selection).
  Future<void> _createProfileForExistingUser() async {
    if (_selectedRole == null) {
      _showError('Please select your role to continue');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final fbUser = FirebaseAuth.instance.currentUser!;
      final name = _nameController.text.trim();
      if (name.isNotEmpty) await fbUser.updateDisplayName(name);

      await AuthService.createUser(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        name: name.isNotEmpty ? name : (fbUser.displayName ?? ''),
        roles: [_selectedRole!],
        currentRole: _selectedRole!,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(
          context, AuthService.routeForRole(_selectedRole!));
    } catch (e) {
      if (mounted) _showError('Could not save profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    // Special case: user already signed in, just needs Firestore profile
    if (widget.needsProfile) {
      await _createProfileForExistingUser();
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (!_isLogin && _selectedRole == null) {
      _showError('Please select your account type');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // ── Login ───────────────────────────────────────────────────────────
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;

        final appUser = await AuthService.getUser(cred.user!.uid);
        if (!mounted) return;

        if (appUser == null) {
          // Auth account exists but no Firestore doc → create profile  
          if (!mounted) return;
          setState(() {
            _isLogin = false;
            _isLoading = false;
          });
          _showError('Please select your role to complete your profile.');
          return;
        }

        Navigator.pushReplacementNamed(
            context, AuthService.routeForRole(appUser.currentRole));
      } else {
        // ── Sign-up ─────────────────────────────────────────────────────────
        final email    = _emailController.text.trim();
        final password = _passwordController.text;
        final name     = _nameController.text.trim();
        final role     = _selectedRole!;

        final cred =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Send verification email immediately after account creation
        await cred.user!.sendEmailVerification();

        // ⚠️ Sign out BEFORE navigating so AuthWrapper does NOT
        // intercept and override navigation to OtpVerificationScreen.
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        // Navigate to verification screen. Password is passed so the screen
        // can sign the user back in once email is verified.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: email,
              password: password,
              name: name,
              role: role,
            ),
          ),
        );
        return; // skip the finally-setState below
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? 'Authentication failed');
    } catch (e) {
      if (mounted) _showError('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isProfileCompletion = widget.needsProfile;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primary.withAlpha((0.1 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.home_work_rounded,
                        size: 40, color: primary),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  isProfileCompletion
                      ? 'Complete Your Profile'
                      : (_isLogin ? 'Welcome Back' : 'Create Account'),
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isProfileCompletion
                      ? 'Choose your role to get started'
                      : (_isLogin
                          ? 'Sign in to continue using RentEase'
                          : 'Sign up to get started'),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // ── Only show email/password fields when NOT in profile-completion mode ──
                if (!isProfileCompletion) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please enter your email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Name field (sign-up and profile completion)
                if (!_isLogin || isProfileCompletion) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Password field (only for normal sign-up/login)
                if (!isProfileCompletion) ...[
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Role Cards (sign-up and profile-completion mode) ──────────
                if (!_isLogin || isProfileCompletion) ...[
                  Text(
                    'I am a...',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ..._roles.map((role) {
                    final selected = _selectedRole == role['key'];
                    return GestureDetector(
                      onTap: () => setState(
                          () => _selectedRole = role['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withAlpha((0.08 * 255).round())
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                selected ? primary : Colors.grey.shade200,
                            width: selected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selected
                                  ? primary
                                      .withAlpha((0.12 * 255).round())
                                  : Colors.black
                                      .withAlpha((0.03 * 255).round()),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? primary
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                role['icon'] as IconData,
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role['label'] as String,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    role['subtitle'] as String,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(Icons.check_circle_rounded,
                                  color: primary, size: 22),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // ── Submit Button ─────────────────────────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isProfileCompletion
                              ? 'Complete Setup'
                              : (_isLogin ? 'Sign In' : 'Create Account'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 24),

                // ── Toggle (only shown for normal login/signup, not profile completion) ──
                if (!isProfileCompletion)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _isLogin = !_isLogin;
                          _selectedRole = null;
                          _formKey.currentState?.reset();
                        }),
                        child: Text(
                          _isLogin ? 'Sign Up' : 'Sign In',
                          style: TextStyle(
                              color: primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
