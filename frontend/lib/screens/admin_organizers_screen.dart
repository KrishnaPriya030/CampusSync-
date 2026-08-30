import 'dart:ui';

import 'package:flutter/material.dart';

class AdminOrganizersScreen extends StatefulWidget {
  const AdminOrganizersScreen({super.key});

  @override
  State<AdminOrganizersScreen> createState() =>
      _AdminOrganizersScreenState();
}

class _AdminOrganizersScreenState
    extends State<AdminOrganizersScreen> {
  final List<Map<String, String>> organizers = [
    {
      'name': 'Alex Johnson',
      'email': 'alex@example.com',
      'organization': 'Computer Science Department',
      'status': 'ACTIVE',
    },
    {
      'name': 'Sarah Williams',
      'email': 'sarah@example.com',
      'organization': 'Student Activities Club',
      'status': 'PENDING',
    },
  ];

  void _showCreateOrganizerDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111936),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Create Organizer',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                controller: nameController,
                label: 'Name',
              ),
              const SizedBox(height: 14),
              _field(
                controller: emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim();

                if (name.isEmpty || email.isEmpty) return;

                setState(() {
                  organizers.add({
                    'name': name,
                    'email': email,
                    'organization': 'Not assigned',
                    'status': 'PENDING',
                  });
                });

                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.55),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060917),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOrganizerDialog,
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Create Organizer'),
      ),
      body: Container(
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
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B5CF6)
                        .withOpacity(0.13),
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -100,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B82F6)
                        .withOpacity(0.08),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  90,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Organizers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage CampusSync organizers',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.50),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: ListView.separated(
                        itemCount: organizers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _organizerCard(
                            organizers[index],
                            index,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _organizerCard(
    Map<String, String> organizer,
    int index,
  ) {
    final isActive = organizer['status'] == 'ACTIVE';

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6)
                      .withOpacity(0.14),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFFC4B5FD),
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      organizer['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      organizer['email'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      organizer['organization'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.10)
                            : Colors.orange.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        organizer['status'] ?? '',
                        style: TextStyle(
                          color: isActive
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white.withOpacity(0.55),
                ),
                color: const Color(0xFF111936),
                onSelected: (value) {
                  if (value == 'activate') {
                    setState(() {
                      organizers[index]['status'] = 'ACTIVE';
                    });
                  }

                  if (value == 'delete') {
                    setState(() {
                      organizers.removeAt(index);
                    });
                  }
                },
                itemBuilder: (context) => [
                  if (!isActive)
                    const PopupMenuItem(
                      value: 'activate',
                      child: Text(
                        'Activate',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}