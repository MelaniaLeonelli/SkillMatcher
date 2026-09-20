import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'home_screen.dart';
import 'manager_home_screen.dart';
import 'team_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  String? errorMessage;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    final email =
        emailController.text.trim();

    final password =
        passwordController.text;

    if (email.isEmpty ||
        password.isEmpty) {
      setState(() {
        errorMessage =
            'Inserisci email e password';
      });

      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ApiService.login(
        email: email,
        password: password,
      );

      final user =
          await ApiService.getCurrentUser();

      final teams =
          await ApiService.getMyTeams();

      if (!mounted) return;

      if (teams.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TeamScreen(
              user: user,
            ),
          ),
        );

        return;
      }

      final team = teams.first;

      final String role =
          team['role']
                  ?.toString()
                  .toLowerCase() ??
              '';

      debugPrint(
        'LOGIN ROLE: $role',
      );

      if (role == 'manager') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ManagerHomeScreen(
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
          builder: (context) =>
              HomeScreen(
            user: user,
            teams: teams,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color:
            const Color.fromRGBO(
          87,
          57,
          57,
          0.82,
        ),
        child: SafeArea(
          child: Center(
            child:
                SingleChildScrollView(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  // ===============================================
                  // LOGO
                  // ===============================================

                  Image.asset(
                    'assets/images/logo.png',
                    width: 313,
                    height: 313,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // ===============================================
                  // LOGIN CARD
                  // ===============================================

                  Container(
                    width: 311,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 46,
                      vertical: 25,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color
                              .fromRGBO(
                        238,
                        237,
                        237,
                        0.36,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        50,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SIGN IN',
                          style:
                              TextStyle(
                            fontFamily:
                                'Inter',
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .w400,
                            color:
                                Colors.white,
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // =========================================
                        // EMAIL
                        // =========================================

                        SizedBox(
                          height: 41,
                          child:
                              TextField(
                            controller:
                                emailController,
                            keyboardType:
                                TextInputType
                                    .emailAddress,
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'Email',
                              hintStyle:
                                  TextStyle(
                                fontSize:
                                    16,
                                color:
                                    Colors
                                        .black54,
                              ),
                              filled:
                                  true,
                              fillColor:
                                  Color(
                                0xFFD9D9D9,
                              ),
                              contentPadding:
                                  EdgeInsets
                                      .symmetric(
                                horizontal:
                                    12,
                                vertical:
                                    10,
                              ),
                              border:
                                  InputBorder
                                      .none,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // =========================================
                        // PASSWORD
                        // =========================================

                        SizedBox(
                          height: 41,
                          child:
                              TextField(
                            controller:
                                passwordController,
                            obscureText:
                                obscurePassword,
                            onSubmitted:
                                (_) {
                              if (!isLoading) {
                                login();
                              }
                            },
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Password',
                              hintStyle:
                                  const TextStyle(
                                fontSize:
                                    16,
                                color:
                                    Colors
                                        .black54,
                              ),
                              filled:
                                  true,
                              fillColor:
                                  const Color(
                                0xFFD9D9D9,
                              ),
                              contentPadding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    12,
                                vertical:
                                    10,
                              ),
                              border:
                                  InputBorder
                                      .none,
                              suffixIcon:
                                  IconButton(
                                padding:
                                    EdgeInsets
                                        .zero,
                                icon:
                                    Icon(
                                  obscurePassword
                                      ? Icons
                                          .visibility_off
                                      : Icons
                                          .visibility,
                                  size:
                                      18,
                                ),
                                onPressed:
                                    () {
                                  setState(
                                    () {
                                      obscurePassword =
                                          !obscurePassword;
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // =========================================
                        // LOGIN BUTTON
                        // =========================================

                        SizedBox(
                          width: 219,
                          height: 33,
                          child:
                              ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : login,
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF573939,
                              ),
                              disabledBackgroundColor:
                                  const Color(
                                0xFF573939,
                              ),
                              foregroundColor:
                                  Colors
                                      .white,
                              padding:
                                  EdgeInsets
                                      .zero,
                              shape:
                                  const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .zero,
                              ),
                            ),
                            child:
                                isLoading
                                    ? const SizedBox(
                                        width:
                                            18,
                                        height:
                                            18,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'LOGIN',
                                        style:
                                            TextStyle(
                                          fontFamily:
                                              'Inter',
                                          fontSize:
                                              20,
                                          fontWeight:
                                              FontWeight.w400,
                                        ),
                                      ),
                          ),
                        ),

                        // =========================================
                        // ERROR
                        // =========================================

                        if (errorMessage !=
                            null) ...[
                          const SizedBox(
                            height: 10,
                          ),

                          Text(
                            errorMessage!,
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                const TextStyle(
                              color:
                                  Colors
                                      .white,
                              fontSize:
                                  12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  TextButton(
                    onPressed: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const RegisterScreen(),
                      ),
                    );
                    },
                    child:
                        const Text(
                      'Non hai un account? Registrati',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}