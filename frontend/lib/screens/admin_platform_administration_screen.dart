import 'package:flutter/material.dart';

class AdminPlatformAdministrationScreen
    extends StatelessWidget {
  const AdminPlatformAdministrationScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF060917),
            Color(0xFF0B1430),
            Color(0xFF171033),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),

            const Text(
              'Platform Administration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Manage CampusSync platform resources '
              'and administrative functions.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 28),

            _AdminOptionCard(
              icon: Icons.business_rounded,
              title: 'Organizations',
              description:
                  'Create, edit, activate and deactivate '
                  'organizations.',
              onTap: () {
                // Organization management is already
                // available from the Admin navigation.
              },
            ),

            const SizedBox(height: 14),

            _AdminOptionCard(
              icon: Icons.groups_rounded,
              title: 'Organizers',
              description:
                  'Manage organizer accounts and their '
                  'activation status.',
              onTap: () {
                // Organizer management is already
                // available from the Admin navigation.
              },
            ),

            const SizedBox(height: 14),

            _AdminOptionCard(
              icon: Icons.school_rounded,
              title: 'Students',
              description:
                  'Manage student accounts, academic '
                  'details and bulk imports.',
              onTap: () {
                // Student management is already
                // available from the Admin navigation.
              },
            ),

            const SizedBox(height: 14),

            _AdminOptionCard(
              icon: Icons.security_rounded,
              title: 'Account & Security',
              description:
                  'Platform authentication and account '
                  'security functions.',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Security settings are not configured yet.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            _AdminOptionCard(
              icon: Icons.info_outline_rounded,
              title: 'Platform Information',
              description:
                  'View CampusSync platform information.',
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        'CampusSync',
                      ),
                      content: const Text(
                        'CampusSync administration platform.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AdminOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFC4B5FD),
                  size: 27,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      description,
                      style: TextStyle(
                        color:
                            Colors.white.withOpacity(0.50),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}