import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  String? errorMessage;

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> register() async {
    final String name =
        nameController.text.trim();

    final String email =
        emailController.text.trim();

    final String password =
        passwordController.text;

    final String confirmPassword =
        confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        errorMessage =
            'Compila tutti i campi';
      });

      return;
    }

    if (!email.contains('@') ||
        !email.contains('.')) {
      setState(() {
        errorMessage =
            'Inserisci un indirizzo email valido';
      });

      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage =
            'La password deve contenere almeno 6 caratteri';
      });

      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage =
            'Le password non coincidono';
      });

      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ApiService.register(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (
          dialogContext,
        ) {
          return AlertDialog(
            title: const Text(
              'Registrazione completata',
            ),
            content: const Text(
              'Il tuo account è stato creato con successo. Ora puoi effettuare il login.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'OK',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              const LoginScreen(),
        ),
        (
          route,
        ) =>
            false,
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

  // ============================================================
  // LOGIN
  // ============================================================

  void goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) =>
            const LoginScreen(),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

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
        width:
            double.infinity,
        height:
            double.infinity,

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
              padding:
                  const EdgeInsets.symmetric(
                vertical: 25,
              ),

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  // ===============================================
                  // LOGO
                  // ===============================================

                  Image.asset(
                    'assets/images/logo.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // ===============================================
                  // REGISTER CARD
                  // ===============================================

                  Container(
                    width: 340,

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 28,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color.fromRGBO(
                        238,
                        237,
                        237,
                        0.36,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        50,
                      ),
                    ),

                    child: Column(
                      children: [
                        const Text(
                          'SIGN UP',
                          style:
                              TextStyle(
                            fontFamily:
                                'Inter',
                            fontSize:
                                20,
                            fontWeight:
                                FontWeight.w400,
                            color:
                                Colors.white,
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        // =========================================
                        // NAME
                        // =========================================

                        _buildTextField(
                          controller:
                              nameController,
                          hintText:
                              'Nome e Cognome',
                          icon:
                              Icons.person_outline,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // =========================================
                        // EMAIL
                        // =========================================

                        _buildTextField(
                          controller:
                              emailController,
                          hintText:
                              'Email',
                          icon:
                              Icons.email_outlined,
                          keyboardType:
                              TextInputType.emailAddress,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // =========================================
                        // PASSWORD
                        // =========================================

                        _buildPasswordField(
                          controller:
                              passwordController,
                          hintText:
                              'Password',
                          obscure:
                              obscurePassword,
                          onToggle: () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword;
                            });
                          },
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // =========================================
                        // CONFIRM PASSWORD
                        // =========================================

                        _buildPasswordField(
                          controller:
                              confirmPasswordController,
                          hintText:
                              'Conferma password',
                          obscure:
                              obscureConfirmPassword,
                          onToggle: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },
                          onSubmitted: (
                            _,
                          ) {
                            if (!isLoading) {
                              register();
                            }
                          },
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // =========================================
                        // REGISTER BUTTON
                        // =========================================

                        SizedBox(
                          width:
                              double.infinity,
                          height: 40,

                          child:
                              ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : register,

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF573939,
                              ),

                              disabledBackgroundColor:
                                  const Color(
                                0xFF573939,
                              ),

                              foregroundColor:
                                  Colors.white,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                              ),
                            ),

                            child:
                                isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'REGISTRATI',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              16,
                                          fontWeight:
                                              FontWeight.w500,
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
                            height: 12,
                          ),

                          Text(
                            errorMessage!,
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
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

                  // ===============================================
                  // LOGIN LINK
                  // ===============================================

                  TextButton(
                    onPressed:
                        goToLogin,

                    child:
                        const Text(
                      'Hai già un account? Accedi',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            14,
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

  // ============================================================
  // NORMAL FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return SizedBox(
      height: 44,

      child: TextField(
        controller:
            controller,

        keyboardType:
            keyboardType,

        decoration:
            InputDecoration(
          hintText:
              hintText,

          hintStyle:
              const TextStyle(
            fontSize:
                15,
            color:
                Colors.black54,
          ),

          prefixIcon:
              Icon(
            icon,
            size:
                19,
          ),

          filled:
              true,

          fillColor:
              const Color(
            0xFFD9D9D9,
          ),

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal:
                12,
            vertical:
                11,
          ),

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            borderSide:
                BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
    ValueChanged<String>?
        onSubmitted,
  }) {
    return SizedBox(
      height: 44,

      child: TextField(
        controller:
            controller,

        obscureText:
            obscure,

        onSubmitted:
            onSubmitted,

        decoration:
            InputDecoration(
          hintText:
              hintText,

          hintStyle:
              const TextStyle(
            fontSize:
                15,
            color:
                Colors.black54,
          ),

          prefixIcon:
              const Icon(
            Icons.lock_outline,
            size:
                19,
          ),

          suffixIcon:
              IconButton(
            padding:
                EdgeInsets.zero,

            icon:
                Icon(
              obscure
                  ? Icons.visibility_off
                  : Icons.visibility,
              size:
                  18,
            ),

            onPressed:
                onToggle,
          ),

          filled:
              true,

          fillColor:
              const Color(
            0xFFD9D9D9,
          ),

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal:
                12,
            vertical:
                11,
          ),

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            borderSide:
                BorderSide.none,
          ),
        ),
      ),
    );
  }
}