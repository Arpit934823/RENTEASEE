import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class PropertyManagerDashboardScreen extends StatefulWidget {
  const PropertyManagerDashboardScreen({super.key});

  @override
  State<PropertyManagerDashboardScreen> createState() =>
      _PropertyManagerDashboardScreenState();
}

class _PropertyManagerDashboardScreenState
    extends State<PropertyManagerDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<AppUser?>(
      stream: AuthService.getUserStream(uid),
      builder: (context, snap) {
        final user = snap.data;
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'RentEase',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              if (user != null && user.roles.length > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _RoleSwitchButton(user: user),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/user_profile'),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context)
                        .primaryColor
                        .withAlpha((0.2 * 255).round()),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF13A4EC),
                        const Color(0xFF0D7CC0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF13A4EC).withAlpha((0.3 * 255).round()),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.25 * 255).round()),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.apartment_rounded,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'PROPERTY MANAGER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user != null ? 'Hello, ${user.name.split(' ').first}!' : 'Hello!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage your portfolio efficiently',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Quick Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _statCard('18', 'Properties', Icons.domain_rounded,
                          Colors.indigo),
                      const SizedBox(width: 12),
                      _statCard('142', 'Tenants', Icons.people_rounded,
                          Colors.teal),
                      const SizedBox(width: 12),
                      _statCard('6', 'Pending', Icons.pending_actions_rounded,
                          Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'QUICK ACTIONS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      _actionButton(
                          Icons.add_circle_outline, 'Add Property', () {
                        Navigator.pushNamed(context, '/add_property');
                      }),
                      _actionButton(
                          Icons.chat_bubble_outline, 'Inquiries', () {
                        Navigator.pushNamed(context, '/inquiries');
                      }),
                      _actionButton(Icons.receipt_long_rounded, 'Rent Rolls',
                          () {}),
                      _actionButton(Icons.bar_chart_rounded, 'Reports', () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Managed Properties
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Managed Properties',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _propertyCard(
                        'Sunrise Apartments',
                        'Block A–F, Gomti Nagar, Lucknow',
                        '6 Units',
                        Colors.indigo.shade200,
                      ),
                      const SizedBox(height: 16),
                      _propertyCard(
                        'Green View Society',
                        'Aliganj Extension, Lucknow',
                        '12 Units',
                        Colors.teal.shade200,
                      ),
                      const SizedBox(height: 16),
                      _propertyCard(
                        'The Metro Hub',
                        'Hazratganj, Lucknow',
                        '4 Units',
                        Colors.orange.shade200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) {
              setState(() => _selectedIndex = i);
              if (i == 1) Navigator.pushNamed(context, '/inquiries');
              if (i == 2) Navigator.pushNamed(context, '/user_profile');
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline), label: 'Inquiries'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.04 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 26),
            const Spacer(),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _propertyCard(
      String name, String address, String units, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.domain_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(address,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .primaryColor
                      .withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  units,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Role switch mini-button in AppBar ─────────────────────────────────────────

class _RoleSwitchButton extends StatelessWidget {
  const _RoleSwitchButton({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Switch role',
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha((0.12 * 255).round()),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz_rounded,
                size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 4),
            Text(
              AppUser.roleLabel(user.currentRole),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onSelected: (newRole) async {
        await AuthService.updateCurrentRole(user.uid, newRole);
        if (context.mounted) {
          Navigator.pushReplacementNamed(
              context, AuthService.routeForRole(newRole));
        }
      },
      itemBuilder: (_) => user.roles
          .where((r) => r != user.currentRole)
          .map((r) => PopupMenuItem(
                value: r,
                child: Row(
                  children: [
                    Icon(_roleIcon(r), size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(AppUser.roleLabel(r)),
                  ],
                ),
              ))
          .toList(),
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
