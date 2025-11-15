import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/parent_service.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'services/call_service.dart';
import 'services/announcement_service.dart';
import 'services/child_history_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ParentApp());
}

class ParentApp extends StatelessWidget {
  const ParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ParentAuthService()),
        ChangeNotifierProvider(create: (_) => ParentService()),
        ChangeNotifierProvider(create: (_) => AlertService()),
        ChangeNotifierProvider(create: (_) => CallStatusService()),
        ChangeNotifierProvider(create: (_) => AnnouncementService()),
        Provider(create: (_) => ChildHistoryService()),
      ],
      child: Consumer<ParentAuthService>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Tarteel Parent',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
              scaffoldBackgroundColor: const Color(0xFFF8FAFF),
              useMaterial3: true,
            ),
            home: auth.isLoggedIn
                ? const DashboardScreen()
                : LoginScreen(
                    error: auth.error,
                    onLogin: auth.signIn,
                  ),
          );
        },
      ),
    );
  }
}
