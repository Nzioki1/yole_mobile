import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_api.dart';
import '../features/recipients/data/recipients_repository.dart';
import '../features/recipients/data/recipients_api.dart';
import '../features/transfer/data/transfer_repository.dart';
import '../features/transfer/data/transfer_api.dart';
import '../features/auth/data/kyc_api.dart';
import '../core/network/dio_client.dart';

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('AuthRepository not provided');
});

final recipientsRepositoryProvider = Provider<RecipientsRepository>((ref) {
  throw UnimplementedError('RecipientsRepository not provided');
});

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  throw UnimplementedError('TransferRepository not provided');
});

// API providers
final dioClientProvider = Provider<Dio>((ref) => DioClient().dio);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.read(dioClientProvider)),
);

final recipientsApiProvider = Provider<RecipientsApi>(
  (ref) => RecipientsApi(ref.read(dioClientProvider)),
);

final transferApiProvider = Provider<TransferApi>(
  (ref) => TransferApi(ref.read(dioClientProvider)),
);

final kycApiProvider = Provider<KycApi>(
  (ref) => KycApi(ref.read(dioClientProvider)),
);
