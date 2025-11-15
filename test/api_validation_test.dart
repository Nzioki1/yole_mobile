import 'package:flutter_test/flutter_test.dart';
import 'api_validator.dart';
import 'api_report_generator.dart';

void main() {
  group('API Validation Tests', () {
    late ApiValidator validator;

    setUp(() {
      validator = ApiValidator();
    });

    tearDown(() {
      validator.dispose();
    });

    test('Validate all API endpoints and generate report', () async {
      print('\n' + '=' * 60);
      print('YOLE API VALIDATION TEST');
      print('=' * 60 + '\n');

      // Run validation
      final results = await validator.validateAll();

      // Generate report
      final report = ApiReportGenerator.generateReport(results);

      // Print report to console
      print(report);

      // Save report to file
      final reportPath = 'API_VALIDATION_REPORT.md';
      await ApiReportGenerator.saveReport(report, reportPath);

      // Basic assertions
      expect(results, isNotEmpty);
      expect(results.length, equals(16));

      print('\n' + '=' * 60);
      print('VALIDATION COMPLETE');
      print('=' * 60);
    });
  });
}
