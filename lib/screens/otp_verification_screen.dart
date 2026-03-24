import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Shown after sign-up. The user must click the link in their email to proceed.
/// Receives the role + name that were collected during sign-up so a Firestore
/// profile can be created once verification is confirmed.
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String role;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.name,
    required this.role,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  bool _verified = false;
  int _resendCooldown = 0;
  Timer? _pollTimer;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Start polling every 4 seconds to detect when user verifies their email
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkVerification());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    if (_isChecking || _verified) return;
    setState(() => _isChecking = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Reload to get fresh emailVerified status from Firebase
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed != null && refreshed.emailVerified) {
        _pollTimer?.cancel();
        setState(() {
          _verified = true;
          _isChecking = false;
        });
        await _completeSignup(refreshed);
      }
    } catch (_) {
      // Silently ignore reload failures (network issues etc.)
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _completeSignup(User user) async {
    try {
      // Update display name if provided
      if (widget.name.isNotEmpty) {
        await user.updateDisplayName(widget.name);
      }

      // Create Firestore profile
      await AuthService.createUser(
        uid: user.uid,
        email: widget.email,
        name: widget.name,
        roles: [widget.role],
        currentRole: widget.role,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(
          context, AuthService.routeForRole(widget.role));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not complete sign-up: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent! Please check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Start 60-second cooldown
      setState(() => _resendCooldown = 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) t.cancel();
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _cancelAndGoBack() async {
    // Delete the unverified account so user can try again cleanly
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {}
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
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: primary.withAlpha((0.1 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mark_email_unread_outlined,
                      size: 44, color: primary),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Verify Your Email',
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.6),
                  children: [
                    const TextSpan(
                        text: 'We sent a verification link to\n'),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                          color: primary, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                        text:
                            '\n\nClick the link in the email to activate your account. This page will update automatically.'),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Status indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _verified
                    ? Row(
                        key: const ValueKey('verified'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.green.shade600, size: 22),
                          const SizedBox(width: 8),
                          Text('Email verified! Redirecting…',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )
                    : Row(
                        key: const ValueKey('waiting'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: primary),
                          ),
                          const SizedBox(width: 10),
                          Text('Waiting for verification…',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
              ),

              const Spacer(),

              // Manual check button
              OutlinedButton.icon(
                onPressed: _isChecking ? null : _checkVerification,
                icon: _isChecking
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primary),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text("I've verified, check now"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              // Resend button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the email? ",
                      style: Theme.of(context).textTheme.bodyMedium),
                  _isResending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed:
                              _resendCooldown > 0 ? null : _resendEmail,
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
              const SizedBox(height: 16),

              // Cancel
              TextButton(
                onPressed: _cancelAndGoBack,
                child: const Text('Cancel & go back',
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
