import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/bulk_student_import_response.dart';
import '../models/organization_head.dart';
import '../services/admin_organization_head_service.dart';
import '../storage/token_storage.dart';
import '../widgets/campus_back_button.dart';

class AdminOrganizationHeadsScreen extends StatefulWidget {
  const AdminOrganizationHeadsScreen({super.key});

  @override
  State<AdminOrganizationHeadsScreen> createState() =>
      _AdminOrganizationHeadsScreenState();
}

class _AdminOrganizationHeadsScreenState
    extends State<AdminOrganizationHeadsScreen> {
  final AdminOrganizationHeadService _service = AdminOrganizationHeadService();
  final TokenStorage _tokenStorage = TokenStorage();
  final TextEditingController _searchController = TextEditingController();

  List<OrganizationHead> _items = [];
  List<OrganizationHead> _filteredItems = [];

  bool _loading = true;
  bool _importing = false;
  String? _error;

  String _statusFilter = 'ALL';
  String _groupFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final items = await _service.getAllOrganizationHeads(token);

      if (!mounted) return;
      setState(() {
        _items = items;
        _filteredItems = List<OrganizationHead>.from(items);
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  void _applyFilters() {
    if (!mounted) return;

    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredItems = _items.where((item) {
        final matchesQuery =
            query.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            item.email.toLowerCase().contains(query) ||
            (item.phoneNumber ?? '').toLowerCase().contains(query) ||
            item.organizationName.toLowerCase().contains(query) ||
            item.designation.toLowerCase().contains(query);

        final matchesStatus =
            _statusFilter == 'ALL' ||
            item.accountStatus.toUpperCase() == _statusFilter;

        final matchesGroup =
            _groupFilter == 'ALL' || item.organizationName == _groupFilter;

        return matchesQuery && matchesStatus && matchesGroup;
      }).toList();
    });
  }

  List<String> get _groups {
    final values = _items
        .map((item) => item.organizationName)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  Future<void> _importExcel() async {
    if (_importing) return;

    try {
      final PlatformFile? selectedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (selectedFile == null) return;

      final extension = selectedFile.extension?.toLowerCase();
      if (extension != 'xlsx' && extension != 'xls') {
        _showMessage(
          'Please select an Excel file (.xlsx or .xls).',
          error: true,
        );
        return;
      }

      final fileBytes = await selectedFile.readAsBytes();
      if (fileBytes.isEmpty) {
        _showMessage('Unable to read the selected Excel file.', error: true);
        return;
      }

      final confirmed = await _showImportConfirmation(selectedFile.name);
      if (!confirmed || !mounted) return;

      setState(() => _importing = true);

      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final response = await _service.importOrganizationHeads(
        fileBytes,
        selectedFile.name,
        token,
      );

      if (!mounted) return;
      setState(() => _importing = false);

      await _showImportResult(response);

      if (response.successful > 0) {
        await _loadItems();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      _showMessage('Import failed: ${_cleanError(e)}', error: true);
    }
  }

  Future<void> _toggle(OrganizationHead item) async {
    final active = item.accountStatus.toUpperCase() == 'ACTIVE';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          active ? 'Block Account?' : 'Activate Account?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          active
              ? 'Are you sure you want to block ${item.name}?'
              : 'Are you sure you want to activate ${item.name}?',
          style: TextStyle(color: Colors.white.withOpacity(0.68)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: active ? Colors.redAccent : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(active ? 'Block' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final updated = active
          ? await _service.blockOrganizationHead(item.id, token)
          : await _service.activateOrganizationHead(item.id, token);

      if (!mounted) return;

      final index = _items.indexWhere((x) => x.id == updated.id);
      if (index != -1) {
        setState(() => _items[index] = updated);
        _applyFilters();
      }

      _showMessage(
        active
            ? 'Account blocked successfully.'
            : 'Account activated successfully.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e), error: true);
    }
  }

  Future<void> _view(OrganizationHead item) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final details = await _service.getOrganizationHeadById(item.id, token);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            details.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _DetailRow(label: 'Email', value: details.email),
                _DetailRow(
                  label: 'Phone',
                  value: details.phoneNumber ?? 'Not provided',
                ),
                _DetailRow(
                  label: 'Organization',
                  value: details.organizationName,
                ),
                _DetailRow(label: 'Designation', value: details.designation),
                _DetailRow(
                  label: 'Account Status',
                  value: details.accountStatus,
                ),
                _DetailRow(
                  label: 'First Login',
                  value: details.firstLogin ? 'Pending' : 'Completed',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFFC4B5FD)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e), error: true);
    }
  }

  Future<bool> _showImportConfirmation(String fileName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.upload_file_rounded, color: Color(0xFFC4B5FD)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Import Accounts',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'The email and date of birth from the Excel file become the initial credentials. The user must change the password after first login.',
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: Icon(Icons.upload_rounded, size: 17),
            label: Text('Import'),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Color(0xFF7C3AED)),
              foregroundColor: WidgetStatePropertyAll(Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _showImportResult(BulkStudentImportResponse response) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Import Result',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResultRow(
                label: 'Total Rows',
                value: response.totalRows.toString(),
              ),
              _ResultRow(
                label: 'Successful',
                value: response.successful.toString(),
              ),
              _ResultRow(label: 'Failed', value: response.failed.toString()),
              if (response.errors.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Errors',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...response.errors.map(
                  (error) => Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $error',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final groups = _groups;

    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText:
                'Search by name, email, phone, organization or designation...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFFC4B5FD),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: _searchController.clear,
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: Colors.white54,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.055),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        );

        final status = _dropdown(
          value: _statusFilter,
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text('All Status')),
            DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
            DropdownMenuItem(value: 'BLOCKED', child: Text('Blocked')),
          ],
          onChanged: (v) {
            setState(() => _statusFilter = v ?? 'ALL');
            _applyFilters();
          },
        );

        final groupItems = <DropdownMenuItem<String>>[
          DropdownMenuItem(value: 'ALL', child: Text('All organizations')),
          ...groups.map(
            (name) => DropdownMenuItem(
              value: name,
              child: Text(name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ];

        final groupDropdown = _dropdown(
          value: _groupFilter,
          items: groupItems,
          onChanged: (v) {
            setState(() => _groupFilter = v ?? 'ALL');
            _applyFilters();
          },
        );

        final clear = OutlinedButton.icon(
          onPressed: () {
            _searchController.clear();
            setState(() {
              _statusFilter = 'ALL';
              _groupFilter = 'ALL';
            });
            _applyFilters();
          },
          icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
          label: const Text('Clear'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC4B5FD),
          ),
        );

        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: status),
                  const SizedBox(width: 10),
                  Expanded(child: groupDropdown),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: clear),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 10),
            SizedBox(width: 150, child: status),
            const SizedBox(width: 10),
            SizedBox(width: 190, child: groupDropdown),
            const SizedBox(width: 10),
            clear,
          ],
        );
      },
    );
  }

  Widget _dropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.any((item) => item.value == value) ? value : 'ALL',
      onChanged: onChanged,
      dropdownColor: const Color(0xFF111827),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.055),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: items,
    );
  }

  Widget _buildImportCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF5B21B6)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final info = Row(
            children: [
              const Icon(
                Icons.table_view_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Import organization heads from an Excel file. The user will change the password after first login.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          );

          final button = ElevatedButton.icon(
            onPressed: _importing ? null : _importExcel,
            icon: _importing
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file_rounded),
            label: Text(_importing ? 'Importing...' : 'Choose Excel File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF312E81),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          );

          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(bool desktop, bool tablet) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      );
    }

    if (_error != null) {
      return _state(
        Icons.error_outline_rounded,
        'Unable to load accounts',
        _error!,
        retry: true,
      );
    }

    if (_items.isEmpty) {
      return _state(
        Icons.people_outline_rounded,
        'No accounts found',
        'Import an Excel file to create accounts.',
      );
    }

    if (_filteredItems.isEmpty) {
      return _state(
        Icons.search_off_rounded,
        'No matching accounts',
        'Try a different search or filter.',
      );
    }

    if (desktop || tablet) {
      final columns = desktop ? 3 : 2;

      return GridView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: desktop ? 1.38 : 1.28,
        ),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return _AccountCard(
            item: item,
            active: item.accountStatus.toUpperCase() == 'ACTIVE',
            onView: () => _view(item),
            onToggle: () => _toggle(item),
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _filteredItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _AccountCard(
          item: item,
          active: item.accountStatus.toUpperCase() == 'ACTIVE',
          onView: () => _view(item),
          onToggle: () => _toggle(item),
        );
      },
    );
  }

  Widget _state(
    IconData icon,
    String title,
    String subtitle, {
    bool retry = false,
  }) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFFC4B5FD), size: 48),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                ),
              ),
              if (retry) ...[
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loadItems,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFB91C1C)
              : const Color(0xFF312E81),
        ),
      );
  }

  String _cleanError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 1100;
    final tablet = width >= 700 && width < 1100;

    final padding = desktop
        ? 40.0
        : tablet
        ? 28.0
        : 18.0;

    return Scaffold(
      backgroundColor: const Color(0xFF060917),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060917),
        elevation: 0,
        title: const Text(
          'Organization Head Accounts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading || _importing ? null : _loadItems,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF060917), Color(0xFF0B1430), Color(0xFF171033)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadItems,
            color: const Color(0xFF8B5CF6),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(padding, 20, padding, 30),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CampusBackButton(label: 'Back'),
                        const SizedBox(height: 12),
                        const Text(
                          'Organization Head Accounts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Import and manage CampusSync organization head accounts',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.50),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildImportCard(),
                        const SizedBox(height: 18),
                        _buildFilters(),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Accounts',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${_filteredItems.length} accounts',
                              style: const TextStyle(
                                color: Color(0xFFC4B5FD),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height - 270,
                          child: _buildContent(desktop, tablet),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final OrganizationHead item;
  final bool active;
  final VoidCallback onView;
  final VoidCallback onToggle;

  const _AccountCard({
    required this.item,
    required this.active,
    required this.onView,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: Center(
                  child: Text(
                    _initials(item.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.50),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  active ? 'ACTIVE' : 'BLOCKED',
                  style: TextStyle(
                    color: active ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (item.firstLogin) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.orange.withOpacity(0.20)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    size: 16,
                    color: Colors.orangeAccent,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'First login pending — user must change password',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 13),
          _InfoItem(icon: Icons.email_outlined, value: item.email),
          const SizedBox(height: 8),
          _InfoItem(
            icon: Icons.account_balance_outlined,
            value: item.organizationName,
          ),
          const SizedBox(height: 8),
          _InfoItem(
            icon: Icons.phone_outlined,
            value: item.phoneNumber ?? 'No phone number',
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC4B5FD),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    active ? Icons.block_outlined : Icons.check_circle_outline,
                    size: 17,
                  ),
                  label: Text(active ? 'Block' : 'Activate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: active
                        ? Colors.redAccent
                        : Colors.greenAccent,
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
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFA78BFA)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.52),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
