import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manager_home_screen.dart';
import 'screens/team_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const SkillMatcherApp());
}

class SkillMatcherApp extends StatelessWidget {
  const SkillMatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillMatcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    checkAuthentication();
  }

  Future<void> checkAuthentication() async {
    final token = await ApiService.getToken();

    if (token == null) {
      goToLogin();
      return;
    }

    try {
      final user = await ApiService.getCurrentUser();
      final teams = await ApiService.getMyTeams();

      if (!mounted) return;

      if (teams.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeamScreen(
              user: user,
            ),
          ),
        );
        return;
      }

      goToCorrectHome(
        user: user,
        teams: teams,
      );
    } catch (e) {
      await ApiService.logout();

      if (!mounted) return;

      goToLogin();
    }
  }

  void goToCorrectHome({
    required Map<String, dynamic> user,
    required List<dynamic> teams,
  }) {
    final team = teams.first;

    final String role =
        team['role']?.toString().toLowerCase() ?? '';

    if (role == 'manager') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ManagerHomeScreen(
            user: user,
            teams: teams,
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          user: user,
          teams: teams,
        ),
      ),
    );
  }

  void goToLogin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromRGBO(
        87,
        57,
        57,
        0.82,
      ),
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}