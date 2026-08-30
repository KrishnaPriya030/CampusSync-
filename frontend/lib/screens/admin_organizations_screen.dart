import 'dart:ui';

import 'package:flutter/material.dart';

class AdminOrganizationsScreen extends StatefulWidget {
  const AdminOrganizationsScreen({super.key});

  @override
  State<AdminOrganizationsScreen> createState() =>
      _AdminOrganizationsScreenState();
}

class _AdminOrganizationsScreenState
    extends State<AdminOrganizationsScreen> {
  final List<Map<String, String>> organizations = [
    {
      'name': 'Computer Science Department',
      'description': 'Computer science events and activities',
      'status': 'ACTIVE',
    },
    {
      'name': 'Student Activities Club',
      'description': 'Student events and campus activities',
      'status': 'ACTIVE',
    },
  ];

  void _showAddOrganizationDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111936),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Add Organization',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField(
                controller: nameController,
                label: 'Organization Name',
              ),
              const SizedBox(height: 14),
              _inputField(
                controller: descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final description =
                    descriptionController.text.trim();

                if (name.isEmpty) return;

                setState(() {
                  organizations.add({
                    'name': name,
                    'description': description,
                    'status': 'ACTIVE',
                  });
                });

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
        onPressed: _showAddOrganizationDialog,
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add),
        label: const Text('Add Organization'),
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
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B5CF6)
                        .withOpacity(0.13),
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
                      'Organizations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Manage CampusSync organizations',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.50),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Expanded(
                      child: organizations.isEmpty
                          ? _emptyState()
                          : ListView.separated(
                              itemCount: organizations.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final organization =
                                    organizations[index];

                                return _organizationCard(
                                  organization,
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

  Widget _organizationCard(
    Map<String, String> organization,
    int index,
  ) {
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Color(0xFFC4B5FD),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      organization['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        organization['status'] ?? '',
                        style: const TextStyle(
                          color: Colors.greenAccent,
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
                  if (value == 'delete') {
                    setState(() {
                      organizations.removeAt(index);
                    });
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      'Edit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent),
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 60,
            color: Colors.white.withOpacity(0.25),
          ),
          const SizedBox(height: 16),
          const Text(
            'No organizations yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first organization',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}