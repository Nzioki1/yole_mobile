import 'dart:convert';
import 'yole_api_service.dart';
import '../models/api/country.dart';
import '../models/api/system_status.dart';
import '../models/api/error_response.dart';

/// Data service for YOLE backend
class DataService {
  final YoleApiService _api;

  DataService({required YoleApiService api}) : _api = api;

  /// Get countries list
  Future<List<Country>> getCountries() async {
    try {
      print('Requesting countries...');
      final response = await _api.get('/countries');

      print('Countries response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Countries response data: $responseData');

        // Handle different response formats
        List<dynamic> countries;
        if (responseData is List) {
          countries = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          countries = responseData['data'] ?? [];
        } else if (responseData is Map &&
            responseData.containsKey('countries')) {
          countries = responseData['countries'] ?? [];
        } else {
          print('Unexpected countries response format: $responseData');
          countries = [];
        }

        print('Parsed ${countries.length} countries');
        return countries.map((json) => Country.fromJson(json)).toList();
      } else {
        print('Countries error: ${response.body}');
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      print('Countries exception: $e');
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to get countries: $e');
    }
  }

  /// Get system status
  Future<SystemStatus> getStatus() async {
    try {
      final response = await _api.get('/status');

      if (response.statusCode == 200) {
        return SystemStatus.fromJson(jsonDecode(response.body));
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to get system status: $e');
    }
  }

  /// Get countries with caching
  Future<List<Country>> getCountriesCached() async {
    // In a real implementation, you might want to cache this data
    // For now, just call the API directly
    return getCountries();
  }

  /// Search countries by name
  Future<List<Country>> searchCountries(String query) async {
    try {
      final response = await _api.get('/countries?search=$query');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> countries = data['data'] ?? [];
        return countries.map((json) => Country.fromJson(json)).toList();
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to search countries: $e');
    }
  }

  /// Get country by code
  Future<Country?> getCountryByCode(String code) async {
    try {
      final response = await _api.get('/countries/$code');

      if (response.statusCode == 200) {
        return Country.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to get country: $e');
    }
  }
}
