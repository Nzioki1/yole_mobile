import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Ensures the app can read contacts *right now*.
/// - Requests runtime permission when possible.
/// - If permanently denied, offers an 'Open Settings' action.
Future<bool> ensureContactsPermission(BuildContext context) async {
  var status = await Permission.contacts.status;

  // First time or previously denied (but can ask again)? -> request
  if (status.isDenied || status.isRestricted || status.isLimited) {
    status = await Permission.contacts.request();
  }

  if (status.isGranted) return true;

  // Permanently denied: guide user to Settings
  if (status.isPermanentlyDenied) {
    if (!context.mounted) return false;

    final isIOS = Platform.isIOS;
    final msg = isIOS
        ? 'Contacts permission is turned off. Go to Settings > Yole Mobile > Contacts to enable it.'
        : 'Contacts permission is turned off. Go to Settings > Apps > Yole Mobile > Permissions > Contacts.';

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Permission needed',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(msg, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await openAppSettings();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Open Settings'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
    return false;
  }

  // Any other non-granted state (e.g., denied without 'Don't ask again')
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacts permission denied')),
    );
  }
  return false;
}
