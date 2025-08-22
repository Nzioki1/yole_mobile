import 'package:flutter/material.dart';
import '../../../core/i18n/generated/l10n.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../core/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.signup)),
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
              PrimaryButton(label: t.signup, onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: call signup
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}