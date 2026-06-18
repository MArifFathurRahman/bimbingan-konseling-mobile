import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/themes/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/counseling_provider.dart';
import 'providers/student_provider.dart';
import 'providers/violation_provider.dart';
import 'routes/app_router.dart';
import 'screens/admin/admin_dashboard_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/student/student_dashboard_page.dart';
import 'screens/teacher/wali_kelas_dashboard_page.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.initialize();
  } catch (_) {
    // Firebase unavailable — app will use empty data gracefully
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => CounselingProvider()),
        ChangeNotifierProvider(create: (_) => ViolationProvider()),
      ],
      child: MaterialApp(
        title: 'Binusa SafeSpace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.initialize();
      if (!mounted) return;

      if (!auth.isLoggedIn || auth.user == null) {
        _goToLogin();
        return;
      }

      Widget destination;
      if (auth.user!.isAdmin) {
        destination = const AdminDashboardPage();
      } else if (auth.user!.isWaliKelas) {
        destination = const WaliKelasDashboardPage();
      } else {
        destination = const StudentDashboardPage();
      }
      _replaceWith(destination);
    } catch (_) {
      if (!mounted) return;
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    _replaceWith(const LoginPage());
  }

  void _replaceWith(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFf7f9fb),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF00236f),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Binusa SafeSpace',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00236f),
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Memuat...',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF757682),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
