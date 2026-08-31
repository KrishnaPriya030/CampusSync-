import 'package:flutter/material.dart';

import '../models/organization.dart';
import '../services/admin_organization_service.dart';
import '../storage/token_storage.dart';

class AdminOrganizationsScreen extends StatefulWidget {
  const AdminOrganizationsScreen({
    super.key,
  });

  @override
  State<AdminOrganizationsScreen> createState() =>
      _AdminOrganizationsScreenState();
}

class _AdminOrganizationsScreenState
    extends State<AdminOrganizationsScreen> {
  final AdminOrganizationService _service =
      AdminOrganizationService();

  final TokenStorage _tokenStorage = TokenStorage();

  List<Organization> _organizations = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final organizations =
          await _service.getAllOrganizations(token);

      if (!mounted) return;

      setState(() {
        _organizations = organizations;
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Load organizations error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Failed to load organizations\n$e',
      );
    }
  }

  Future<void> _createOrganization() async {
    final result =
        await _showOrganizationDialog();

    if (result == null) {
      return;
    }

    await _saveOrganization(
      request: result,
    );
  }

  Future<void> _editOrganization(
    Organization organization,
  ) async {
    final result =
        await _showOrganizationDialog(
      organization: organization,
    );

    if (result == null) {
      return;
    }

    await _saveOrganization(
      organizationId: organization.id,
      request: result,
    );
  }

  Future<void> _saveOrganization({
    int? organizationId,
    required Map<String, dynamic> request,
  }) async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final Organization organization;

      if (organizationId == null) {
        organization =
            await _service.createOrganization(
          request,
          token,
        );
      } else {
        organization =
            await _service.updateOrganization(
          organizationId,
          request,
          token,
        );
      }

      if (!mounted) return;

      setState(() {
        final existingIndex =
            _organizations.indexWhere(
          (item) => item.id == organization.id,
        );

        if (existingIndex == -1) {
          _organizations.add(organization);
        } else {
          _organizations[existingIndex] =
              organization;
        }
      });

      _showMessage(
        organizationId == null
            ? 'Organization created successfully'
            : 'Organization updated successfully',
      );
    } catch (e) {
      debugPrint(
        'Save organization error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Failed to save organization\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _activate(
    Organization organization,
  ) async {
    await _changeStatus(
      organization,
      activate: true,
    );
  }

  Future<void> _deactivate(
    Organization organization,
  ) async {
    await _changeStatus(
      organization,
      activate: false,
    );
  }

  Future<void> _changeStatus(
    Organization organization, {
    required bool activate,
  }) async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final updated = activate
          ? await _service.activateOrganization(
              organization.id,
              token,
            )
          : await _service.deactivateOrganization(
              organization.id,
              token,
            );

      if (!mounted) return;

      setState(() {
        final index =
            _organizations.indexWhere(
          (item) => item.id == updated.id,
        );

        if (index != -1) {
          _organizations[index] = updated;
        }
      });

      _showMessage(
        activate
            ? 'Organization activated'
            : 'Organization deactivated',
      );
    } catch (e) {
      debugPrint(
        'Organization status error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Failed to change organization status\n$e',
      );
    }
  }

  Future<Map<String, dynamic>?> _showOrganizationDialog({
    Organization? organization,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController =
        TextEditingController(
      text: organization?.name ?? '',
    );

    final codeController =
        TextEditingController(
      text: organization?.code ?? '',
    );

    final descriptionController =
        TextEditingController(
      text: organization?.description ?? '',
    );

    String? selectedType =
        organization?.organizationType;

    try {
      return await showDialog<
          Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              return AlertDialog(
                title: Text(
                  organization == null
                      ? 'Create Organization'
                      : 'Edit Organization',
                ),
                content: SizedBox(
                  width: 430,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller:
                                nameController,
                            textCapitalization:
                                TextCapitalization
                                    .words,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Organization name',
                              prefixIcon: Icon(
                                Icons.business_outlined,
                              ),
                            ),
                            validator:
                                (value) {
                              if (value == null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Enter organization name';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          TextFormField(
                            controller:
                                codeController,
                            textCapitalization:
                                TextCapitalization
                                    .characters,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Organization code',
                              prefixIcon: Icon(
                                Icons
                                    .qr_code_rounded,
                              ),
                            ),
                            validator:
                                (value) {
                              if (value == null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Enter organization code';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          DropdownButtonFormField<
                              String>(
                            value: selectedType,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Organization type',
                              prefixIcon: Icon(
                                Icons
                                    .category_outlined,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value:
                                    'COLLEGE',
                                child: Text(
                                  'College',
                                ),
                              ),
                              DropdownMenuItem(
                                value:
                                    'UNIVERSITY',
                                child: Text(
                                  'University',
                                ),
                              ),
                              DropdownMenuItem(
                                value:
                                    'COMPANY',
                                child: Text(
                                  'Company',
                                ),
                              ),
                              DropdownMenuItem(
                                value:
                                    'OTHER',
                                child: Text(
                                  'Other',
                                ),
                              ),
                            ],
                            onChanged:
                                (value) {
                              setDialogState(() {
                                selectedType =
                                    value;
                              });
                            },
                            validator:
                                (value) {
                              if (value ==
                                  null ||
                                  value.isEmpty) {
                                return 'Select organization type';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          TextFormField(
                            controller:
                                descriptionController,
                            maxLines: 3,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Description',
                              prefixIcon: Icon(
                                Icons
                                    .description_outlined,
                              ),
                              alignLabelWithHint:
                                  true,
                            ),
                            validator:
                                (value) {
                              if (value == null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Enter description';
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
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child:
                        const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!formKey
                          .currentState!
                          .validate()) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        {
                          'name':
                              nameController
                                  .text
                                  .trim(),
                          'code':
                              codeController
                                  .text
                                  .trim()
                                  .toUpperCase(),
                          'organizationType':
                              selectedType,
                          'departmentId':
                              organization
                                  ?.departmentId,
                          'description':
                              descriptionController
                                  .text
                                  .trim(),
                        },
                      );
                    },
                    child: Text(
                      organization == null
                          ? 'Create'
                          : 'Save',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      codeController.dispose();
      descriptionController.dispose();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration:
              const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF060917),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _saving ? null : _createOrganization,
        backgroundColor:
            const Color(0xFF8B5CF6),
        icon: const Icon(
          Icons.add_business_rounded,
        ),
        label: const Text(
          'Add Organization',
        ),
      ),
      body: Container(
        decoration:
            const BoxDecoration(
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
                  child:
                      CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh:
                      _loadOrganizations,
                  child: _organizations.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            110,
                          ),
                          itemCount:
                              _organizations.length,
                          separatorBuilder:
                              (_, __) =>
                                  const SizedBox(
                            height: 14,
                          ),
                          itemBuilder:
                              (context, index) {
                            return _buildOrganizationCard(
                              _organizations[
                                  index],
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
          Icons.business_outlined,
          size: 64,
          color:
              Colors.white.withOpacity(0.25),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'No organizations found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap Add Organization to create one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.50),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationCard(
    Organization organization,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.06),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFF8B5CF6,
                  ).withOpacity(0.14),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color:
                      Color(0xFFC4B5FD),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      organization.code,
                      style:
                          TextStyle(
                        color: Colors.white
                            .withOpacity(0.45),
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _statusBadge(
                organization.active,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _infoRow(
            Icons.category_outlined,
            organization
                .organizationType,
          ),

          if (organization
                  .departmentName !=
              null &&
              organization
                  .departmentName!
                  .isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(
              Icons.account_tree_outlined,
              organization
                  .departmentName!,
            ),
          ],

          const SizedBox(height: 8),

          _infoRow(
            Icons.description_outlined,
            organization.description,
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _editOrganization(
                    organization,
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label:
                      const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      organization.active
                          ? () =>
                              _deactivate(
                                organization,
                              )
                          : () =>
                              _activate(
                                organization,
                              ),
                  icon: Icon(
                    organization.active
                        ? Icons
                            .block_outlined
                        : Icons
                            .check_circle_outline,
                  ),
                  label: Text(
                    organization.active
                        ? 'Deactivate'
                        : 'Activate',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        organization.active
                            ? Colors
                                .redAccent
                            : Colors
                                .greenAccent,
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
    bool active,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? Colors.green
                .withOpacity(0.10)
            : Colors.red
                .withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: active
              ? Colors.greenAccent
              : Colors.redAccent,
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
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
            maxLines: maxLines,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}