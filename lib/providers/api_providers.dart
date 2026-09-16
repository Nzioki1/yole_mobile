import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/yole_api_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/core_api_service.dart';
import '../services/core_auth_service.dart';
import '../services/transaction_service.dart';
import '../services/data_service.dart';

/// Provider for YoleApiService (old backend - not used)
final yoleApiServiceProvider = Provider<YoleApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return YoleApiService(storage: storage);
});

/// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for CoreApiService (mock NestJS backend)
final coreApiServiceProvider = Provider<CoreApiService>((ref) {
  final service = CoreApiService();
  // Initialize to load stored token
  service.init();
  return service;
});

/// Provider for CoreAuthService (uses mock NestJS backend)
final coreAuthServiceProvider = Provider<CoreAuthService>((ref) {
  final api = ref.watch(coreApiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return CoreAuthService(api: api, storage: storage);
});

/// Provider for AuthService (old backend - not used)
final oldAuthServiceProvider = Provider<AuthService>((ref) {
  final api = ref.watch(yoleApiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthService(api: api, storage: storage);
});

/// Provider for AuthService (currently using CoreAuthService)
final authServiceProvider = Provider<CoreAuthService>((ref) {
  return ref.watch(coreAuthServiceProvider);
});

/// Provider for TransactionService
final transactionServiceProvider = Provider<TransactionService>((ref) {
  final api = ref.watch(yoleApiServiceProvider);
  return TransactionService(api: api);
});

/// Provider for DataService
final dataServiceProvider = Provider<DataService>((ref) {
  final api = ref.watch(yoleApiServiceProvider);
  return DataService(api: api);
});

/// Note: KycService provider is defined in kyc_provider.dart
/// Import kyc_provider.dart to use kycServiceProvider
