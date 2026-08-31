class BulkStudentImportResponse {
  final int totalRows;
  final int successful;
  final int failed;
  final List<String> errors;

  const BulkStudentImportResponse({
    required this.totalRows,
    required this.successful,
    required this.failed,
    required this.errors,
  });

  factory BulkStudentImportResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return BulkStudentImportResponse(
      totalRows: _toInt(json['totalRows']),
      successful: _toInt(json['successful']),
      failed: _toInt(json['failed']),
      errors: _toStringList(json['errors']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static List<String> _toStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    return value
        .map(
          (item) => item.toString(),
        )
        .toList();
  }
}