import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/bulk_student_import_response.dart';
import '../models/student.dart';
import '../services/admin_student_service.dart';
import '../storage/token_storage.dart';
import '../widgets/campus_back_button.dart';
import 'admin_student_form_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({
    super.key,
  });

  @override
  State<AdminStudentsScreen> createState() =>
      _AdminStudentsScreenState();
}

class _AdminStudentsScreenState
    extends State<AdminStudentsScreen> {
  final AdminStudentService _studentService =
      AdminStudentService();

  final TokenStorage _tokenStorage =
      TokenStorage();

  final TextEditingController _searchController =
      TextEditingController();

  List<Student> _students = [];
  List<Student> _filteredStudents = [];

  bool _loading = true;
  bool _importing = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _filterStudents,
    );

    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _filterStudents,
    );

    _searchController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // LOAD STUDENTS
  // ==========================================================================

  Future<void> _loadStudents() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token =
          await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found.',
        );
      }

      final students =
          await _studentService.getAllStudents(
        token,
      );

      if (!mounted) return;

      setState(() {
        _students = students;
        _filteredStudents =
            List<Student>.from(students);
        _loading = false;
      });

      _filterStudents();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  // ==========================================================================
  // SEARCH
  // ==========================================================================

  void _filterStudents() {
    final query =
        _searchController.text
            .trim()
            .toLowerCase();

    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        _filteredStudents =
            List<Student>.from(_students);
        return;
      }

      _filteredStudents =
          _students.where((student) {
        return student.name
                .toLowerCase()
                .contains(query) ||
            student.email
                .toLowerCase()
                .contains(query) ||
            student.registerNumber
                .toLowerCase()
                .contains(query) ||
            student.departmentName
                .toLowerCase()
                .contains(query) ||
            student.branchName
                .toLowerCase()
                .contains(query) ||
            student.programme
                .toLowerCase()
                .contains(query);
      }).toList();
    });
  }

  // ==========================================================================
  // EDIT STUDENT
  // ==========================================================================

  Future<void> _editStudent(
    Student student,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminStudentFormScreen(
          student: student,
        ),
      ),
    );

    if (result == true) {
      await _loadStudents();
    }
  }

  // ==========================================================================
  // ACTIVATE / DEACTIVATE
  // ==========================================================================

  Future<void> _toggleStudent(
    Student student,
  ) async {
    final isActive =
        _isStudentActive(student);

    final confirmed =
        await _showConfirmationDialog(
      student,
      isActive,
    );

    if (!confirmed) return;

    try {
      final token =
          await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found.',
        );
      }

      final Student updated;

      if (isActive) {
        updated =
            await _studentService
                .deactivateStudent(
          student.id,
          token,
        );
      } else {
        updated =
            await _studentService
                .activateStudent(
          student.id,
          token,
        );
      }

      if (!mounted) return;

      final index =
          _students.indexWhere(
        (item) => item.id == updated.id,
      );

      if (index != -1) {
        setState(() {
          _students[index] = updated;
        });

        _filterStudents();
      }

      _showMessage(
        isActive
            ? 'Student deactivated successfully.'
            : 'Student activated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        error: true,
      );
    }
  }

  // ==========================================================================
  // IMPORT EXCEL
  // ==========================================================================

