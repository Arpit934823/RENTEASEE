import 'package:flutter/material.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String? _selectedType;

  final List<Map<String, dynamic>> _userTypes = [
    {
      'type': 'Tenant',
      'icon': Icons.person_rounded,
      'description': 'Looking for a place to rent.',
    },
    {
      'type': 'Landlord',
      'icon': Icons.real_estate_agent_rounded,
      'description': 'Managing owned properties.',
    },
    {
      'type': 'Property Manager',
      'icon': Icons.apartment_rounded,
      'description': 'Managing properties for others.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Account Type',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How are you planning to use RentEasee?',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Select the user type that best describes you to personalize your experience.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userTypes.length,
                  itemBuilder: (context, index) {
                    final isSelected =
                        _selectedType == _userTypes[index]['type'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).primaryColor.withAlpha((0.1 * 255).round())
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.0),
                          onTap: () {
                            setState(() {
                              _selectedType = _userTypes[index]['type'];
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _userTypes[index]['icon'],
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userTypes[index]['type'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(fontSize: 18),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _userTypes[index]['description'],
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _selectedType == null
                    ? null
                    : () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/profile_setup',
                          arguments: _selectedType,
                        );
                      },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
