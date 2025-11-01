import 'dart:io';
import 'api_validator.dart';

/// Generate markdown report from validation results
class ApiReportGenerator {
  /// Generate markdown report
  static String generateReport(List<ApiValidationResult> results) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# YOLE API Validation Report');
    buffer.writeln('**Generated:** ${DateTime.now().toIso8601String()}\n');

    // Summary
    final summary = _generateSummary(results);
    buffer.writeln(summary);
    buffer.writeln();

    // Public Endpoints
    final publicEndpoints = results.where((r) => !r.requiresAuth).toList();
    if (publicEndpoints.isNotEmpty) {
      buffer.writeln('## Public Endpoints\n');
      buffer.writeln(_generateTable(publicEndpoints));
      buffer.writeln();
    }

    // Protected Endpoints
    final protectedEndpoints = results.where((r) => r.requiresAuth).toList();
    if (protectedEndpoints.isNotEmpty) {
      buffer.writeln('## Protected Endpoints\n');
      buffer.writeln(_generateTable(protectedEndpoints));
      buffer.writeln();
    }

    // Detailed Results
    buffer.writeln('## Detailed Results\n');
    for (final result in results) {
      buffer.writeln(_generateDetailedResult(result));
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate summary section
  static String _generateSummary(List<ApiValidationResult> results) {
    final total = results.length;
    final operational = results.where((r) => r.isUp).length;
    final authIssues = results.where((r) => r.isAuthIssue).length;
    final down = results.where((r) => r.isDown).length;

    final avgResponseTime = results
            .where((r) => r.responseTimeMs > 0)
            .map((r) => r.responseTimeMs)
            .fold(0, (sum, time) => sum + time) /
        results.where((r) => r.responseTimeMs > 0).length;

    return '''## Summary

- **Total Endpoints:** $total
- **Operational (200-299):** $operational
- **Auth Issues (401):** $authIssues
- **Down/Errors:** $down
- **Average Response Time:** ${avgResponseTime.toStringAsFixed(2)}ms
- **Success Rate:** ${((operational / total) * 100).toStringAsFixed(1)}%''';
  }

  /// Generate markdown table
  static String _generateTable(List<ApiValidationResult> results) {
    final buffer = StringBuffer();

    // Table header
    buffer.writeln('| Endpoint | Method | Status | Response Time | Notes |');
    buffer.writeln('|----------|--------|--------|---------------|-------|');

    // Table rows
    for (final result in results) {
      final name = result.name;
      final method = result.method;
      final status = result.statusEmoji;
      final responseTime =
          result.responseTimeMs > 0 ? '${result.responseTimeMs}ms' : 'N/A';
      final notes = result.error ?? 'Working';

      buffer.writeln('| $name | $method | $status | $responseTime | $notes |');
    }

    return buffer.toString();
  }

  /// Generate detailed result
  static String _generateDetailedResult(ApiValidationResult result) {
    final buffer = StringBuffer();

    buffer.writeln('### ${result.name}');
    buffer.writeln();
    buffer.writeln('- **Endpoint:** \`${result.endpoint}\`');
    buffer.writeln('- **Method:** \`${result.method}\`');
    buffer
        .writeln('- **Requires Auth:** ${result.requiresAuth ? "Yes" : "No"}');
    buffer.writeln('- **Status Code:** \`${result.statusCode}\`');
    buffer.writeln('- **Status:** ${result.statusEmoji}');
    buffer.writeln('- **Response Time:** ${result.responseTimeMs}ms');

    if (result.error != null) {
      buffer.writeln('- **Error:** ${result.error}');
    }

    if (result.responseBody != null) {
      buffer.writeln(
          '- **Response Keys:** ${result.responseBody!.keys.join(", ")}');
    }

    return buffer.toString();
  }

  /// Save report to file
  static Future<void> saveReport(String report, String filePath) async {
    final file = File(filePath);
    await file.writeAsString(report);
    print('📄 Report saved to: $filePath');
  }
}
