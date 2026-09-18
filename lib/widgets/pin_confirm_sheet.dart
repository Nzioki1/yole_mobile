import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/biometric_provider.dart';

/// PIN Confirm Bottom Sheet - Used to verify transaction PIN
class PinConfirmSheet extends StatefulWidget {
  final String title;
  final String message;
  final Function(String pin) onPinEntered;

  const PinConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.onPinEntered,
  });

  @override
  State<PinConfirmSheet> createState() => _PinConfirmSheetState();

  /// Show the PIN confirm sheet
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PinConfirmSheet(
        title: title,
        message: message,
        onPinEntered: (pin) => Navigator.of(context).pop(pin),
      ),
    );
  }
}

class _PinConfirmSheetState extends State<PinConfirmSheet> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty && index > 0) {
      // Backspace - move to previous field
      _focusNodes[index - 1].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      // Move to next field
      _focusNodes[index + 1].requestFocus();
    } else if (value.isNotEmpty && index == 5) {
      // Last digit entered - submit
      _submitPin();
    }
  }

  void _submitPin() {
    final pin = _controllers.map((c) => c.text).join();
    if (pin.length < 4) {
      setState(() => _error = 'Please enter at least 4 digits');
      return;
    }
    widget.onPinEntered(pin);
  }

  Future<void> _useBiometric() async {
    final container = ProviderContainer();
    final biometricService = container.read(biometricAuthServiceProvider);

    final enabled = await biometricService.isEnabled();
    final available = await biometricService.canCheckBiometrics();

    if (!enabled || !available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      container.dispose();
      return;
    }

    final authenticated = await biometricService.authenticate(
      reason: 'Confirm transaction',
    );

    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
      container.dispose();
      return;
    }

    final payload = await biometricService.getUnlockPayload();
    container.dispose();

    if (payload == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No biometric credentials stored'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      widget.onPinEntered(payload.transactionPin);
    }
  }

  Future<bool> _shouldShowBiometricButton() async {
    final container = ProviderContainer();
    final biometricService = container.read(biometricAuthServiceProvider);

    final enabled = await biometricService.isEnabled();
    final available = await biometricService.canCheckBiometrics();

    container.dispose();
    return enabled && available;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            widget.message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // PIN input fields
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                width: 45,
                height: 55,
                margin: EdgeInsets.symmetric(
                  horizontal: index == 2 ? 12 : 4,
                ),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (value) => _onDigitChanged(index, value),
                ),
              );
            }),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),

          // Biometric button (conditional)
          FutureBuilder<bool>(
            future: _shouldShowBiometricButton(),
            builder: (context, snapshot) {
              final showButton = snapshot.data ?? false;
              if (!showButton) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _useBiometric,
                    icon: const Icon(Icons.fingerprint, size: 28),
                    label: const Text('Use Biometric'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

          // Confirm button
          ElevatedButton(
            onPressed: _isLoading ? null : _submitPin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm', style: TextStyle(fontSize: 16)),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
