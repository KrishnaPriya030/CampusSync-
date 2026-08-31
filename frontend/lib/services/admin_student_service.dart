import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;

import '../models/student.dart';
import '../models/department.dart';
import '../models/branch.dart';
import '../models/create_student_request.dart';
import '../models/create_student_response.dart';
import '../models/update_student_request.dart';
import '../models/bulk_student_import_response.dart';

class AdminStudentService {

  // ============================================================
  // JSON HEADERS
  // ============================================================

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // CREATE STUDENT
  // POST /api/admin/students
  // ============================================================

  Future<CreateStudentResponse> createStudent(
    CreateStudentRequest request,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$ApiConfig.baseUrl/api/admin/students'),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Failed to create student: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid create student response',
      );
    }

    return CreateStudentResponse.fromJson(decoded);
  }

  // ============================================================
  // GET ALL STUDENTS
  // GET /api/admin/students
  // ============================================================

  Future<List<Student>> getAllStudents(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$ApiConfig.baseUrl/api/admin/students'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load students: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception(
        'Invalid students response',
      );
    }

    return decoded
        .map(
          (item) => Student.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // GET STUDENT BY ID
  // GET /api/admin/students/{id}
  // ============================================================

  Future<Student> getStudentById(
    int id,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/students/$id',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load student: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid student response',
      );
    }

    return Student.fromJson(decoded);
  }

  // ============================================================
  // UPDATE STUDENT
  // PUT /api/admin/students/{id}
  // ============================================================

  Future<Student> updateStudent(
    int id,
    UpdateStudentRequest request,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/students/$id',
      ),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update student: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid update student response',
      );
    }

    return Student.fromJson(decoded);
  }

  // ============================================================
  // GET DEPARTMENTS
  // GET /api/admin/academic/departments
  // ============================================================

  Future<List<Department>> getDepartments(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/academic/departments',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load departments: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception(
        'Invalid departments response',
      );
    }

    return decoded
        .map(
          (item) => Department.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // GET BRANCHES
  // GET /api/admin/academic/branches
  // ============================================================

  Future<List<Branch>> getBranches(
    int departmentId,
    String token,
  ) async {
    final uri = Uri.parse(
      '$ApiConfig.baseUrl/api/admin/academic/branches',
    ).replace(
      queryParameters: {
        'departmentId': departmentId.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load branches: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception(
        'Invalid branches response',
      );
    }

    return decoded
        .map(
          (item) => Branch.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // ACTIVATE STUDENT
  // PUT /api/admin/students/{id}/activate
  // ============================================================

  Future<Student> activateStudent(
    int id,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/students/$id/activate',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to activate student: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid activation response',
      );
    }

    return Student.fromJson(decoded);
  }

  // ============================================================
  // DEACTIVATE STUDENT
  // PUT /api/admin/students/{id}/deactivate
  // ============================================================

  Future<Student> deactivateStudent(
    int id,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/students/$id/deactivate',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to deactivate student: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid deactivation response',
      );
    }

    return Student.fromJson(decoded);
  }

  // ============================================================
  // BULK STUDENT IMPORT
  // POST /api/admin/students/import
  // ============================================================

  Future<BulkStudentImportResponse> importStudents(
    File file,
    String token,
  ) async {
    if (!await file.exists()) {
      throw Exception(
        'Selected file does not exist',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/students/import',
      ),
    );

    request.headers['Authorization'] =
        'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to import students: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    if (response.body.isEmpty) {
      throw Exception(
        'Empty bulk import response',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid bulk import response',
      );
    }

    return BulkStudentImportResponse(
      totalRows:
          (decoded['totalRows'] as num?)?.toInt() ?? 0,
      successful:
          (decoded['successful'] as num?)?.toInt() ?? 0,
      failed:
          (decoded['failed'] as num?)?.toInt() ?? 0,
      errors:
          decoded['errors'] is List
              ? (decoded['errors'] as List)
                  .map(
                    (e) => e.toString(),
                  )
                  .toList()
              : <String>[],
    );
  }
}