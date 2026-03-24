import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Shown after sign-up, while the user is SIGNED OUT.
/// User must click the link in their email, then press "I've verified".
/// We sign in, check emailVerified, create the Firestore profile, and proceed.
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final String role;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  bool _isChecking  = false;
  bool _isResending = false;
  bool _verified    = false;
  int  _resendCooldown = 60;
  Timer? _cooldownTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 60-second cooldown before user can request another email
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Sign in, check emailVerified, then:
  ///  - if verified  → create profile → navigate to dashboard
  ///  - if not verified → sign out immediately and show error
  Future<void> _checkVerification() async {
    if (_isChecking || _verified) return;
    setState(() { _isChecking = true; _errorMessage = null; });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      final user = cred.user;
      if (user == null) throw Exception('Could not sign in');

      // Force-refresh to get latest emailVerified from Firebase servers
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser!;

      if (!refreshed.emailVerified) {
        // Not verified yet — sign back out (AuthWrapper would do this too,
        // but we proactively avoid the flash by doing it ourselves first)
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() {
            _isChecking = false;
            _errorMessage =
                'Email not verified yet. Please click the link in your inbox and try again.';
          });
        }
        return;
      }

      // ✅ Verified — complete sign-up
      setState(() { _verified = true; _isChecking = false; });

      if (widget.name.isNotEmpty) {
        await refreshed.updateDisplayName(widget.name);
      }
      await AuthService.createUser(
        uid: refreshed.uid,
        email: widget.email,
        name: widget.name,
        roles: [widget.role],
        currentRole: widget.role,
      );

      if (!mounted) return;
      // AuthWrapper will now see a verified, profiled user and route correctly
      Navigator.pushReplacementNamed(
          context, AuthService.routeForRole(widget.role));
    } on FirebaseAuthException catch (e) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = e.message ?? 'Authentication failed';
        });
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Something went wrong: $e';
        });
      }
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    setState(() { _isResending = true; _errorMessage = null; });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      await cred.user!.sendEmailVerification();
      // Sign out immediately so AuthWrapper doesn't bounce the unverified user
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✉️ Verification email resent! Check your inbox.'),
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _resendCooldown = 60);
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) t.cancel();
        });
      });
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() => _errorMessage = 'Failed to resend: $e');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _cancelAndGoBack() async {
    // Delete the unverified account so the email can be reused
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      await cred.user?.delete();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login_signup');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).textTheme.titleLarge?.color),
          onPressed: _cancelAndGoBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Icon
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _verified
                      ? Container(
                          key: const ValueKey('done'),
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle_outline_rounded,
                              size: 48, color: Colors.green.shade600))
                      : Container(
                          key: const ValueKey('waiting'),
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            color: primary.withAlpha((0.10 * 255).round()),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.mark_email_unread_outlined,
                              size: 44, color: primary)),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                _verified ? 'Email Verified! 🎉' : 'Verify Your Email',
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              if (!_verified) ...[
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.6),
                    children: [
                      const TextSpan(text: 'We sent a verification link to\n'),
                      TextSpan(
                        text: widget.email,
                        style: TextStyle(
                            color: primary, fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                          text:
                              '\n\nClick the link in the email, then press the button below.'),
                    ],
                  ),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Main CTA — "I've verified, let me in"
              ElevatedButton.icon(
                onPressed: _isChecking || _verified ? null : _checkVerification,
                icon: _isChecking
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified_user_outlined),
                label: Text(
                  _isChecking
                      ? 'Checking…'
                      : _verified
                          ? 'Redirecting…'
                          : "✓ I've verified my email",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              // Resend row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't get the email? ",
                      style: Theme.of(context).textTheme.bodyMedium),
                  _isResending
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: _resendCooldown > 0 ? null : _resendEmail,
                          child: Text(
                            _resendCooldown > 0
                                ? 'Resend in ${_resendCooldown}s'
                                : 'Resend',
                            style: TextStyle(
                                color: _resendCooldown > 0
                                    ? Colors.grey
                                    : primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: _cancelAndGoBack,
                child: const Text('Cancel & use a different email',
                    style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
