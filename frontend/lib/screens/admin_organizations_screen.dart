import 'package:flutter/material.dart';

import '../models/organization.dart';
import '../services/admin_organization_service.dart';
import '../storage/token_storage.dart';
import '../widgets/campus_back_button.dart';

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

  // ============================================================
  // LOAD ORGANIZATIONS
  // ============================================================

  Future<void> _loadOrganizations() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final organizations =
          await _service.getAllOrganizations(token);

      if (!mounted) {
        return;
      }

      setState(() {
        _organizations = organizations;
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Load organizations error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Failed to load organizations\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // CREATE ORGANIZATION
  // ============================================================

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

  // ============================================================
  // EDIT ORGANIZATION
  // ============================================================

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

  // ============================================================
  // SAVE ORGANIZATION
  // ============================================================

  Future<void> _saveOrganization({
    int? organizationId,
    required Map<String, dynamic> request,
  }) async {
    if (_saving) {
      return;
    }

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

      if (!mounted) {
        return;
      }

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

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to save organization\n$e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // ACTIVATE
  // ============================================================

  Future<void> _activate(
    Organization organization,
  ) async {
    await _changeStatus(
      organization,
      activate: true,
    );
  }

  // ============================================================
  // DEACTIVATE
  // ============================================================

  Future<void> _deactivate(
    Organization organization,
  ) async {
    await _changeStatus(
      organization,
      activate: false,
    );
  }

  // ============================================================
  // CHANGE STATUS
  // ============================================================

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

      if (!mounted) {
        return;
      }

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

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to change organization status\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // ORGANIZATION FORM
  // ============================================================

  Future<Map<String, dynamic>?> _showOrganizationDialog({
    Organization? organization,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return _OrganizationFormDialog(
          organization: organization,
        );
      },
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.55),
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFC4B5FD),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: BorderSide(
          color:
              Colors.white.withOpacity(0.08),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFF8B5CF6),
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT ORGANIZATION TYPE
  // ============================================================

  String _formatOrganizationType(
    String value,
  ) {
    switch (value) {
      case 'DEPARTMENT':
        return 'Department';

      case 'CLUB':
        return 'Club';

      case 'COLLEGE':
        return 'College';

      case 'COMMITTEE':
        return 'Committee';

      default:
        return value;
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error
              ? Colors.redAccent
              : const Color(0xFF1F2937),
          duration:
              const Duration(seconds: 4),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width;

    final bool desktop = width >= 900;

    return Scaffold(
      backgroundColor:
          const Color(0xFF060917),
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
          child: RefreshIndicator(
            onRefresh: _loadOrganizations,
            color:
                const Color(0xFF8B5CF6),
            backgroundColor:
                const Color(0xFF111827),
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          Color(0xFF8B5CF6),
                    ),
                  )
                : CustomScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child:
                            _buildHeader(
                          desktop: desktop,
                        ),
                      ),

                      if (_organizations
                          .isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child:
                              _buildEmptyState(),
                        )
                      else
                        SliverPadding(
                          padding:
                              EdgeInsets.fromLTRB(
                            desktop ? 40 : 18,
                            10,
                            desktop ? 40 : 18,
                            110,
                          ),
                          sliver:
                              SliverLayoutBuilder(
                            builder:
                                (
                              context,
                              constraints,
                            ) {
                              final contentWidth =
                                  constraints
                                      .crossAxisExtent;

                              final int columns =
                                  contentWidth >=
                                          1050
                                      ? 3
                                      : contentWidth >=
                                              650
                                          ? 2
                                          : 1;

                              if (columns == 1) {
                                return SliverList(
                                  delegate:
                                      SliverChildBuilderDelegate(
                                    (
                                      context,
                                      index,
                                    ) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                          bottom: 14,
                                        ),
                                        child:
                                            _buildOrganizationCard(
                                          _organizations[
                                              index],
                                        ),
                                      );
                                    },
                                    childCount:
                                        _organizations
                                            .length,
                                  ),
                                );
                              }

                              return SliverGrid(
                                delegate:
                                    SliverChildBuilderDelegate(
                                  (
                                    context,
                                    index,
                                  ) {
                                    return _buildOrganizationCard(
                                      _organizations[
                                          index],
                                    );
                                  },
                                  childCount:
                                      _organizations
                                          .length,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      columns,
                                  crossAxisSpacing:
                                      14,
                                  mainAxisSpacing:
                                      14,
                                  childAspectRatio:
                                      columns == 3
                                          ? 1.45
                                          : 1.55,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _saving ? null : _createOrganization,
        backgroundColor:
            const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.add_business_rounded,
        ),
        label: const Text(
          'Add Organization',
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required bool desktop,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        desktop ? 40 : 18,
        desktop ? 20 : 14,
        desktop ? 40 : 18,
        14,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // BACK BUTTON
          // ------------------------------------------------------

          CampusBackButton(
            label: 'Back',
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------
          // PAGE HEADER
          // ------------------------------------------------------

          Row(
            children: [
              Container(
                width: desktop ? 52 : 46,
                height: desktop ? 52 : 46,
                decoration:
                    const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF6366F1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organizations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            desktop ? 28 : 23,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${_organizations.length} organization${_organizations.length == 1 ? '' : 's'} registered',
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.48),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Refresh',
                onPressed:
                    _loadOrganizations,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),

        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration:
                BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(
                0xFF8B5CF6,
              ).withOpacity(0.10),
            ),
            child: const Icon(
              Icons.business_outlined,
              size: 38,
              color:
                  Color(0xFFC4B5FD),
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Center(
          child: Text(
            'No organizations found',
            textAlign: TextAlign.center,
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
            'Create an organization to start managing CampusSync entities.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.50),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 22),

        Center(
          child: ElevatedButton.icon(
            onPressed:
                _createOrganization,
            icon: const Icon(
              Icons.add_business_rounded,
            ),
            label: const Text(
              'Create Organization',
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF8B5CF6),
              foregroundColor:
                  Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ORGANIZATION CARD
  // ============================================================

  Widget _buildOrganizationCard(
    Organization organization,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color:
            Colors.white.withOpacity(0.06),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.12),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
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
                decoration:
                    BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      const Color(
                    0xFF8B5CF6,
                  ).withOpacity(0.14),
                ),
                child:
                    const Icon(
                  Icons.business_rounded,
                  color:
                      Color(0xFFC4B5FD),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      organization.code,
                      style: TextStyle(
                        color: Colors
                            .white
                            .withOpacity(
                          0.45,
                        ),
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        letterSpacing:
                            0.5,
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

          const SizedBox(
            height: 16,
          ),

          _infoRow(
            Icons.category_outlined,
            _formatOrganizationType(
              organization
                  .organizationType,
            ),
          ),

          if (organization
                      .departmentName !=
                  null &&
              organization
                  .departmentName!
                  .isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            _infoRow(
              Icons.account_tree_outlined,
              organization
                  .departmentName!,
            ),
          ],

          const SizedBox(
            height: 8,
          ),

          _infoRow(
            Icons.description_outlined,
            organization.description,
            maxLines: 3,
          ),

          const SizedBox(
            height: 16,
          ),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: () =>
                      _editOrganization(
                    organization,
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Edit',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(
                      0xFFC4B5FD,
                    ),
                    side: BorderSide(
                      color: const Color(
                        0xFF8B5CF6,
                      ).withOpacity(0.35),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child:
                    OutlinedButton.icon(
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
                    side: BorderSide(
                      color: organization
                              .active
                          ? Colors.redAccent
                              .withOpacity(
                              0.30,
                            )
                          : Colors
                              .greenAccent
                              .withOpacity(
                              0.30,
                            ),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    bool active,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
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

  // ============================================================
  // INFO ROW
  // ============================================================

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
          color: Colors.white
              .withOpacity(0.35),
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

// ============================================================================
// ORGANIZATION FORM DIALOG
// ============================================================================

class _OrganizationFormDialog
    extends StatefulWidget {
  final Organization? organization;

  const _OrganizationFormDialog({
    this.organization,
  });

  @override
  State<_OrganizationFormDialog> createState() =>
      _OrganizationFormDialogState();
}

class _OrganizationFormDialogState
    extends State<_OrganizationFormDialog> {
  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _nameController;

  late final TextEditingController
      _codeController;

  late final TextEditingController
      _descriptionController;

  String? _selectedType;

  static const organizationTypes = [
    'DEPARTMENT',
    'CLUB',
    'COLLEGE',
    'COMMITTEE',
  ];

  @override
  void initState() {
    super.initState();

    final organization =
        widget.organization;

    _nameController =
        TextEditingController(
      text: organization?.name ?? '',
    );

    _codeController =
        TextEditingController(
      text: organization?.code ?? '',
    );

    _descriptionController =
        TextEditingController(
      text: organization?.description ?? '',
    );

    _selectedType =
        organization?.organizationType;

    if (_selectedType != null &&
        !organizationTypes
            .contains(_selectedType)) {
      _selectedType = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatOrganizationType(
    String value,
  ) {
    switch (value) {
      case 'DEPARTMENT':
        return 'Department';

      case 'CLUB':
        return 'Club';

      case 'COLLEGE':
        return 'College';

      case 'COMMITTEE':
        return 'Committee';

      default:
        return value;
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color:
            Colors.white.withOpacity(0.55),
      ),
      prefixIcon: Icon(
        icon,
        color:
            const Color(0xFFC4B5FD),
      ),
      filled: true,
      fillColor:
          Colors.white.withOpacity(0.05),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: BorderSide(
          color:
              Colors.white.withOpacity(0.08),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide:
            const BorderSide(
          color: Color(0xFF8B5CF6),
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide:
            const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide:
            const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    Navigator.of(context).pop({
      'name':
          _nameController.text.trim(),
      'code':
          _codeController.text
              .trim()
              .toUpperCase(),
      'organizationType':
          _selectedType,
      'departmentId':
          widget.organization?.departmentId,
      'description':
          _descriptionController.text
              .trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width;

    final dialogWidth =
        width >= 900
            ? 520.0
            : width - 32;

    final isEditing =
        widget.organization != null;

    return AlertDialog(
      backgroundColor:
          const Color(0xFF111827),
      surfaceTintColor:
          Colors.transparent,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(22),
      ),
      title: Text(
        isEditing
            ? 'Edit Organization'
            : 'Create Organization',
        style: const TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child:
              SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextFormField(
                  controller:
                      _nameController,
                  textCapitalization:
                      TextCapitalization
                          .words,
                  style:
                      const TextStyle(
                    color: Colors.white,
                  ),
                  decoration:
                      _inputDecoration(
                    label:
                        'Organization name',
                    icon: Icons
                        .business_outlined,
                  ),
                  validator: (value) =>
                      value == null ||
                              value
                                  .trim()
                                  .isEmpty
                          ? 'Enter organization name'
                          : null,
                ),

                const SizedBox(
                  height: 14,
                ),

                TextFormField(
                  controller:
                      _codeController,
                  textCapitalization:
                      TextCapitalization
                          .characters,
                  style:
                      const TextStyle(
                    color: Colors.white,
                  ),
                  decoration:
                      _inputDecoration(
                    label:
                        'Organization code',
                    icon: Icons
                        .qr_code_rounded,
                  ),
                  validator: (value) =>
                      value == null ||
                              value
                                  .trim()
                                  .isEmpty
                          ? 'Enter organization code'
                          : null,
                ),

                const SizedBox(
                  height: 14,
                ),

                DropdownButtonFormField<
                    String>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor:
                      const Color(
                    0xFF1F2937,
                  ),
                  style:
                      const TextStyle(
                    color: Colors.white,
                  ),
                  decoration:
                      _inputDecoration(
                    label:
                        'Organization type',
                    icon: Icons
                        .category_outlined,
                  ),
                  items:
                      organizationTypes
                          .map(
                    (
                      type,
                    ) =>
                        DropdownMenuItem<
                            String>(
                      value: type,
                      child: Text(
                        _formatOrganizationType(
                          type,
                        ),
                      ),
                    ),
                  ).toList(),
                  onChanged: (value) =>
                      setState(
                    () =>
                        _selectedType =
                            value,
                  ),
                  validator: (value) =>
                      value == null ||
                              value.isEmpty
                          ? 'Select organization type'
                          : null,
                ),

                const SizedBox(
                  height: 14,
                ),

                TextFormField(
                  controller:
                      _descriptionController,
                  maxLines: 4,
                  style:
                      const TextStyle(
                    color: Colors.white,
                  ),
                  decoration:
                      _inputDecoration(
                    label: 'Description',
                    icon: Icons
                        .description_outlined,
                  ).copyWith(
                    alignLabelWithHint:
                        true,
                  ),
                  validator: (value) =>
                      value == null ||
                              value
                                  .trim()
                                  .isEmpty
                          ? 'Enter description'
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding:
          const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16,
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context)
                  .pop(),
          child:
              const Text('Cancel'),
        ),

        const SizedBox(width: 8),

        ElevatedButton(
          onPressed: _submit,
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                const Color(
              0xFF8B5CF6,
            ),
            foregroundColor:
                Colors.white,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
          ),
          child: Text(
            isEditing
                ? 'Save'
                : 'Create',
          ),
        ),
      ],
    );
  }
}