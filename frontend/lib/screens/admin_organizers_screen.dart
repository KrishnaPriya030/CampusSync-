import 'package:flutter/material.dart';

import '../models/organizer.dart';
import '../models/organization.dart';
import '../services/admin_organizer_service.dart';
import '../services/admin_organization_service.dart';
import '../storage/token_storage.dart';
import 'package:flutter/services.dart';
class AdminOrganizersScreen extends StatefulWidget {
  const AdminOrganizersScreen({
    super.key,
  });

  @override
  State<AdminOrganizersScreen> createState() =>
      _AdminOrganizersScreenState();
}

class _AdminOrganizersScreenState
    extends State<AdminOrganizersScreen> {
  final AdminOrganizerService _organizerService =
      AdminOrganizerService();

  final AdminOrganizationService _organizationService =
      AdminOrganizationService();

  final TokenStorage _tokenStorage = TokenStorage();

  List<Organizer> _organizers = [];
  List<Organization> _organizations = [];

  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final results = await Future.wait([
        _organizerService.getAllOrganizers(token),
        _organizationService.getAllOrganizations(token),
      ]);

      if (!mounted) return;

      setState(() {
        _organizers =
            results[0] as List<Organizer>;
        _organizations =
            results[1] as List<Organization>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Admin organizers load error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Failed to load organizers\n$e',
      );
    }
  }

  Future<void> _createOrganizer() async {
    final result = await showDialog<_OrganizerFormResult>(
      context: context,
      builder: (_) {
        return _OrganizerFormDialog(
          organizations: _organizations,
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final request = CreateOrganizerRequest(
        name: result.name,
        email: result.email,
        phoneNumber: result.phoneNumber,
        organizationId: result.organizationId,
        designation: result.designation,
      );

      final response =
          await _organizerService.createOrganizer(
        request,
        token,
      );

      if (!mounted) return;

      await _showActivationLinkDialog(
        response.activationLink,
      );

      await _loadData();
    } catch (e) {
      debugPrint('Create organizer error: $e');

      if (!mounted) return;

      _showMessage(
        'Failed to create organizer\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

 Future<void> _showActivationLinkDialog(
  String link,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Organizer Created Successfully',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share this activation link with the organizer. '
              'They can open it on their Android phone to set '
              'their own password.',
            ),

            const SizedBox(height: 16),

            if (link.isEmpty)
              const Text(
                'No activation link was returned by the server.',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  link,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (link.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: link),
                );

                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Activation link copied',
                      ),
                    ),
                  );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy Link'),
            ),

          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Done'),
          ),
        ],
      );
    },
  );
}
  Future<void> _activateOrganizer(
    Organizer organizer,
  ) async {
    await _changeStatus(
      organizer,
      activate: true,
    );
  }

  Future<void> _deactivateOrganizer(
    Organizer organizer,
  ) async {
    await _changeStatus(
      organizer,
      activate: false,
    );
  }

  Future<void> _changeStatus(
    Organizer organizer, {
    required bool activate,
  }) async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final updated = activate
          ? await _organizerService.activateOrganizer(
              organizer.id,
              token,
            )
          : await _organizerService.deactivateOrganizer(
              organizer.id,
              token,
            );

      if (!mounted) return;

      setState(() {
        final index = _organizers.indexWhere(
          (item) => item.id == updated.id,
        );

        if (index != -1) {
          _organizers[index] = updated;
        }
      });

      _showMessage(
        activate
            ? 'Organizer activated'
            : 'Organizer deactivated',
      );
    } catch (e) {
      debugPrint(
        'Organizer status error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Failed to change organizer status\n$e',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060917),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _createOrganizer,
        backgroundColor: const Color(0xFF8B5CF6),
        icon: _creating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.person_add_rounded),
        label: Text(
          _creating
              ? 'Creating...'
              : 'Add Organizer',
        ),
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
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _organizers.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            100,
                          ),
                          itemCount: _organizers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _buildOrganizerCard(
                              _organizers[index],
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.groups_outlined,
          size: 64,
          color: Colors.white.withOpacity(0.25),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'No organizers found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap Add Organizer to create one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerCard(
    Organizer organizer,
  ) {
    final status =
        organizer.accountStatus.toUpperCase();

    final isActive = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6)
                      .withOpacity(0.14),
                ),
                child: const Icon(
                  Icons.person_rounded,
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
                      organizer.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      organizer.email,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              _statusBadge(
                status,
                isActive,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _infoRow(
            Icons.business_outlined,
            organizer.organizationName,
          ),

          const SizedBox(height: 8),

          _infoRow(
            Icons.work_outline_rounded,
            organizer.designation,
          ),

          if (organizer.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(
              Icons.phone_outlined,
              organizer.phoneNumber,
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isActive
                      ? null
                      : () =>
                          _activateOrganizer(
                            organizer,
                          ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                  ),
                  label: const Text(
                    'Activate',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !isActive
                      ? null
                      : () =>
                          _deactivateOrganizer(
                            organizer,
                          ),
                  icon: const Icon(
                    Icons.block_outlined,
                  ),
                  label: const Text(
                    'Deactivate',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String status,
    bool active,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withOpacity(0.10)
            : Colors.orange.withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(
        status.isEmpty ? 'UNKNOWN' : status,
        style: TextStyle(
          color: active
              ? Colors.greenAccent
              : Colors.orangeAccent,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color:
              Colors.white.withOpacity(0.35),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty
                ? 'Not provided'
                : text,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrganizerFormResult {
  final String name;
  final String email;
  final String phoneNumber;
  final int organizationId;
  final String designation;

  const _OrganizerFormResult({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.organizationId,
    required this.designation,
  });
}

class _OrganizerFormDialog extends StatefulWidget {
  final List<Organization> organizations;

  const _OrganizerFormDialog({
    required this.organizations,
  });

  @override
  State<_OrganizerFormDialog> createState() =>
      _OrganizerFormDialogState();
}

class _OrganizerFormDialogState
    extends State<_OrganizerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _designationController =
      TextEditingController();

  int? _organizationId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_organizationId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an organization',
          ),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      _OrganizerFormResult(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber:
            _phoneController.text.trim(),
        organizationId: _organizationId!,
        designation:
            _designationController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Create Organizer',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    final email =
                        value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Enter email';
                    }

                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller:
                      _phoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration:
                      const InputDecoration(
                    labelText: 'Phone number',
                  ),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: _organizationId,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(
                    labelText: 'Organization',
                  ),
                  items: widget.organizations
                      .where(
                        (organization) =>
                            organization.active,
                      )
                      .map(
                        (organization) =>
                            DropdownMenuItem<int>(
                          value:
                              organization.id,
                          child: Text(
                            organization.name,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _organizationId =
                          value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Select organization';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller:
                      _designationController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Designation',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter designation';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}