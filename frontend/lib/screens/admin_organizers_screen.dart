import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/organizer.dart';
import '../models/bulk_student_import_response.dart';
import '../models/organization.dart';
import '../services/admin_organizer_service.dart';
import '../services/admin_organization_service.dart';
import '../services/token_storage.dart';
import '../widgets/campus_back_button.dart';

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
  bool _importing = false;

  String? _errorMessage;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _selectedOrganization = 'All Organizations';
  String _selectedStatus = 'All Statuses';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==========================================================================
  // LOAD DATA
  // ==========================================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
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
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ==========================================================================
  // FILTERED ORGANIZERS
  // ==========================================================================

  List<Organizer> get _filteredOrganizers {
    final query = _searchQuery.trim().toLowerCase();

    return _organizers.where((organizer) {
      final name = organizer.name.toLowerCase();
      final email = organizer.email.toLowerCase();
      final organization =
          (organizer.organizationName ?? '').toLowerCase();
      final designation =
          (organizer.designation ?? '').toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          email.contains(query) ||
          organization.contains(query) ||
          designation.contains(query);

      final matchesOrganization =
          _selectedOrganization == 'All Organizations' ||
          (organizer.organizationName ?? '') ==
              _selectedOrganization;

      final status =
          organizer.accountStatus.toUpperCase();

      final matchesStatus =
          _selectedStatus == 'All Statuses' ||
          (_selectedStatus == 'Active' &&
              status == 'ACTIVE') ||
          (_selectedStatus == 'Blocked' &&
              status == 'BLOCKED');

      return matchesSearch &&
          matchesOrganization &&
          matchesStatus;
    }).toList();
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedOrganization = 'All Organizations';
      _selectedStatus = 'All Statuses';
    });
  }

  // ==========================================================================
  // EXCEL IMPORT
  // ==========================================================================

  Future<void> _importOrganizers() async {
    if (_importing) return;

    try {
      final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [
        'xlsx',
        'xls',
      ],
    );

    if (file == null) {
      return;
    }

    final List<int> fileBytes =
        await file.readAsBytes();

    if (fileBytes.isEmpty) {
      if (!mounted) return;

      _showMessage(
        'Unable to read the selected Excel file.',
        isError: true,
      );

      return;
    }

      if (!mounted) return;

      setState(() {
        _importing = true;
      });

      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final response =
          await _organizerService.importOrganizers(
        fileBytes,
        file.name,
        token,
      );

      if (!mounted) return;

      setState(() {
        _importing = false;
      });

      await _showImportResult(response);

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _importing = false;
      });

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // ==========================================================================
  // IMPORT RESULT
  // ==========================================================================

  Future<void> _showImportResult(
    BulkStudentImportResponse response,
  ) async {
    if (!mounted) return;

    final int totalCount = response.totalRows;
    final int successCount = response.successful;
    final int failureCount = response.failed;
    final List<String> errors = response.errors;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.file_upload_rounded,
                color: Color(0xFFC4B5FD),
              ),
              SizedBox(width: 12),
              Text(
                'Import Completed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImportResultRow(
                    'Total processed',
                    totalCount.toString(),
                  ),
                  const SizedBox(height: 12),
                  _buildImportResultRow(
                    'Imported successfully',
                    successCount.toString(),
                  ),
                  const SizedBox(height: 12),
                  _buildImportResultRow(
                    'Failed',
                    failureCount.toString(),
                  ),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Import Errors',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: errors
                            .map(
                              (error) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '• ',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        error,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFFC4B5FD),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImportResultRow(
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // BLOCK ORGANIZER
  // ==========================================================================

  Future<void> _activateOrganizer(
    Organizer organizer,
  ) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Activate Organizer',
      message:
          'Are you sure you want to activate ${organizer.name}?',
      confirmText: 'Activate',
    );

    if (!confirmed) return;

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      await _organizerService.activateOrganizer(
        organizer.id,
        token,
      );

      if (!mounted) return;

      _showMessage(
        'Organizer activated successfully.',
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  Future<void> _blockOrganizer(
    Organizer organizer,
  ) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Block Organizer',
      message:
          'Are you sure you want to block ${organizer.name}?',
      confirmText: 'Block',
    );

    if (!confirmed) return;

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      await _organizerService.blockOrganizer(
        organizer.id,
        token,
      );

      if (!mounted) return;

      _showMessage(
        'Organizer blocked successfully.',
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // ==========================================================================
  // RESET PASSWORD
  // ==========================================================================

  Future<void> _resetPassword(
    Organizer organizer,
  ) async {
    final result =
        await _showResetPasswordDialog(
      organizer,
    );

    if (result == null) {
      return;
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      await _organizerService.resetOrganizerPassword(
        id: organizer.id,
        newPassword: result['newPassword']!,
        confirmPassword: result['confirmPassword']!,
        token: token,
      );

      if (!mounted) return;

      _showMessage(
        'Organizer password reset successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // ==========================================================================
  // RESET PASSWORD DIALOG
  // ==========================================================================

  Future<Map<String, String>?> _showResetPasswordDialog(
    Organizer organizer,
  ) async {
    final passwordController =
        TextEditingController();

    final confirmController =
        TextEditingController();

    bool obscurePassword = true;
    bool obscureConfirm = true;

    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              backgroundColor:
                  const Color(0xFF11182B),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),
              title: const Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        organizer.name,
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.60),
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller:
                            passwordController,
                        obscureText:
                            obscurePassword,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                            _inputDecoration(
                          label:
                              'New Password',
                          icon:
                              Icons.lock_outline_rounded,
                          suffix: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword =
                                    !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Enter a new password';
                          }

                          if (value.length < 6) {
                            return 'Password must contain at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller:
                            confirmController,
                        obscureText:
                            obscureConfirm,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                            _inputDecoration(
                          label:
                              'Confirm Password',
                          icon:
                              Icons.lock_reset_rounded,
                          suffix: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirm =
                                    !obscureConfirm;
                              });
                            },
                            icon: Icon(
                              obscureConfirm
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Confirm the password';
                          }

                          if (value !=
                              passwordController
                                  .text) {
                            return 'Passwords do not match';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white60,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!
                        .validate()) {
                      return;
                    }

                    Navigator.pop(
                      context,
                      {
                        'newPassword':
                            passwordController.text,
                        'confirmPassword':
                            confirmController.text,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF7C3AED),
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Reset Password',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  // CONFIRMATION DIALOG
  // ==========================================================================

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF11182B),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.60),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white60,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ==========================================================================
  // MESSAGE
  // ==========================================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFB91C1C)
              : const Color(0xFF312E81),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ==========================================================================
  // ERROR CLEANUP
  // ==========================================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final bool desktop = width >= 1100;
    final bool tablet =
        width >= 700 && width < 1100;

    final horizontalPadding = desktop
        ? 40.0
        : tablet
            ? 28.0
            : 18.0;

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
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF8B5CF6),
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              desktop ? 30 : 20,
              horizontalPadding,
              30,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 1200,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        desktop,
                        tablet,
                      ),

                      const SizedBox(height: 22),

                      _buildImportCard(),

                      const SizedBox(height: 24),

                      _buildSectionHeader(),

                      const SizedBox(height: 14),

                      _buildSearchAndFilters(),

                      const SizedBox(height: 18),

                      _buildBody(
                        desktop,
                        tablet,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

    Widget _buildHeader(
    bool desktop,
    bool tablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CampusBackButton(label: 'Back'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organizer Accounts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: desktop
                          ? 30
                          : tablet
                              ? 28
                              : 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Import and manage CampusSync organizer accounts',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _loading ? null : _loadData,
              tooltip: 'Refresh',
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  // IMPORT CARD
  // ==========================================================================

  Widget _buildImportCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF5B21B6),
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1D95)
                .withOpacity(0.20),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 600;

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildImportInformation(),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: _buildImportButton(),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildImportInformation(),
              ),

              const SizedBox(width: 20),

              _buildImportButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImportInformation() {
    return const Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.table_view_rounded,
          color: Colors.white,
          size: 28,
        ),

        SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Import Organizer Excel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 5),

              Text(
                'Upload an .xlsx or .xls file to create organizer accounts. '
                'The email and date of birth in the file become the initial '
                'credentials. Users change their password during first login.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportButton() {
    return ElevatedButton.icon(
      onPressed:
          _importing ? null : _importOrganizers,
      icon: _importing
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.upload_file_rounded,
            ),
      label: Text(
        _importing
            ? 'Importing...'
            : 'Choose Excel File',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF312E81),
        disabledBackgroundColor:
            Colors.white54,
        disabledForegroundColor:
            Colors.white70,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(13),
        ),
      ),
    );
  }

  // ==========================================================================
  // SECTION HEADER
  // ==========================================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Organizer Accounts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6)
                .withOpacity(0.10),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Text(
            '${_filteredOrganizers.length} of ${_organizers.length} accounts',
            style: const TextStyle(
              color: Color(0xFFC4B5FD),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // SEARCH AND FILTERS
  // ==========================================================================

  Widget _buildSearchAndFilters() {
    final organizationNames = _organizations
        .map((organization) => organization.name)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.075),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final searchField = TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            decoration: _inputDecoration(
              label: 'Search organizers',
              icon: Icons.search_rounded,
              suffix: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: Colors.white54,
                        size: 19,
                      ),
                    ),
            ).copyWith(
              hintText:
                  'Name, email, organization or designation',
              hintStyle: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          );

          final organizationDropdown =
              DropdownButtonFormField<String>(
            value: _selectedOrganization,
            isExpanded: true,
            dropdownColor: const Color(0xFF11182B),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            decoration: _inputDecoration(
              label: 'Organization',
              icon: Icons.business_outlined,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: 'All Organizations',
                child: Text(
                  'All Organizations',
                ),
              ),
              ...organizationNames.map(
                (name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedOrganization = value;
              });
            },
          );

          final statusDropdown =
              DropdownButtonFormField<String>(
            value: _selectedStatus,
            isExpanded: true,
            dropdownColor: const Color(0xFF11182B),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            decoration: _inputDecoration(
              label: 'Status',
              icon: Icons.verified_user_outlined,
            ),
            items: const [
              DropdownMenuItem<String>(
                value: 'All Statuses',
                child: Text('All Statuses'),
              ),
              DropdownMenuItem<String>(
                value: 'Active',
                child: Text('Active'),
              ),
              DropdownMenuItem<String>(
                value: 'Blocked',
                child: Text('Blocked'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedStatus = value;
              });
            },
          );

          final clearButton =
              OutlinedButton.icon(
            onPressed:
                (_searchQuery.isEmpty &&
                        _selectedOrganization ==
                            'All Organizations' &&
                        _selectedStatus ==
                            'All Statuses')
                    ? null
                    : _clearFilters,
            icon: const Icon(
              Icons.filter_alt_off_rounded,
              size: 17,
            ),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC4B5FD),
              disabledForegroundColor:
                  Colors.white24,
              side: BorderSide(
                color: const Color(0xFF8B5CF6)
                    .withOpacity(0.25),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          );

          if (compact) {
            return Column(
              children: [
                searchField,
                const SizedBox(height: 12),
                organizationDropdown,
                const SizedBox(height: 12),
                statusDropdown,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: clearButton,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: searchField,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: organizationDropdown,
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 190,
                child: statusDropdown,
              ),
              const SizedBox(width: 12),
              clearButton,
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // BODY
  // ==========================================================================

  Widget _buildBody(
    bool desktop,
    bool tablet,
  ) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_organizers.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = _filteredOrganizers;

    if (filtered.isEmpty) {
      return _buildNoResultsState();
    }

    final crossAxisCount = desktop
        ? 3
        : tablet
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio:
            desktop ? 1.55 : 1.65,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final organizer = filtered[index];

        return _OrganizerCard(
          organizer: organizer,
          onBlock: () => _blockOrganizer(
            organizer,
          ),
          onActivate: () => _activateOrganizer(
            organizer,
          ),
          onResetPassword:
              () => _resetPassword(
            organizer,
          ),
        );
      },
    );
  }

  // ==========================================================================
  // NO SEARCH RESULTS
  // ==========================================================================

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Color(0xFFC4B5FD),
            size: 46,
          ),
          const SizedBox(height: 14),
          const Text(
            'No organizers match your filters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Try a different search term or clear the filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(
              Icons.filter_alt_off_rounded,
            ),
            label: const Text('Clear Filters'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(0xFFC4B5FD),
              side: BorderSide(
                color: const Color(0xFF8B5CF6)
                    .withOpacity(0.30),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ERROR STATE
  // ==========================================================================

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.red.withOpacity(0.14),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 42,
          ),

          const SizedBox(height: 12),

          const Text(
            'Unable to load organizer accounts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.50),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF7C3AED),
              foregroundColor:
                  Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // EMPTY STATE
  // ==========================================================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.manage_accounts_outlined,
            color: Color(0xFFC4B5FD),
            size: 50,
          ),

          const SizedBox(height: 14),

          const Text(
            'No organizer accounts found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Import an Excel file to create organizer accounts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.45),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: _importOrganizers,
            icon: const Icon(
              Icons.upload_file_rounded,
            ),
            label: const Text(
              'Import Organizers',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF7C3AED),
              foregroundColor:
                  Colors.white,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ORGANIZER CARD
// ============================================================================

class _OrganizerCard extends StatelessWidget {
  final Organizer organizer;
  final VoidCallback onBlock;
  final VoidCallback onActivate;
  final VoidCallback onResetPassword;

  const _OrganizerCard({
    required this.organizer,
    required this.onBlock,
    required this.onActivate,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final bool blocked =
        organizer.accountStatus
                .toUpperCase() ==
            'BLOCKED';

    final bool firstLogin =
        organizer.firstLogin == true;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.075),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF7C3AED),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(organizer.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 11),

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
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      organizer.email,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.40),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              _StatusBadge(
                text: blocked
                    ? 'BLOCKED'
                    : 'ACTIVE',
                blocked: blocked,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _InfoLine(
            icon: Icons.phone_outlined,
            text: organizer.phoneNumber ??
                'No phone number',
          ),

          const SizedBox(height: 7),

          _InfoLine(
            icon: Icons.business_outlined,
            text: organizer.organizationName ??
                'No organization',
          ),

          const SizedBox(height: 7),

          _InfoLine(
            icon: Icons.badge_outlined,
            text: organizer.designation ??
                'No designation',
          ),

          const Spacer(),

          if (firstLogin)
            Container(
              width: double.infinity,
              margin:
                  const EdgeInsets.only(
                top: 12,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.orange
                    .withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(9),
                border: Border.all(
                  color: Colors.orange
                      .withOpacity(0.10),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    color:
                        Colors.orangeAccent,
                    size: 15,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'First login pending — user must change password',
                      style: TextStyle(
                        color:
                            Colors.orangeAccent,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      onResetPassword,
                  icon: const Icon(
                    Icons.lock_reset_rounded,
                    size: 16,
                  ),
                  label: const Text(
                    'Reset Password',
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
                      ).withOpacity(0.30),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    textStyle:
                        const TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: blocked ? onActivate : onBlock,
                  icon: Icon(
                    blocked
                        ? Icons.check_circle_outline_rounded
                        : Icons.block_rounded,
                    size: 16,
                  ),
                  label: Text(
                    blocked ? 'Activate' : 'Block',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: blocked
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    side: BorderSide(
                      color: (blocked
                              ? Colors.greenAccent
                              : Colors.redAccent)
                          .withOpacity(0.25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}

// ============================================================================
// STATUS BADGE
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final String text;
  final bool blocked;

  const _StatusBadge({
    required this.text,
    required this.blocked,
  });

  @override
  Widget build(BuildContext context) {
    final color = blocked
        ? Colors.redAccent
        : Colors.greenAccent;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ============================================================================
// INFO LINE
// ============================================================================

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              Colors.white.withOpacity(0.35),
          size: 15,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.48),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// IMPORT RESULT ROW
// ============================================================================

class _ImportResultRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _ImportResultRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// INPUT DECORATION
// ============================================================================

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: Colors.white54,
    ),
    prefixIcon: Icon(
      icon,
      color: const Color(0xFFC4B5FD),
      size: 20,
    ),
    suffixIcon: suffix,
    filled: true,
    fillColor:
        Colors.white.withOpacity(0.05),
    enabledBorder: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(12),
      borderSide: BorderSide(
        color:
            Colors.white.withOpacity(0.08),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF8B5CF6),
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.redAccent,
      ),
    ),
    focusedErrorBorder:
        OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.redAccent,
      ),
    ),
  );
}