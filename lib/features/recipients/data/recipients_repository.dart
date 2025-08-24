import 'package:dio/dio.dart';
import '../../../core/network/failure_mapper.dart';
import '../../../core/network/failure.dart';
import 'models.dart';
import 'recipients_api.dart';

class RecipientsRepository {
  final RecipientsApi api;

  RecipientsRepository(this.api);

  Future<RecipientsResponse> fetchRecipients({
    int page = 1,
    String? query,
  }) async {
    try {
      final response = await api.fetchRecipients(page: page, query: query);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map) throw const FormatException('Unexpected response format');
        return RecipientsResponse.fromJson(data as Map<String, dynamic>);
      } else {
        throw const NetworkFailure('Failed to fetch recipients');
      }
    } catch (e) {
      throw FailureMapper.fromAny(e);
    }
  }

  Future<Recipient> addRecipient(String name, String phoneNumber, String countryCode) async {
    try {
      final request = AddRecipientRequest(
        name: name,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
      );
      final response = await api.addRecipient(request);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        if (data is! Map) throw const FormatException('Unexpected response format');
        return Recipient.fromJson(data as Map<String, dynamic>);
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        // If API returns non-2xx without throwing, map to ValidationFailure
        throw const ValidationFailure('Validation error');
      } else {
        throw const NetworkFailure('Failed to add recipient');
      }
    } catch (e) {
      throw FailureMapper.fromAny(e);
    }
  }

  Future<List<Country>> fetchCountries() async {
    try {
      final response = await api.fetchCountries();

      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map && body['data'] is List) {
          return (body['data'] as List).map((e) => Country.fromJson(e)).toList();
        }
        throw const FormatException('Unexpected response format');
      } else {
        throw const NetworkFailure('Failed to fetch countries');
      }
    } catch (e) {
      throw FailureMapper.fromAny(e);
    }
  }
}
