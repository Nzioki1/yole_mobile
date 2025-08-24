import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/generated/l10n.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../core/utils/validators.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final state = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return LoadingOverlay(
      isLoading: state.loading,
      child: Scaffold(
        appBar: AppBar(title: Text(t.login)),
        body: Column(
          children: [
            if (state.error != null) 
              ErrorBanner(message: state.error!.message),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: t.email, 
                        controller: _email, 
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: t.password, 
                        controller: _password, 
                        obscureText: true, 
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: t.login,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            notifier.login(_email.text, _password.text);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}