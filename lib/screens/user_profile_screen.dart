import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? _switchingTo; // role key being switched to

  Future<void> _switchRole(AppUser user, String newRole) async {
    setState(() => _switchingTo = newRole);
    try {
      await AuthService.updateCurrentRole(user.uid, newRole);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
          context, AuthService.routeForRole(newRole));
    } finally {
      if (mounted) setState(() => _switchingTo = null);
    }
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final primary = Theme.of(context).primaryColor;

    return StreamBuilder<AppUser?>(
      stream: AuthService.getUserStream(uid),
      builder: (context, snap) {
        final user = snap.data;
        final isLoading = snap.connectionState == ConnectionState.waiting;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Profile',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: primary),
                onPressed: () {},
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // ── Avatar & Name ─────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primary
                                        .withAlpha((0.12 * 255).round()),
                                    border: Border.all(
                                        color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withAlpha((0.1 * 255).round()),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.person_rounded,
                                      size: 54, color: primary),
                                ),
                                // Role badge
                                if (user != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: Text(
                                      AppUser.roleLabel(user.currentRole)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name
                                  : 'RentEase User',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ??
                                  FirebaseAuth
                                      .instance.currentUser?.email ??
                                  '',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Role Switch Card ──────────────────────────────────
                      if (user != null && user.roles.length > 1) ...[
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((0.04 * 255).round()),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.swap_horiz_rounded,
                                        color: primary, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Switch Role',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...user.roles.map((role) {
                                  final isActive =
                                      role == user.currentRole;
                                  final isSwitching =
                                      _switchingTo == role;
                                  return GestureDetector(
                                    onTap: isActive || _switchingTo != null
                                        ? null
                                        : () => _switchRole(user, role),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      margin: const EdgeInsets.only(
                                          bottom: 10),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? primary.withAlpha(
                                                (0.1 * 255).round())
                                            : Colors.grey.shade50,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isActive
                                              ? primary
                                              : Colors.grey.shade200,
                                          width: isActive ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _roleIcon(role),
                                            color: isActive
                                                ? primary
                                                : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              AppUser.roleLabel(role),
                                              style: TextStyle(
                                                fontWeight: isActive
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isActive
                                                    ? primary
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (isActive)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: primary,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20),
                                              ),
                                              child: const Text(
                                                'ACTIVE',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          if (isSwitching)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                      strokeWidth: 2),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Stats ─────────────────────────────────────────────
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            _statCard('0', 'Listings', isPrimary: false),
                            const SizedBox(width: 12),
                            _statCard('0', 'Active', isPrimary: true),
                            const SizedBox(width: 12),
                            _statCard('0', 'Inquiries', isPrimary: false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Settings Menu ─────────────────────────────────────
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withAlpha((0.03 * 255).round()),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              _settingsTile(
                                  Icons.manage_accounts_outlined,
                                  'Account Settings'),
                              _settingsTile(
                                  Icons.notifications_active_outlined,
                                  'Notifications'),
                              _settingsTile(
                                  Icons.verified_user_outlined,
                                  'Privacy & Security'),
                              _settingsTile(
                                  Icons.help_center_outlined,
                                  'Help & Support'),
                              _settingsTile(
                                  Icons.info_outline, 'About App'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Logout ────────────────────────────────────────────
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Version 1.0.0 • RentEase',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _statCard(String value, String label, {required bool isPrimary}) {
    final primary = Theme.of(context).primaryColor;
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isPrimary ? primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(color: Colors.grey.shade200),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: primary.withAlpha((0.3 * 255).round()),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isPrimary ? Colors.white : primary,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: isPrimary ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black54, size: 20),
      ),
      title: Text(title,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'landlord':
        return Icons.real_estate_agent_rounded;
      case 'property_manager':
        return Icons.apartment_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}
