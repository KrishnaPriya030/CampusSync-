import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/create_student_request.dart';
import '../models/department.dart';
import '../models/student.dart';
import '../models/update_student_request.dart';
import '../services/admin_student_service.dart';
import '../storage/token_storage.dart';

class AdminStudentFormScreen extends StatefulWidget {
  final Student? student;

  const AdminStudentFormScreen({
    super.key,
    this.student,
  });

  bool get isEditing => student != null;

  @override
  State<AdminStudentFormScreen> createState() =>
      _AdminStudentFormScreenState();
}

class _AdminStudentFormScreenState
    extends State<AdminStudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final AdminStudentService _service =
      AdminStudentService();

  final TokenStorage _tokenStorage =
      TokenStorage();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _registerNumberController =
      TextEditingController();

  final TextEditingController _programmeController =
      TextEditingController();

  final TextEditingController _admissionYearController =
      TextEditingController();

  final TextEditingController _semesterController =
      TextEditingController();

  final TextEditingController _graduationYearController =
      TextEditingController();

  final TextEditingController _dobController =
      TextEditingController();

  List<Department> _departments = [];
  List<Branch> _branches = [];

  Department? _selectedDepartment;
  Branch? _selectedBranch;

  bool _internal = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _populateEditingData();
    _loadAcademicData();
  }

  void _populateEditingData() {
    final student = widget.student;

    if (student == null) {
      return;
    }

    _nameController.text = student.name;
    _emailController.text = student.email;
    _phoneController.text = student.phoneNumber ?? '';
    _registerNumberController.text =
        student.registerNumber;
    _programmeController.text =
        student.programme;
    _admissionYearController.text =
        student.admissionYear.toString();
    _semesterController.text =
        student.semester.toString();
    _graduationYearController.text =
        student.graduationYear.toString();
    _internal = student.internal;
  }

  Future<void> _loadAcademicData() async {
    try {
      final token =
          await _tokenStorage.getToken();

      if (token == null) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final departments =
          await _service.getDepartments(token);

      if (!mounted) return;

      setState(() {
        _departments = departments;

        if (widget.student != null) {
          for (final department in departments) {
            if (department.id ==
                widget.student!.departmentId) {
              _selectedDepartment = department;
              break;
            }
          }
        }
      });

      if (_selectedDepartment != null) {
        await _loadBranches(
          _selectedDepartment!.id,
        );
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Failed to load academic data',
      );

      debugPrint(
        'Academic data error: $e',
      );
    }
  }

  Future<void> _loadBranches(
    int departmentId,
  ) async {
    try {
      final token =
          await _tokenStorage.getToken();

      if (token == null) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final branches =
          await _service.getBranches(
        departmentId,
        token,
      );

      if (!mounted) return;

      setState(() {
        _branches = branches;

        _selectedBranch = null;

        if (widget.student != null) {
          for (final branch in branches) {
            if (branch.id ==
                widget.student!.branchId) {
              _selectedBranch = branch;
              break;
            }
          }
        }
      });
    } catch (e) {
      debugPrint(
        'Branch loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _branches = [];
        _selectedBranch = null;
      });

      _showMessage(
        'Failed to load branches',
      );
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();

    DateTime initialDate =
        DateTime(
      now.year - 18,
      now.month,
      now.day,
    );

    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(
          _dobController.text,
        );
      } catch (_) {}
    }

    final picked =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked == null) {
      return;
    }

    final month =
        picked.month.toString().padLeft(2, '0');

    final day =
        picked.day.toString().padLeft(2, '0');

    _dobController.text =
        '${picked.year}-$month-$day';
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDepartment == null) {
      _showMessage(
        'Please select a department',
      );
      return;
    }

    if (_selectedBranch == null) {
      _showMessage(
        'Please select a branch',
      );
      return;
    }

    if (!widget.isEditing &&
        _dobController.text.isEmpty) {
      _showMessage(
        'Please select date of birth',
      );
      return;
    }

    final token =
        await _tokenStorage.getToken();

    if (token == null) {
      _showMessage(
        'Authentication token not found',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (widget.isEditing) {
        final request =
            UpdateStudentRequest(
          name: _nameController.text.trim(),
          phoneNumber:
              _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
          programme:
              _programmeController.text.trim(),
          admissionYear:
              int.parse(
            _admissionYearController.text.trim(),
          ),
          departmentId:
              _selectedDepartment!.id,
          branchId:
              _selectedBranch!.id,
          semester:
              int.parse(
            _semesterController.text.trim(),
          ),
          graduationYear:
              int.parse(
            _graduationYearController.text.trim(),
          ),
          internal: _internal,
        );

        await _service.updateStudent(
          widget.student!.id,
          request,
          token,
        );

        if (!mounted) return;

        _showMessage(
          'Student updated successfully',
        );
      } else {
        final request =
            CreateStudentRequest(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber:
              _phoneController.text.trim(),
          registerNumber:
              _registerNumberController.text.trim(),
          dateOfBirth: DateTime.parse(
  _dobController.text.trim(),
),
          departmentId:
              _selectedDepartment!.id,
          branchId:
              _selectedBranch!.id,
          semester:
              int.parse(
            _semesterController.text.trim(),
          ),
          programme:
              _programmeController.text.trim(),
          admissionYear:
              int.parse(
            _admissionYearController.text.trim(),
          ),
          graduationYear:
              int.parse(
            _graduationYearController.text.trim(),
          ),
        );

        await _service.createStudent(
          request,
          token,
        );

        if (!mounted) return;

        _showMessage(
          'Student created successfully',
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint(
        'Save student error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Failed to save student',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _registerNumberController.dispose();
    _programmeController.dispose();
    _admissionYearController.dispose();
    _semesterController.dispose();
    _graduationYearController.dispose();
    _dobController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Edit Student'
        : 'Add Student';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding:
                    const EdgeInsets.all(20),
                children: [
                  _sectionTitle(
                    'Basic Information',
                  ),

                  _textField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 14),

                  _textField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType:
                        TextInputType.emailAddress,
                    enabled:
                        !widget.isEditing,
                  ),

                  const SizedBox(height: 14),

                  _textField(
                    controller:
                        _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType:
                        TextInputType.phone,
                  ),

                  const SizedBox(height: 14),

                  _textField(
                    controller:
                        _registerNumberController,
                    label: 'Register Number',
                    icon:
                        Icons.badge_outlined,
                    enabled:
                        !widget.isEditing,
                  ),

                  if (!widget.isEditing) ...[
                    const SizedBox(height: 14),

                    TextFormField(
                      controller:
                          _dobController,
                      readOnly: true,
                      onTap:
                          _selectDateOfBirth,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Date of Birth',
                        prefixIcon: Icon(
                          Icons
                              .calendar_today_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Date of birth is required';
                        }

                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 26),

                  _sectionTitle(
                    'Academic Information',
                  ),

                  DropdownButtonFormField<
                      Department>(
                    value:
                        _selectedDepartment,
                    decoration:
                        const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(
                        Icons.account_balance_outlined,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                    items: _departments
                        .where(
                          (department) =>
                              department.active,
                        )
                        .map(
                          (department) =>
                              DropdownMenuItem<
                                  Department>(
                            value: department,
                            child: Text(
                              '${department.name} (${department.code})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (department) async {
                      if (department == null) {
                        return;
                      }

                      setState(() {
                        _selectedDepartment =
                            department;
                        _branches = [];
                        _selectedBranch = null;
                      });

                      await _loadBranches(
                        department.id,
                      );
                    },
                    validator: (_) {
                      if (_selectedDepartment ==
                          null) {
                        return 'Department is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<Branch>(
                    value: _selectedBranch,
                    decoration:
                        const InputDecoration(
                      labelText: 'Branch',
                      prefixIcon: Icon(
                        Icons.account_tree_outlined,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                    items: _branches
                        .where(
                          (branch) =>
                              branch.active,
                        )
                        .map(
                          (branch) =>
                              DropdownMenuItem<
                                  Branch>(
                            value: branch,
                            child: Text(
                              '${branch.name} (${branch.code})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _branches.isEmpty
                        ? null
                        : (branch) {
                            setState(() {
                              _selectedBranch =
                                  branch;
                            });
                          },
                    validator: (_) {
                      if (_selectedBranch ==
                          null) {
                        return 'Branch is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  _textField(
                    controller:
                        _programmeController,
                    label: 'Programme',
                    icon:
                        Icons.menu_book_outlined,
                  ),

                  const SizedBox(height: 14),

                  _textField(
                    controller:
                        _admissionYearController,
                    label: 'Admission Year',
                    icon:
                        Icons.calendar_month_outlined,
                    keyboardType:
                        TextInputType.number,
                  ),

                  const SizedBox(height: 14),

                  _textField(
                    controller:
                        _semesterController,
                    label: 'Semester',
                    icon:
                        Icons.school_outlined,
                    keyboardType:
                        TextInputType.number,
                  ),

                  const SizedBox(height: 14),

                  _textField(
                    controller:
                        _graduationYearController,
                    label: 'Graduation Year',
                    icon:
                        Icons.event_available_outlined,
                    keyboardType:
                        TextInputType.number,
                  ),

                  if (widget.isEditing) ...[
                    const SizedBox(height: 14),

                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Internal Student',
                      ),
                      subtitle: const Text(
                        'Mark this student as internal',
                      ),
                      value: _internal,
                      onChanged: (value) {
                        setState(() {
                          _internal = value;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _saving
                              ? null
                              : _saveStudent,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Update Student'
                                  : 'Create Student',
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return '$label is required';
        }

        return null;
      },
    );
  }
}