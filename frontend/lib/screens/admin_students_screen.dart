import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/bulk_student_import_response.dart';
import '../models/student.dart';
import '../services/admin_student_service.dart';
import '../storage/token_storage.dart';
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

  // ============================================================
  // LOAD STUDENTS
  // ============================================================

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
          'Authentication token not found',
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

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

  // ============================================================
  // ADD STUDENT
  // ============================================================

  Future<void> _addStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminStudentFormScreen(),
      ),
    );

    if (result == true) {
      await _loadStudents();
    }
  }

  // ============================================================
  // EDIT STUDENT
  // ============================================================

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

  // ============================================================
  // ACTIVATE / DEACTIVATE
  // ============================================================

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
          'Authentication token not found',
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Student deactivated successfully'
                : 'Student activated successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Operation failed: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // IMPORT EXCEL
  // ============================================================

  Future<void> _importExcel() async {
    if (_importing) return;

    try {
      final result =
          await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'xlsx',
          'xls',
        ],
        allowMultiple: false,
      );

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final selectedFile =
          result.files.single;

      if (selectedFile.path == null ||
          selectedFile.path!.isEmpty) {
        _showMessage(
          'Unable to access the selected file.',
          error: true,
        );
        return;
      }

      final extension =
          selectedFile.extension
              ?.toLowerCase();

      if (extension != 'xlsx' &&
          extension != 'xls') {
        _showMessage(
          'Please select an Excel file (.xlsx or .xls).',
          error: true,
        );
        return;
      }

      final confirmed =
          await _showImportConfirmation(
        selectedFile.name,
      );

      if (!confirmed) return;

      if (!mounted) return;

      setState(() {
        _importing = true;
      });

      final token =
          await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final file =
          File(selectedFile.path!);

      final response =
          await _studentService
              .importStudents(
        file,
        token,
      );

      if (!mounted) return;

      setState(() {
        _importing = false;
      });

      await _showImportResult(
        response,
      );

      if (response.successful > 0) {
        await _loadStudents();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _importing = false;
      });

      _showMessage(
        'Import failed: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        error: true,
      );
    }
  }

  // ============================================================
  // IMPORT CONFIRMATION
  // ============================================================

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
          title: const Text(
            'Import Students',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: Text(
            'Import students from:\n\n$fileName',
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('Cancel'),
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
                    const Color(
                  0xFF7C3AED,
                ),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Import'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // IMPORT RESULT
  // ============================================================

  Future<void> _showImportResult(
    BulkStudentImportResponse response,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF111827),
          title: const Text(
            'Import Result',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
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

                if (response
                    .errors
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 18,
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
                  ...response.errors
                      .map(
                        (error) =>
                            Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 6,
                          ),
                          child: Text(
                            '• $error',
                            style:
                                TextStyle(
                              color: Colors
                                  .white
                                  .withOpacity(
                                0.65,
                              ),
                              fontSize: 12,
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
              ),
              child:
                  const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error
                ? Colors.redAccent
                : null,
      ),
    );
  }

  // ============================================================
  // CONFIRMATION DIALOG
  // ============================================================

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
                  .withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('Cancel'),
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

  // ============================================================
  // ACTIVE STATUS
  // ============================================================

  bool _isStudentActive(
    Student student,
  ) {
    return student.accountStatus
            .trim()
            .toLowerCase() ==
        'active';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF060917),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF060917),
        elevation: 0,
        title: const Text(
          'Students',
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
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            children: [
              // ==================================================
              // SEARCH + BUTTONS
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          _searchController,
                      style:
                          const TextStyle(
                        color: Colors.white,
                      ),
                      decoration:
                          InputDecoration(
                        hintText:
                            'Search students...',
                        hintStyle:
                            TextStyle(
                          color: Colors.white
                              .withOpacity(
                            0.4,
                          ),
                        ),
                        prefixIcon:
                            const Icon(
                          Icons
                              .search_rounded,
                          color: Color(
                            0xFFC4B5FD,
                          ),
                        ),
                        suffixIcon:
                            _searchController
                                    .text
                                    .isNotEmpty
                                ? IconButton(
                                    onPressed:
                                        () {
                                      _searchController
                                          .clear();
                                    },
                                    icon:
                                        const Icon(
                                      Icons
                                          .clear_rounded,
                                      color: Colors
                                          .white54,
                                    ),
                                  )
                                : null,
                        filled: true,
                        fillColor:
                            Colors.white
                                .withOpacity(
                          0.06,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  // IMPORT BUTTON
                  SizedBox(
                    height: 52,
                    child:
                        OutlinedButton.icon(
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
                                strokeWidth:
                                    2,
                                color:
                                    Color(
                                  0xFFC4B5FD,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons
                                  .upload_file_rounded,
                            ),
                      label: Text(
                        _importing
                            ? 'Importing...'
                            : 'Import Excel',
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
                            0.45,
                          ),
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  // ADD BUTTON
                  SizedBox(
                    height: 52,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _importing
                              ? null
                              : _addStudent,
                      icon:
                          const Icon(
                        Icons
                            .add_rounded,
                      ),
                      label:
                          const Text(
                        'Add',
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
                            15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  '${_filteredStudents.length} student${_filteredStudents.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.45,
                    ),
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Expanded(
                child:
                    _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
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
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(
            height: 150,
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
                  style: TextStyle(
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

    if (_students.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(
            height: 150,
          ),
          _buildEmptyState(
            'No students found',
            'Students imported or created by the admin will appear here.',
          ),
        ],
      );
    }

    if (_filteredStudents.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(
            height: 150,
          ),
          _buildEmptyState(
            'No matching students',
            'Try a different name, email, register number or department.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(),
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
          onEdit: () =>
              _editStudent(
            student,
          ),
          onToggle: () =>
              _toggleStudent(
            student,
          ),
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(
    String title,
    String subtitle,
  ) {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration:
                BoxDecoration(
              color: const Color(
                0xFF8B5CF6,
              ).withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child:
                const Icon(
              Icons
                  .school_outlined,
              color: Color(
                0xFFC4B5FD,
              ),
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
        ],
      ),
    );
  }
}

// ================================================================
// RESULT ROW
// ================================================================

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
                  .withOpacity(
                0.55,
              ),
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

// ================================================================
// STUDENT CARD
// ================================================================

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
            .withOpacity(0.06),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: Colors.white
              .withOpacity(0.09),
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
                      Color(
                        0xFF8B5CF6,
                      ),
                      Color(
                        0xFF6366F1,
                      ),
                    ],
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
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
                          FontWeight
                              .bold,
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
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      student
                          .registerNumber,
                      style: TextStyle(
                        color: Colors
                            .white
                            .withOpacity(
                          0.5,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
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
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
                child: Text(
                  active
                      ? 'ACTIVE'
                      : 'INACTIVE',
                  style: TextStyle(
                    color: active
                        ? Colors
                            .greenAccent
                        : Colors
                            .redAccent,
                    fontSize: 9,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),
            ],
          ),

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
                  value: student
                      .departmentName,
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
            icon: Icons
                .menu_book_outlined,
            value:
                '${student.programme} • Sem ${student.semester}',
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton
                        .icon(
                  onPressed:
                      onEdit,
                  icon:
                      const Icon(
                    Icons
                        .edit_outlined,
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
                          BorderRadius
                              .circular(
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
                    OutlinedButton
                        .icon(
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
                          BorderRadius
                              .circular(
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

  String _initials(
    String name,
  ) {
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

// ================================================================
// INFO ITEM
// ================================================================

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
              const Color(
            0xFFA78BFA,
          ),
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
                  .withOpacity(
                0.52,
              ),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}