Future<void> _importExcel() async {
  if (_importing) return;

  try {
    final PlatformFile? selectedFile =
        await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [
        'xlsx',
        'xls',
      ],
    );

    if (selectedFile == null) {
      return;
    }

    final extension =
        selectedFile.extension?.toLowerCase();

    if (extension != 'xlsx' &&
        extension != 'xls') {
      _showMessage(
        'Please select an Excel file (.xlsx or .xls).',
        error: true,
      );
      return;
    }

    // Read the selected file as bytes.
    // This works in Flutter Web/Chrome.
    final List<int> fileBytes =
        await selectedFile.readAsBytes();

    if (fileBytes.isEmpty) {
      _showMessage(
        'Unable to read the selected Excel file.',
        error: true,
      );
      return;
    }

    final confirmed =
        await _showImportConfirmation(
      selectedFile.name,
    );

    if (!confirmed) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _importing = true;
    });

    final token =
        await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found.',
      );
    }

    final response =
        await _studentService.importStudents(
      fileBytes,
      selectedFile.name,
      token,
    );

    if (!mounted) return;

    setState(() {
      _importing = false;
    });

    await _showImportResult(response);

    if (response.successful > 0) {
      await _loadStudents();
    }
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _importing = false;
    });

    _showMessage(
      'Import failed: ${_cleanError(e)}',
      error: true,
    );
  }
}
  // ==========================================================================
  // IMPORT CONFIRMATION
  // ==========================================================================

  Future<bool> _showImportConfirmation(
    String fileName,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF111827),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.upload_file_rounded,
                color:
                    Color(0xFFC4B5FD),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Import Students',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Import student accounts from:\n\n'
            '$fileName\n\n'
            'The email and date of birth in the '
            'Excel file are used as the initial '
            'credentials. Users change their '
            'password after first login.',
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.68),
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white60,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              icon: const Icon(
                Icons.upload_rounded,
                size: 17,
              ),
              label:
                  const Text('Import'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF7C3AED,
                ),
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ==========================================================================
  // IMPORT RESULT
  // ==========================================================================

  Future<void> _showImportResult(
    BulkStudentImportResponse response,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF111827),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color:
                    Color(0xFFC4B5FD),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Import Result',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content:
              SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                _ResultRow(
                  label: 'Total Rows',
                  value:
                      response.totalRows
                          .toString(),
                ),

                _ResultRow(
                  label: 'Successful',
                  value:
                      response.successful
                          .toString(),
                ),

                _ResultRow(
                  label: 'Failed',
                  value:
                      response.failed
                          .toString(),
                ),

                if (response.errors
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 14,
                  ),

                  const Text(
                    'Errors',
                    style:
                        TextStyle(
                      color:
                          Colors.redAccent,
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  ...response.errors.map(
                    (error) => Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        bottom: 7,
                      ),
                      child: Text(
                        '• $error',
                        style: TextStyle(
                          color: Colors
                              .white
                              .withOpacity(
                            0.65,
                          ),
                          fontSize: 12,
                          height: 1.4,
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
              onPressed: () =>
                  Navigator.pop(
                context,
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF7C3AED,
                ),
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
              ),
              child:
                  const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // MESSAGE
  // ==========================================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFB91C1C)
              : const Color(0xFF312E81),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ==========================================================================
  // CONFIRMATION DIALOG
  // ==========================================================================

  Future<bool> _showConfirmationDialog(
    Student student,
    bool isActive,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF111827),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: Text(
            isActive
                ? 'Deactivate Student?'
                : 'Activate Student?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: Text(
            isActive
                ? 'Are you sure you want to deactivate ${student.name}?'
                : 'Are you sure you want to activate ${student.name}?',
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.68),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white60,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    isActive
                        ? Colors.redAccent
                        : Colors.green,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
              ),
              child: Text(
                isActive
                    ? 'Deactivate'
                    : 'Activate',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ==========================================================================
  // ACTIVE STATUS
  // ==========================================================================

  bool _isStudentActive(
    Student student,
  ) {
    return student.accountStatus
            .trim()
            .toLowerCase() ==
        'active';
  }

  // ==========================================================================
  // ERROR CLEANUP
  // ==========================================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(11);
    }

    return message;
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width;

    final bool desktop =
        width >= 1100;

    final bool tablet =
        width >= 700 && width < 1100;

    final horizontalPadding =
        desktop
            ? 40.0
            : tablet
                ? 28.0
                : 18.0;

    return Scaffold(
      backgroundColor:
          const Color(0xFF060917),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF060917),
        elevation: 0,

        title: const Text(
          'Student Accounts',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _loading || _importing
                    ? null
                    : _loadStudents,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: Container(
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(0xFF060917),
              Color(0xFF0B1430),
              Color(0xFF171033),
            ],
          ),
        ),

        child: SafeArea(
          child: RefreshIndicator(
            onRefresh:
                _loadStudents,
            color:
                const Color(0xFF8B5CF6),

            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                30,
              ),

              children: [
                Center(
                  child:
                      ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 1200,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        _buildHeader(),

                        const SizedBox(
                          height: 20,
                        ),

                        _buildImportCard(),

                        const SizedBox(
                          height: 20,
                        ),

                        _buildSearch(),

                        const SizedBox(
                          height: 18,
                        ),

                        _buildCountHeader(),

                        const SizedBox(
                          height: 12,
                        ),

                        SizedBox(
                          height:
                              MediaQuery.sizeOf(
                            context,
                          ).height -
                              250,

                          child:
                              _buildContent(
                            desktop,
                            tablet,
                          ),
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

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const CampusBackButton(label: 'Back'),

        const SizedBox(height: 12),

        const Text(
          'Student Accounts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Import and manage CampusSync student accounts',
          style: TextStyle(
            color: Colors.white
                .withOpacity(0.50),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // IMPORT CARD
  // ==========================================================================

  Widget _buildImportCard() {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF5B21B6),
          ],
        ),

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color: Colors.white
              .withOpacity(0.10),
        ),

        boxShadow: [
          BoxShadow(
            color:
                const Color(
              0xFF4C1D95,
            ).withOpacity(0.20),
            blurRadius: 25,
            offset:
                const Offset(0, 10),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder:
            (context, constraints) {
          final compact =
              constraints.maxWidth <
                  650;

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                _buildImportInformation(),

                const SizedBox(
                  height: 16,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  child:
                      _buildImportButton(),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child:
                    _buildImportInformation(),
              ),

              const SizedBox(
                width: 20,
              ),

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
                'Import Student Excel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              SizedBox(height: 5),

              Text(
                'Upload an .xlsx or .xls file to create student accounts. '
                'The email and date of birth supplied in the file become '
                'the initial credentials. Students change their password '
                'during first login.',
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
          _importing
              ? null
              : _importExcel,

      icon: _importing
          ? const SizedBox(
              width: 17,
              height: 17,
              child:
                  CircularProgressIndicator(
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

      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            Colors.white,
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
              BorderRadius.circular(
            13,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // SEARCH
  // ==========================================================================

  Widget _buildSearch() {
    return TextField(
      controller:
          _searchController,

      style:
          const TextStyle(
        color: Colors.white,
      ),

      decoration:
          InputDecoration(
        hintText:
            'Search by name, email, register number, department...',

        hintStyle:
            TextStyle(
          color: Colors.white
              .withOpacity(0.35),
        ),

        prefixIcon:
            const Icon(
          Icons.search_rounded,
          color:
              Color(0xFFC4B5FD),
        ),

        suffixIcon:
            _searchController
                    .text
                    .isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController
                          .clear();
                    },
                    icon:
                        const Icon(
                      Icons
                          .clear_rounded,
                      color:
                          Colors.white54,
                    ),
                  )
                : null,

        filled: true,

        fillColor:
            Colors.white
                .withOpacity(0.055),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFF8B5CF6),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // COUNT
  // ==========================================================================

  Widget _buildCountHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Student Accounts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFF8B5CF6,
            ).withOpacity(0.10),

            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),

          child: Text(
            '${_filteredStudents.length} students',
            style:
                const TextStyle(
              color:
                  Color(0xFFC4B5FD),
              fontSize: 10,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // CONTENT
  // ==========================================================================

  Widget _buildContent(
    bool desktop,
    bool tablet,
  ) {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(0xFF8B5CF6),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_students.isEmpty) {
      return _buildEmptyState(
        'No students found',
        'Import an Excel file to create student accounts.',
      );
    }

    if (_filteredStudents.isEmpty) {
      return _buildEmptyState(
        'No matching students',
        'Try a different name, email, register number or department.',
      );
    }

    if (desktop || tablet) {
      final crossAxisCount =
          desktop ? 3 : 2;

      return GridView.builder(
        padding:
            const EdgeInsets.only(
          bottom: 20,
        ),

        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio:
              desktop ? 1.45 : 1.35,
        ),

        itemCount:
            _filteredStudents.length,

        itemBuilder:
            (context, index) {
          final student =
              _filteredStudents[index];

          return _StudentCard(
            student: student,
            active:
                _isStudentActive(
              student,
            ),
            onEdit:
                () => _editStudent(
              student,
            ),
            onToggle:
                () => _toggleStudent(
              student,
            ),
          );
        },
      );
    }

    return ListView.separated(
      padding:
          const EdgeInsets.only(
        bottom: 20,
      ),

      itemCount:
          _filteredStudents.length,

      separatorBuilder:
          (_, __) =>
              const SizedBox(
        height: 12,
      ),

      itemBuilder:
          (context, index) {
        final student =
            _filteredStudents[index];

        return _StudentCard(
          student: student,
          active:
              _isStudentActive(
            student,
          ),
          onEdit:
              () => _editStudent(
            student,
          ),
          onToggle:
              () => _toggleStudent(
            student,
          ),
        );
      },
    );
  }

  // ==========================================================================
  // ERROR STATE
  // ==========================================================================

  Widget _buildErrorState() {
    return ListView(
      children: [
        const SizedBox(
          height: 120,
        ),

        Center(
          child: Column(
            children: [
              const Icon(
                Icons
                    .error_outline_rounded,
                color:
                    Colors.redAccent,
                size: 48,
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                'Unable to load students',
                style:
                    TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 20,
                ),
                child: Text(
                  _error!,
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.5,
                    ),
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              ElevatedButton(
                onPressed:
                    _loadStudents,
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF7C3AED,
                  ),
                  foregroundColor:
                      Colors.white,
                ),
                child:
                    const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // EMPTY STATE
  // ==========================================================================

  Widget _buildEmptyState(
    String title,
    String subtitle,
  ) {
    return ListView(
      children: [
        const SizedBox(
          height: 120,
        ),

        Center(
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF8B5CF6,
                  ).withOpacity(
                    0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child:
                    const Icon(
                  Icons.school_outlined,
                  color:
                      Color(0xFFC4B5FD),
                  size: 34,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                title,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 30,
                ),
                child: Text(
                  subtitle,
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.45,
                    ),
                    fontSize: 13,
                  ),
                ),
              ),

              if (_students.isEmpty) ...[
                const SizedBox(
                  height: 20,
                ),

                ElevatedButton.icon(
                  onPressed:
                      _importExcel,
                  icon:
                      const Icon(
                    Icons
                        .upload_file_rounded,
                  ),
                  label:
                      const Text(
                    'Import Students',
                  ),
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF7C3AED,
                    ),
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// STUDENT CARD
// ============================================================================

class _StudentCard
    extends StatelessWidget {
  final Student student;
  final bool active;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _StudentCard({
    required this.student,
    required this.active,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(
        color: Colors.white
            .withOpacity(0.055),

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: Colors.white
              .withOpacity(0.08),
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration:
                    BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF6366F1),
                    ],
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                child: Center(
                  child: Text(
                    _initials(
                      student.name,
                    ),
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      student.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      student
                          .registerNumber,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(
                          0.50,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color: active
                      ? Colors.green
                          .withOpacity(
                          0.12,
                        )
                      : Colors.red
                          .withOpacity(
                          0.12,
                        ),

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child: Text(
                  active
                      ? 'ACTIVE'
                      : 'INACTIVE',
                  style: TextStyle(
                    color: active
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (student.firstLogin) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    size: 16,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'First login pending — user must change password',
                      style: TextStyle(
                        color: Colors.orangeAccent.withOpacity(0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(
            height: 14,
          ),

          _InfoItem(
            icon:
                Icons.email_outlined,
            value:
                student.email,
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons
                      .account_balance_outlined,
                  value:
                      student.departmentName,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _InfoItem(
                  icon: Icons
                      .school_outlined,
                  value:
                      student.branchName,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          _InfoItem(
            icon:
                Icons.menu_book_outlined,
            value:
                '${student.programme} • Sem ${student.semester}',
          ),

          const Spacer(),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      onEdit,
                  icon:
                      const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
                  label:
                      const Text(
                    'Edit',
                  ),
                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        const Color(
                      0xFFC4B5FD,
                    ),
                    side:
                        BorderSide(
                      color:
                          const Color(
                        0xFF8B5CF6,
                      ).withOpacity(
                        0.35,
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

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      onToggle,
                  icon: Icon(
                    active
                        ? Icons
                            .block_outlined
                        : Icons
                            .check_circle_outline,
                    size: 17,
                  ),
                  label: Text(
                    active
                        ? 'Deactivate'
                        : 'Activate',
                  ),
                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        active
                            ? Colors
                                .redAccent
                            : Colors
                                .greenAccent,
                    side:
                        BorderSide(
                      color: active
                          ? Colors
                              .redAccent
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

  String _initials(String name) {
    final trimmed =
        name.trim();

    if (trimmed.isEmpty) {
      return 'S';
    }

    final parts =
        trimmed.split(
      RegExp(r'\s+'),
    );

    if (parts.length == 1) {
      return parts.first[0]
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}

// ============================================================================
// INFO ITEM
// ============================================================================

class _InfoItem
    extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color:
              const Color(0xFFA78BFA),
        ),

        const SizedBox(
          width: 7,
        ),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.52),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// RESULT ROW
// ============================================================================

class _ResultRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.55),
              fontSize: 13,
            ),
          ),

          Text(
            value,
            style:
                const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}