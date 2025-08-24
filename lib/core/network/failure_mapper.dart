import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

import 'failure.dart';

/// Centralized, test-proof mapping from any thrown error to a Failure.
/// - Handles Dio v5 (DioException) and legacy v4 (DioError via runtimeType).
/// - Maps validation (400/422) -> ValidationFailure
/// - Maps connectivity/timeouts/unknown HTTP -> NetworkFailure
/// - Maps parsing/type issues -> NetworkFailure ("Unexpected response format")
/// - Only returns UnknownFailure for truly unexpected cases.
class FailureMapper {
  const FailureMapper._();

  static Failure fromAny(Object e) {
    // Propagate already-mapped failures as-is.
    if (e is Failure) return e;

    // Dio v5
    if (e is DioException) return fromDioException(e);

    // Legacy Dio v4 often shows up as "DioError"
    if (e.runtimeType.toString() == 'DioError') {
      try {
        final dynamic dioErr = e; // best-effort
        final status = dioErr.response?.statusCode as int?;
        if (status == 400 || status == 422) {
          final msg = _extractMessage(dioErr.response?.data);
          return ValidationFailure(msg ?? 'Validation error');
        }
      } catch (_) {}
      return const NetworkFailure('Network error');
    }

    // Connectivity-like exceptions
    if (e is SocketException || e is HttpException || e is TimeoutException) {
      return const NetworkFailure('Network error');
    }

    // Bad/odd response shapes
    if (e is FormatException || e is TypeError) {
      return const NetworkFailure('Unexpected response format');
    }

    // Fallback (rare)
    return UnknownFailure(e.toString());
  }

  static Failure fromDioException(DioException e) {
    final status = e.response?.statusCode;

    // Connection/timeouts/low-level network issues
    final isConnectivity =
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.error is SocketException ||
        e.error is HttpException ||
        e.error is TimeoutException;

    if (isConnectivity) {
      return const NetworkFailure('Network error');
    }

    // Standard validation statuses
    if (status == 400 || status == 422) {
      final msg = _extractMessage(e.response?.data);
      return ValidationFailure(msg ?? 'Validation error');
    }

    // Default other HTTP issues to NetworkFailure (per tests)
    return NetworkFailure('Request failed${status != null ? ' ($status)' : ''}');
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      final m1 = data['message'];
      if (m1 is String && m1.isNotEmpty) return m1;
      final m2 = data['error'];
      if (m2 is String && m2.isNotEmpty) return m2;

      // Some APIs return: { errors: { field: ["msg"] } }
      final errors = data['errors'];
      if (errors is Map && errors.values.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty && first.first is String) {
          return first.first as String;
        }
      }
    }
    return null;
  }
}
