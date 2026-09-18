import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Show PIN input modal and validate against hardcoded PIN 123456.
/// Returns true if PIN is correct, false if user exhausted attempts.
Future<bool> showPinModal(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _PinInputDialog(),
      ) ??
      false;
}

class _PinInputDialog extends StatefulWidget {
  const _PinInputDialog();

  @override
  State<_PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<_PinInputDialog> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  static const _correctPin = '123456';
  int _attempts = 0;
  String? _error;
  bool _loading = false;

  void _validate() {
    final pin = _pinController.text.trim();

    if (pin.isEmpty) {
      setState(() => _error = 'Please enter PIN');
      return;
    }

    if (pin.length != 6) {
      setState(() => _error = 'PIN must be 6 digits');
      return;
    }

    setState(() => _loading = true);

    // Simulate brief validation delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (pin == _correctPin) {
        Navigator.pop(context, true);
      } else {
        _attempts++;
        if (_attempts >= 3) {
          setState(() {
            _error = 'Too many attempts. Try again in 60s.';
            _loading = false;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context, false);
            }
          });
        } else {
          setState(() {
            _error = 'Invalid PIN. ${3 - _attempts} attempt(s) remaining.';
            _loading = false;
          });
          _pinController.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock, color: Colors.blue),
          SizedBox(width: 8),
          Text('Enter Agent PIN'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your 6-digit PIN to authorize this transaction.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pinController,
              decoration: const InputDecoration(
                labelText: 'PIN',
                hintText: '••••••',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              enabled: !_loading && _attempts < 3,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onFieldSubmitted: (_) => _validate(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _attempts >= 3 ? Icons.block : Icons.error,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading || _attempts >= 3 ? null : _validate,
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
