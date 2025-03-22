import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/storage/shared_prefs.dart';
import 'core/auth/auth_provider.dart';
import 'core/biometrics/biometric_service.dart';
import 'core/offline/sync_service.dart';
import 'data/local/database_helper.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize services
  final sharedPrefs = await SharedPrefs.init();
  final databaseHelper = await DatabaseHelper.instance;
  final biometricService = BiometricService();
  final syncService = SyncService(databaseHelper);
  
  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(sharedPrefs)),
        Provider.value(value: sharedPrefs),
        Provider.value(value: databaseHelper),
        Provider.value(value: biometricService),
        Provider.value(value: syncService),
      ],
      child: const EducationApp(),
    ),
  );
}