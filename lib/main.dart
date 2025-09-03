import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');
    print('🔍 Main: Environment variables loaded successfully');
  } catch (e) {
    print('🔍 Main: Error loading environment variables: $e');
    // Continue without environment variables for now
  }

  runApp(const YoleAppWithProviders());
}
