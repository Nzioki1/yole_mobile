import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router/app_router.dart';
import 'core/i18n/generated/l10n.dart';
import 'core/providers.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/recipients/data/recipients_repository.dart';
import 'features/transfer/data/transfer_repository.dart';
import 'features/auth/data/token_store_adapter.dart';

class YoleApp extends ConsumerWidget {
  const YoleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Yole Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      builder: (context, child) {
        // Add error boundary to catch any rendering errors
        return Material(
          child:
              child ??
              const Scaffold(body: Center(child: Text('App failed to load'))),
        );
      },
    );
  }
}

// Provider overrides to fix "not provided" errors
class YoleAppWithProviders extends StatelessWidget {
  const YoleAppWithProviders({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        // Override the repository providers with actual implementations
        authRepositoryProvider.overrideWith(
          (ref) => AuthRepository(
            ref.read(authApiProvider),
            tokenStore: TokenStoreAdapter(),
          ),
        ),
        recipientsRepositoryProvider.overrideWith(
          (ref) => RecipientsRepository(ref.read(recipientsApiProvider)),
        ),
        transferRepositoryProvider.overrideWith(
          (ref) => TransferRepository(ref.read(transferApiProvider)),
        ),
      ],
      child: const YoleApp(),
    );
  }
}
