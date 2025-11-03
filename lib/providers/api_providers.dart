import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/yole_api_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../services/data_service.dart';

/// Provider for YoleApiService
final yoleApiServiceProvider = Provider<YoleApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return YoleApiService(storage: storage);
});

/// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.watch(yoleApiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthService(api: api, storage: storage);
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
