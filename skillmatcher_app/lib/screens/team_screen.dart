import 'package:flutter/material.dart';

import '../services/api_service.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'manager_home_screen.dart';

class TeamScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const TeamScreen({
    super.key,
    required this.user,
  });

  @override
  State<TeamScreen> createState() =>
      _TeamScreenState();
}

class _TeamScreenState
    extends State<TeamScreen> {
  static const Color backgroundColor =
      Color.fromRGBO(87, 57, 57, 0.82);

  static const Color cardColor =
      Color(0xFFE6E0E0);

  static const Color primaryBrown =
      Color(0xFF573939);

  static const Color darkBrown =
      Color(0xFF321414);

  static const Color inputColor =
      Color(0xFFD9D9D9);

  final TextEditingController
      teamNameController =
      TextEditingController();

  final TextEditingController
      inviteCodeController =
      TextEditingController();

  bool isCreating = false;
  bool isJoining = false;

  String? errorMessage;

  // ============================================================
  // CREATE TEAM
  // ============================================================

  Future<void> createTeam() async {
    final name =
        teamNameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        errorMessage =
            'Inserisci il nome del team';
      });

      return;
    }

    if (isCreating ||
        isJoining) {
      return;
    }

    setState(() {
      isCreating = true;
      errorMessage = null;
    });

    try {
      await ApiService.createTeam(
        name: name,
      );

      final teams =
          await ApiService.getMyTeams();

      if (!mounted) return;

      if (teams.isEmpty) {
        throw Exception(
          'Impossibile recuperare il team appena creato',
        );
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              ManagerHomeScreen(
            user: widget.user,
            teams: teams,
          ),
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
          isCreating = false;
        });
      }
    }
  }

  // ============================================================
  // JOIN TEAM
  // ============================================================

  Future<void> joinTeam() async {
    final inviteCode =
        inviteCodeController.text
            .trim();

    if (inviteCode.isEmpty) {
      setState(() {
        errorMessage =
            'Inserisci il codice del team';
      });

      return;
    }

    if (isCreating ||
        isJoining) {
      return;
    }

    setState(() {
      isJoining = true;
      errorMessage = null;
    });

    try {
      await ApiService.joinTeam(
        inviteCode: inviteCode,
      );

      final teams =
          await ApiService.getMyTeams();

      if (!mounted) return;

      if (teams.isEmpty) {
        throw Exception(
          'Impossibile recuperare il team',
        );
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              HomeScreen(
            user: widget.user,
            teams: teams,
          ),
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
          isJoining = false;
        });
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await ApiService.logout();

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
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    teamNameController.dispose();
    inviteCodeController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final String userName =
        widget.user['name']
                ?.toString() ??
            'Utente';

    return Scaffold(
      backgroundColor:
          backgroundColor,

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 28,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 620,
              ),

              child: Column(
                children: [
                  // ===============================================
                  // LOGO
                  // ===============================================

                  Image.asset(
                    'assets/images/logo.png',
                    width: 190,
                    height: 190,
                    fit:
                        BoxFit.contain,
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  // ===============================================
                  // GREETING
                  // ===============================================

                  Text(
                    'Ciao $userName!',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 27,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'Non appartieni ancora a nessun team.',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  const Text(
                    'Puoi creare un nuovo team oppure entrare in uno esistente tramite il codice di invito.',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  // ===============================================
                  // MAIN CARD
                  // ===============================================

                  Container(
                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 30,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          cardColor,

                      borderRadius:
                          BorderRadius.circular(
                        45,
                      ),

                      boxShadow:
                          const [
                        BoxShadow(
                          color:
                              Colors.black12,
                          blurRadius:
                              15,
                          offset:
                              Offset(
                            0,
                            7,
                          ),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        // =========================================
                        // CREATE TEAM
                        // =========================================

                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .add_business_outlined,
                              color:
                                  primaryBrown,
                              size: 27,
                            ),

                            SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                'CREA UN TEAM',
                                style:
                                    TextStyle(
                                  color:
                                      primaryBrown,
                                  fontSize:
                                      19,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Align(
                          alignment:
                              Alignment.centerLeft,
                          child: Text(
                            'Creando un team ne diventerai il manager.',
                            style:
                                TextStyle(
                              color:
                                  primaryBrown,
                              fontSize:
                                  12,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        TextField(
                          controller:
                              teamNameController,

                          textInputAction:
                              TextInputAction.done,

                          onSubmitted:
                              (_) {
                            if (!isCreating &&
                                !isJoining) {
                              createTeam();
                            }
                          },

                          decoration:
                              InputDecoration(
                            hintText:
                                'Nome del team',

                            prefixIcon:
                                const Icon(
                              Icons
                                  .business_outlined,
                              color:
                                  primaryBrown,
                            ),

                            filled:
                                true,

                            fillColor:
                                inputColor,

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                              borderSide:
                                  BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          height: 46,

                          child:
                              ElevatedButton.icon(
                            onPressed:
                                isCreating ||
                                        isJoining
                                    ? null
                                    : createTeam,

                            icon:
                                isCreating
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
                                    : const Icon(
                                        Icons.add,
                                      ),

                            label:
                                Text(
                              isCreating
                                  ? 'CREAZIONE...'
                                  : 'CREA TEAM',
                            ),

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  primaryBrown,

                              foregroundColor:
                                  Colors.white,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  22,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        // =========================================
                        // OR
                        // =========================================

                        const Row(
                          children: [
                            Expanded(
                              child:
                                  Divider(),
                            ),

                            Padding(
                              padding:
                                  EdgeInsets.symmetric(
                                horizontal:
                                    14,
                              ),
                              child:
                                  Text(
                                'OPPURE',
                                style:
                                    TextStyle(
                                  color:
                                      primaryBrown,
                                  fontSize:
                                      12,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),

                            Expanded(
                              child:
                                  Divider(),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        // =========================================
                        // JOIN TEAM
                        // =========================================

                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .group_add_outlined,
                              color:
                                  primaryBrown,
                              size: 27,
                            ),

                            SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                'ENTRA IN UN TEAM',
                                style:
                                    TextStyle(
                                  color:
                                      primaryBrown,
                                  fontSize:
                                      19,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Align(
                          alignment:
                              Alignment.centerLeft,
                          child: Text(
                            'Inserisci il codice condiviso dal manager del team.',
                            style:
                                TextStyle(
                              color:
                                  primaryBrown,
                              fontSize:
                                  12,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        TextField(
                          controller:
                              inviteCodeController,

                          textInputAction:
                              TextInputAction.done,

                          onSubmitted:
                              (_) {
                            if (!isCreating &&
                                !isJoining) {
                              joinTeam();
                            }
                          },

                          decoration:
                              InputDecoration(
                            hintText:
                                'Codice team',

                            prefixIcon:
                                const Icon(
                              Icons
                                  .vpn_key_outlined,
                              color:
                                  primaryBrown,
                            ),

                            filled:
                                true,

                            fillColor:
                                inputColor,

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                              borderSide:
                                  BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          height: 46,

                          child:
                              ElevatedButton.icon(
                            onPressed:
                                isCreating ||
                                        isJoining
                                    ? null
                                    : joinTeam,

                            icon:
                                isJoining
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
                                    : const Icon(
                                        Icons
                                            .login,
                                      ),

                            label:
                                Text(
                              isJoining
                                  ? 'ACCESSO...'
                                  : 'ENTRA NEL TEAM',
                            ),

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  primaryBrown,

                              foregroundColor:
                                  Colors.white,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  22,
                                ),
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
                            height: 18,
                          ),

                          Container(
                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets.all(
                              12,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.redAccent
                                      .withValues(
                                alpha: 0.10,
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),

                            child:
                                Text(
                              errorMessage!,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.redAccent,
                                fontSize:
                                    12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ===============================================
                  // LOGOUT
                  // ===============================================

                  TextButton.icon(
                    onPressed:
                        isCreating ||
                                isJoining
                            ? null
                            : logout,

                    icon:
                        const Icon(
                      Icons.logout,
                      color:
                          Colors.white,
                      size: 18,
                    ),

                    label:
                        const Text(
                      'Esci dall’account',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
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