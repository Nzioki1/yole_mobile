import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/generated/l10n.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_text_field.dart';
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
  Widget build(BuildContext context) {
    final t = S.of(context);
    final state = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(t.login)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(label: t.email, controller: _email, validator: Validators.email),
              const SizedBox(height: 12),
              AppTextField(label: t.password, controller: _password, obscureText: true, validator: Validators.required),
              const SizedBox(height: 24),
              PrimaryButton(
                label: t.login,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    notifier.login(_email.text, _password.text);
                  }
                },
              ),
              if (state.error != null) Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}