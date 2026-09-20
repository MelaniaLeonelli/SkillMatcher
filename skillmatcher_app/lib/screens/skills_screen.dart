import 'package:flutter/material.dart';

import '../services/api_service.dart';

import 'home_screen.dart';
import 'profile_screen.dart';
import 'task_screen.dart';

class SkillsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> teams;

  const SkillsScreen({
    super.key,
    required this.user,
    required this.teams,
  });

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  static const Color backgroundColor =
      Color.fromRGBO(87, 57, 57, 0.82);

  static const Color primaryBrown =
      Color(0xFF573939);

  static const Color darkBrown =
      Color(0xFF321414);

  static const Color cardColor =
      Color(0xFFE6E0E0);

  static const Color inputColor =
      Color(0xFFD9D9D9);

  bool isLoading = true;
  bool isCreatingSkill = false;

  String? errorMessage;

  List<dynamic> catalogSkills = [];
  List<dynamic> mySkills = [];

  final TextEditingController newSkillController =
      TextEditingController();

  // ============================================================
  // TEAM
  // ============================================================

  int get teamId {
    return widget.teams.first['team_id'];
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadSkills();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    newSkillController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD SKILLS
  // ============================================================

  Future<void> loadSkills() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final catalog =
          await ApiService.getTeamSkills(
        teamId,
      );

      final employeeSkills =
          await ApiService.getMySkills();

      if (!mounted) return;

      setState(() {
        catalogSkills = catalog;
        mySkills = employeeSkills;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // EMPLOYEE SKILL HELPERS
  // ============================================================

  Map<String, dynamic>? getEmployeeSkill(
    int skillId,
  ) {
    for (final skill in mySkills) {
      if (skill['skill_id'] == skillId) {
        return Map<String, dynamic>.from(
          skill,
        );
      }
    }

    return null;
  }

  bool hasSkill(
    int skillId,
  ) {
    return getEmployeeSkill(
          skillId,
        ) !=
        null;
  }

  int getSkillLevel(
    int skillId,
  ) {
    final employeeSkill =
        getEmployeeSkill(
      skillId,
    );

    if (employeeSkill == null) {
      return 0;
    }

    return (employeeSkill['level'] as num?)
            ?.toInt() ??
        1;
  }

  // ============================================================
  // ADD EXISTING SKILL TO PROFILE
  // ============================================================

  Future<void> addSkillToProfile(
    Map<String, dynamic> skill,
  ) async {
    int selectedLevel = 1;

    final result =
        await showDialog<int>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                skill['name']
                        ?.toString() ??
                    'Competenza',
              ),

              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Indica il tuo livello per questa competenza:',
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value:
                              selectedLevel
                                  .toDouble(),

                          min: 1,

                          max: 5,

                          divisions: 4,

                          label:
                              '$selectedLevel/5',

                          activeColor:
                              primaryBrown,

                          onChanged:
                              (value) {
                            setDialogState(
                              () {
                                selectedLevel =
                                    value
                                        .round();
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Text(
                        '$selectedLevel/5',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children:
                        List.generate(
                      5,
                      (
                        index,
                      ) {
                        return Icon(
                          index <
                                  selectedLevel
                              ? Icons.star
                              : Icons.star_border,
                          color:
                              primaryBrown,
                        );
                      },
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text(
                    'Annulla',
                  ),
                ),

                ElevatedButton(
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        primaryBrown,
                    foregroundColor:
                        Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      selectedLevel,
                    );
                  },
                  child:
                      const Text(
                    'Aggiungi',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    try {
      await ApiService.addEmployeeSkill(
        userId: widget.user['id'],
        skillId: skill['id'],
        level: result,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            '${skill['name']} aggiunta al profilo',
          ),
        ),
      );

      await loadSkills();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // REMOVE SKILL FROM PROFILE
  // ============================================================

  Future<void> removeSkillFromProfile(
    Map<String, dynamic> skill,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Rimuovi skill',
          ),

          content: Text(
            'Vuoi rimuovere "${skill['name']}" dal tuo profilo?\n\n'
            'La skill resterà comunque disponibile nel catalogo condiviso.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Annulla',
              ),
            ),

            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Rimuovi',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiService.removeMySkill(
        skill['id'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            '${skill['name']} rimossa dal profilo',
          ),
        ),
      );

      await loadSkills();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // CREATE NEW SKILL IN CATALOG
  // ============================================================

  Future<void> createNewSkill() async {
    final name =
        newSkillController.text.trim();

    if (name.isEmpty) {
      setState(() {
        errorMessage =
            'Inserisci il nome della nuova skill';
      });

      return;
    }

    if (isCreatingSkill) {
      return;
    }

    setState(() {
      isCreatingSkill = true;
      errorMessage = null;
    });

    try {
      final createdSkill =
          await ApiService.createSkill(
        name: name,
        teamId: teamId,
      );

      newSkillController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            '${createdSkill['name'] ?? name} aggiunta al catalogo',
          ),
        ),
      );

      await loadSkills();
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage!,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCreatingSkill = false;
        });
      }
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void openHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) =>
            HomeScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
      (
        route,
      ) =>
          false,
    );
  }

  void openTasks() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) =>
            TaskScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  void openProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) =>
            ProfileScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            _buildNavigation(),

            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Colors.white,
                      ),
                    )
                  : errorMessage !=
                              null &&
                          catalogSkills
                              .isEmpty
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: openHome,
        backgroundColor:
            cardColor,
        foregroundColor:
            primaryBrown,
        tooltip: 'Home',
        child: const Icon(
          Icons.home_outlined,
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: loadSkills,

      child:
          SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),

        child: Center(
          child: Container(
            width:
                double.infinity,

            constraints:
                const BoxConstraints(
              maxWidth: 700,
            ),

            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 30,
              vertical: 30,
            ),

            decoration:
                BoxDecoration(
              color:
                  cardColor,

              borderRadius:
                  BorderRadius
                      .circular(
                50,
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
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                // ===============================================
                // HEADER
                // ===============================================

                const Row(
                  children: [
                    Icon(
                      Icons
                          .settings_suggest_outlined,
                      color:
                          primaryBrown,
                      size: 30,
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Text(
                        'CATALOGO SKILLS',
                        style:
                            TextStyle(
                          fontSize:
                              22,
                          fontWeight:
                              FontWeight
                                  .w500,
                          color:
                              primaryBrown,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'Catalogo condiviso delle competenze disponibili nel team. '
                  'Le skill possono essere associate al profilo dei dipendenti '
                  'e utilizzate come requisiti dei task.',
                  style:
                      TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color:
                        primaryBrown,
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // ===============================================
                // CREATE SKILL
                // ===============================================

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets
                          .all(
                    18,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color
                            .fromRGBO(
                      87,
                      57,
                      57,
                      0.07,
                    ),

                    borderRadius:
                        BorderRadius
                            .circular(
                      22,
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Aggiungi nuova competenza',
                        style:
                            TextStyle(
                          fontSize:
                              16,
                          fontWeight:
                              FontWeight
                                  .w500,
                          color:
                              primaryBrown,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'La nuova skill verrà aggiunta al catalogo condiviso del team.',
                        style:
                            TextStyle(
                          fontSize:
                              12,
                          color:
                              primaryBrown,
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child:
                                TextField(
                              controller:
                                  newSkillController,

                              onSubmitted:
                                  (_) {
                                createNewSkill();
                              },

                              decoration:
                                  InputDecoration(
                                hintText:
                                    'Nome nuova skill...',

                                filled:
                                    true,

                                fillColor:
                                    inputColor,

                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      14,
                                  vertical:
                                      14,
                                ),

                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    14,
                                  ),
                                  borderSide:
                                      BorderSide
                                          .none,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          SizedBox(
                            width: 52,
                            height: 52,
                            child:
                                ElevatedButton(
                              onPressed:
                                  isCreatingSkill
                                      ? null
                                      : createNewSkill,

                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    primaryBrown,
                                foregroundColor:
                                    Colors.white,

                                padding:
                                    EdgeInsets.zero,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    14,
                                  ),
                                ),
                              ),

                              child:
                                  isCreatingSkill
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
                                      : const Icon(
                                          Icons.add,
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                const Divider(),

                const SizedBox(
                  height: 15,
                ),

                const Text(
                  'Competenze disponibili',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w500,
                    color:
                        primaryBrown,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                if (catalogSkills.isEmpty)
                  _buildEmptyCatalog()
                else
                  ...catalogSkills.map(
                    (
                      skill,
                    ) {
                      return _buildSkillCard(
                        Map<String,
                                dynamic>.from(
                          skill,
                        ),
                      );
                    },
                  ),

                if (errorMessage !=
                    null) ...[
                  const SizedBox(
                    height: 18,
                  ),

                  Text(
                    errorMessage!,
                    style:
                        const TextStyle(
                      color:
                          Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SKILL CARD
  // ============================================================

  Widget _buildSkillCard(
    Map<String, dynamic> skill,
  ) {
    final int id =
        skill['id'];

    final String name =
        skill['name']
                ?.toString() ??
            'Competenza';

    final bool possessed =
        hasSkill(
      id,
    );

    final int level =
        getSkillLevel(
      id,
    );

    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color.fromRGBO(
          87,
          57,
          57,
          0.07,
        ),

        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,

            decoration:
                const BoxDecoration(
              color:
                  Color.fromRGBO(
                87,
                57,
                57,
                0.12,
              ),
              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons.school_outlined,
              color:
                  primaryBrown,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w500,
                    color:
                        darkBrown,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                if (possessed)
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (
                          index,
                        ) {
                          return Icon(
                            index < level
                                ? Icons.star
                                : Icons
                                    .star_border,
                            size: 18,
                            color:
                                primaryBrown,
                          );
                        },
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Text(
                        '$level/5',
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              primaryBrown,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Non associata al tuo profilo',
                    style:
                        TextStyle(
                      fontSize: 12,
                      color:
                          primaryBrown,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          if (possessed)
            Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color
                            .fromRGBO(
                      87,
                      57,
                      57,
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),

                  child:
                      const Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color:
                            primaryBrown,
                      ),
                      SizedBox(
                        width: 4,
                      ),
                      Text(
                        'Posseduta',
                        style:
                            TextStyle(
                          fontSize:
                              11,
                          color:
                              primaryBrown,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                IconButton(
                  tooltip:
                      'Rimuovi dal profilo',
                  onPressed: () {
                    removeSkillFromProfile(
                      skill,
                    );
                  },
                  icon: const Icon(
                    Icons
                        .delete_outline,
                    color:
                        Colors.redAccent,
                  ),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                addSkillToProfile(
                  skill,
                );
              },

              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    primaryBrown,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),

              icon: const Icon(
                Icons.add,
                size: 17,
              ),

              label:
                  const Text(
                'Aggiungi',
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyCatalog() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        vertical: 40,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 55,
              color:
                  primaryBrown,
            ),

            SizedBox(
              height: 15,
            ),

            Text(
              'Il catalogo delle competenze è vuoto.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 15,
                color:
                    primaryBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color:
                  Colors.white,
              size: 60,
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              errorMessage ??
                  'Errore',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
                  loadSkills,
              child:
                  const Text(
                'Riprova',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION BAR
  // ============================================================

  Widget _buildNavigation() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 10,
      ),

      decoration:
          const BoxDecoration(
        color:
            Color.fromRGBO(
          217,
          217,
          217,
          0.10,
        ),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
        children: [
          SkillsNavigationItem(
            label: 'swipe',
            imagePath:
                'assets/images/logo.png',
            onTap: openHome,
          ),

          SkillsNavigationItem(
            label: 'task',
            icon: Icons
                .assignment_outlined,
            onTap: openTasks,
          ),

          SkillsNavigationItem(
            label: 'skills',
            icon: Icons
                .settings_suggest_outlined,
            selected: true,
            onTap: () {},
          ),

          SkillsNavigationItem(
            label: 'profile',
            icon:
                Icons.person_outline,
            onTap: openProfile,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// NAVIGATION ITEM
// =============================================================

class SkillsNavigationItem
    extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? imagePath;
  final bool selected;
  final VoidCallback onTap;

  const SkillsNavigationItem({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.imagePath,
    this.selected = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(
        30,
      ),

      child: Container(
        padding:
            EdgeInsets.symmetric(
          horizontal:
              selected ? 22 : 18,
          vertical:
              selected ? 10 : 8,
        ),

        decoration:
            BoxDecoration(
          color: selected
              ? const Color
                  .fromRGBO(
                  230,
                  224,
                  224,
                  0.20,
                )
              : Colors.transparent,

          borderRadius:
              BorderRadius.circular(
            30,
          ),
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            if (imagePath !=
                null)
              Image.asset(
                imagePath!,
                width: 48,
                height: 48,
                fit:
                    BoxFit.contain,
              )
            else
              Icon(
                icon,
                size: selected
                    ? 32
                    : 30,
                color:
                    const Color(
                  0xFF321414,
                ),
              ),

            const SizedBox(
              height: 2,
            ),

            Text(
              label,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Color(
                  0xFF321414,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}