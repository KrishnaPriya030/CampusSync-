import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/department.dart';
import '../models/student.dart';
import '../models/update_student_request.dart';
import '../services/admin_student_service.dart';
import '../storage/token_storage.dart';

class AdminStudentFormScreen extends StatefulWidget {
  final Student student;

  const AdminStudentFormScreen({
    super.key,
    required this.student,
  });

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

  // ==========================================================================
  // CONTROLLERS
  // ==========================================================================

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

  // ==========================================================================
  // STATE
  // ==========================================================================

  List<Department> _departments = [];
  List<Branch> _branches = [];

  Department? _selectedDepartment;
  Branch? _selectedBranch;

  bool _internal = false;
  bool _loading = true;
  bool _saving = false;

  String? _errorMessage;

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    _populateStudentData();
    _loadAcademicData();
  }

  // ==========================================================================
  // POPULATE EXISTING STUDENT
  // ==========================================================================

  void _populateStudentData() {
    final student = widget.student;

    _nameController.text = student.name;
    _emailController.text = student.email;
    _phoneController.text =
        student.phoneNumber ?? '';

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

  // ==========================================================================
  // LOAD DEPARTMENTS
  // ==========================================================================

  Future<void> _loadAcademicData() async {
    try {
      final token =
          await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found.',
        );
      }

      final departments =
          await _service.getDepartments(token);

      if (!mounted) return;

      setState(() {
        _departments = departments;

        for (final department
            in departments) {
          if (department.id ==
              widget.student.departmentId) {
            _selectedDepartment =
                department;
            break;
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
        _errorMessage =
            _cleanError(e);
      });
    }
  }

  // ==========================================================================
  // LOAD BRANCHES
  // ==========================================================================

  Future<void> _loadBranches(
    int departmentId,
  ) async {
    try {
      final token =
          await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found.',
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

        for (final branch in branches) {
          if (branch.id ==
              widget.student.branchId) {
            _selectedBranch = branch;
            break;
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
        'Failed to load branches.',
        isError: true,
      );
    }
  }

  // ==========================================================================
  // UPDATE STUDENT
  // ==========================================================================

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDepartment == null) {
      _showMessage(
        'Please select a department.',
        isError: true,
      );
      return;
    }

    if (_selectedBranch == null) {
      _showMessage(
        'Please select a branch.',
        isError: true,
      );
      return;
    }

    final admissionYear =
        int.tryParse(
      _admissionYearController.text.trim(),
    );

    final semester =
        int.tryParse(
      _semesterController.text.trim(),
    );

    final graduationYear =
        int.tryParse(
      _graduationYearController.text.trim(),
    );

    if (admissionYear == null) {
      _showMessage(
        'Admission year must be a valid number.',
        isError: true,
      );
      return;
    }

    if (semester == null) {
      _showMessage(
        'Semester must be a valid number.',
        isError: true,
      );
      return;
    }

    if (graduationYear == null) {
      _showMessage(
        'Graduation year must be a valid number.',
        isError: true,
      );
      return;
    }

    final token =
        await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      _showMessage(
        'Authentication token not found.',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final request =
          UpdateStudentRequest(
        name: _nameController.text.trim(),
        phoneNumber:
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
        programme:
            _programmeController.text.trim(),
        admissionYear: admissionYear,
        departmentId:
            _selectedDepartment!.id,
        branchId:
            _selectedBranch!.id,
        semester: semester,
        graduationYear: graduationYear,
        internal: _internal,
      );

      await _service.updateStudent(
        widget.student.id,
        request,
        token,
      );

      if (!mounted) return;

      _showMessage(
        'Student updated successfully.',
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      debugPrint(
        'Update student error: $e',
      );

      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
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
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: isError
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
  // DISPOSE
  // ==========================================================================

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

    super.dispose();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width;

    final desktop = width >= 1000;

    return Scaffold(
      backgroundColor:
          const Color(0xFF060917),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B1430),
        elevation: 0,

        title: const Text(
          'Edit Student',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF8B5CF6),
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : Container(
                  decoration:
                      const BoxDecoration(
                    gradient:
                        LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end: Alignment
                          .bottomRight,
                      colors: [
                        Color(0xFF060917),
                        Color(0xFF0B1430),
                        Color(0xFF171033),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 1000,
                        ),
                        child:
                            Form(
                          key: _formKey,
                          child:
                              ListView(
                            padding:
                                EdgeInsets.all(
                              desktop
                                  ? 32
                                  : 18,
                            ),
                            children: [
                              _buildInfoCard(),

                              const SizedBox(
                                height: 22,
                              ),

                              _buildBasicInformation(),

                              const SizedBox(
                                height: 20,
                              ),

                              _buildAcademicInformation(),

                              const SizedBox(
                                height: 24,
                              ),

                              _buildUpdateButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  // ==========================================================================
  // INFO CARD
  // ==========================================================================

  Widget _buildInfoCard() {
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
            Color(0xFF312E81),
            Color(0xFF4C1D95),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white
              .withOpacity(0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Student Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Student accounts are created through Excel import. '
                  'This screen is only for updating an existing student account.',
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
      ),
    );
  }

  // ==========================================================================
  // BASIC INFORMATION
  // ==========================================================================

  Widget _buildBasicInformation() {
    return _sectionCard(
      title: 'Basic Information',
      icon: Icons.person_outline_rounded,
      children: [
        _textField(
          controller: _nameController,
          label: 'Name',
          icon: Icons.person_outline_rounded,
        ),

        const SizedBox(height: 14),

        _textField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          enabled: false,
        ),

        const SizedBox(height: 14),

        _textField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType:
              TextInputType.phone,
          requiredField: false,
        ),

        const SizedBox(height: 14),

        _textField(
          controller:
              _registerNumberController,
          label: 'Register Number',
          icon: Icons.badge_outlined,
          enabled: false,
        ),
      ],
    );
  }

  // ==========================================================================
  // ACADEMIC INFORMATION
  // ==========================================================================

  Widget _buildAcademicInformation() {
    return _sectionCard(
      title: 'Academic Information',
      icon: Icons.school_outlined,
      children: [
        DropdownButtonFormField<
            Department>(
          value:
              _selectedDepartment,
          decoration:
              _inputDecoration(
            label: 'Department',
            icon: Icons
                .account_balance_outlined,
          ),
          dropdownColor:
              const Color(0xFF11182B),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
          items: _departments
              .where(
                (department) =>
                    department.active ||
                    department.id ==
                        widget.student
                            .departmentId,
              )
              .map(
                (department) =>
                    DropdownMenuItem<
                        Department>(
                  value: department,
                  child: Text(
                    '${department.name} (${department.code})',
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged:
              (department) async {
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

        DropdownButtonFormField<
            Branch>(
          value: _selectedBranch,
          decoration:
              _inputDecoration(
            label: 'Branch',
            icon: Icons
                .account_tree_outlined,
          ),
          dropdownColor:
              const Color(0xFF11182B),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
          items: _branches
              .where(
                (branch) =>
                    branch.active ||
                    branch.id ==
                        widget.student
                            .branchId,
              )
              .map(
                (branch) =>
                    DropdownMenuItem<
                        Branch>(
                  value: branch,
                  child: Text(
                    '${branch.name} (${branch.code})',
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged:
              _branches.isEmpty
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
          icon: Icons
              .calendar_month_outlined,
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
          icon: Icons
              .event_available_outlined,
          keyboardType:
              TextInputType.number,
        ),

        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white
                .withOpacity(0.035),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
          child: SwitchListTile(
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 14,
            ),
            title: const Text(
              'Internal Student',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Mark this account as an internal CampusSync student',
              style: TextStyle(
                color: Colors.white
                    .withOpacity(0.42),
                fontSize: 10,
              ),
            ),
            value: _internal,
            activeColor:
                const Color(
              0xFF8B5CF6,
            ),
            onChanged: (value) {
              setState(() {
                _internal = value;
              });
            },
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // UPDATE BUTTON
  // ==========================================================================

  Widget _buildUpdateButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed:
            _saving
                ? null
                : _updateStudent,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF7C3AED),
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              Colors.white12,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_rounded,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Update Student',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ==========================================================================
  // SECTION CARD
  // ==========================================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(
          0.045,
        ),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white
              .withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color: const Color(
                    0xFF8B5CF6,
                  ).withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(
                    0xFFC4B5FD,
                  ),
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              Text(
                title,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ...children,
        ],
      ),
    );
  }

  // ==========================================================================
  // TEXT FIELD
  // ==========================================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
      ),
      decoration:
          _inputDecoration(
        label: label,
        icon: icon,
        enabled: enabled,
      ),
      validator: (value) {
        if (!requiredField) {
          return null;
        }

        if (value == null ||
            value.trim().isEmpty) {
          return '$label is required';
        }

        return null;
      },
    );
  }

  // ==========================================================================
  // INPUT DECORATION
  // ==========================================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: enabled
            ? Colors.white54
            : Colors.white30,
      ),
      prefixIcon: Icon(
        icon,
        color: enabled
            ? const Color(
                0xFFC4B5FD,
              )
            : Colors.white30,
        size: 20,
      ),
      filled: true,
      fillColor: enabled
          ? Colors.white.withOpacity(
              0.045,
            )
          : Colors.white.withOpacity(
              0.025,
            ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: BorderSide(
          color: Colors.white
              .withOpacity(0.08),
        ),
      ),
      disabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: BorderSide(
          color: Colors.white
              .withOpacity(0.05),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide:
            const BorderSide(
          color:
              Color(0xFF8B5CF6),
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

  // ==========================================================================
  // ERROR STATE
  // ==========================================================================

  Widget _buildErrorState() {
    return Container(
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
      child: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .error_outline_rounded,
                color:
                    Colors.redAccent,
                size: 46,
              ),

              const SizedBox(
                height: 14,
              ),

              const Text(
                'Unable to load student data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.white
                      .withOpacity(0.50),
                  fontSize: 12,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _errorMessage =
                        null;
                  });

                  _loadAcademicData();
                },
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
                    const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}