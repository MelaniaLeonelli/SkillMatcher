import 'package:flutter/material.dart';

import '../services/api_service.dart';

import 'manager_candidates_screen.dart';
import 'manager_dashboard_screen.dart';
import 'manager_home_screen.dart';
import 'manager_navigation.dart';
import 'manager_tasks_screen.dart';
import 'profile_screen.dart';

class CreateTaskScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> teams;

  const CreateTaskScreen({
    super.key,
    required this.user,
    required this.teams,
  });

  @override
  State<CreateTaskScreen> createState() =>
      _CreateTaskScreenState();
}

class _CreateTaskScreenState
    extends State<CreateTaskScreen> {
  // ============================================================
  // COLORS
  // ============================================================

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

  static const Color chipColor =
      Color(0xFFA08F8F);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  final TextEditingController newSkillController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  List<dynamic> teamSkills = [];

  final Set<int> selectedSkillIds = {};

  DateTime? deadline;

  String priority = 'medium';

  bool isLoadingSkills = true;
  bool isCreatingTask = false;
  bool isCreatingSkill = false;

  String? errorMessage;

  // ============================================================
  // TEAM
  // ============================================================

  int get teamId =>
      widget.teams.first['team_id'];

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
    titleController.dispose();
    descriptionController.dispose();
    newSkillController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD TEAM SKILLS
  // ============================================================

  Future<void> loadSkills() async {
    try {
      final result =
          await ApiService.getTeamSkills(
        teamId,
      );

      if (!mounted) return;

      setState(() {
        teamSkills = result;
        isLoadingSkills = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingSkills = false;

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
  // DEADLINE
  // ============================================================

  Future<void> chooseDeadline() async {
    final now = DateTime.now();

    final selectedDate =
        await showDatePicker(
      context: context,
      initialDate:
          deadline ??
              now.add(
                const Duration(
                  days: 7,
                ),
              ),
      firstDate: now,
      lastDate: DateTime(
        now.year + 5,
      ),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      deadline = selectedDate;
    });
  }

  String formatDate(
    DateTime value,
  ) {
    final day =
        value.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        value.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day/$month/${value.year}';
  }

  String backendDate(
    DateTime value,
  ) {
    final day =
        value.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        value.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '${value.year}-$month-$day';
  }

  // ============================================================
  // CREATE NEW SKILL
  // ============================================================

  Future<void> createNewSkill() async {
    final skillName =
        newSkillController.text.trim();

    if (skillName.isEmpty) {
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
      final result =
          await ApiService.createSkill(
        name: skillName,
        teamId: teamId,
      );

      final dynamic createdId =
          result['id'];

      newSkillController.clear();

      await loadSkills();

      if (!mounted) return;

      if (createdId is int) {
        setState(() {
          selectedSkillIds.add(
            createdId,
          );
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Skill aggiunta al team',
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
          isCreatingSkill = false;
        });
      }
    }
  }

  // ============================================================
  // CREATE TASK
  // ============================================================

  Future<void> createTask() async {
    final title =
        titleController.text.trim();

    final description =
        descriptionController.text.trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (title.isEmpty) {
      setState(() {
        errorMessage =
            'Inserisci il titolo del task';
      });

      return;
    }

    if (description.isEmpty) {
      setState(() {
        errorMessage =
            'Inserisci una descrizione';
      });

      return;
    }

    if (deadline == null) {
      setState(() {
        errorMessage =
            'Seleziona una scadenza';
      });

      return;
    }

    if (selectedSkillIds.isEmpty) {
      setState(() {
        errorMessage =
            'Seleziona almeno una skill richiesta';
      });

      return;
    }

    if (isCreatingTask) {
      return;
    }

    // ----------------------------------------------------------
    // CREATE
    // ----------------------------------------------------------

    setState(() {
      isCreatingTask = true;
      errorMessage = null;
    });

    try {
      final createdTask =
          await ApiService.createTask(
        title: title,
        description: description,
        priority: priority,
        deadline:
            backendDate(
          deadline!,
        ),
        teamId: teamId,
      );

      final dynamic createdTaskId =
          createdTask['id'];

      if (createdTaskId is! int) {
        throw Exception(
          'Il backend non ha restituito un ID valido per il task',
        );
      }

      // Associa tutte le skill selezionate
      for (final skillId
          in selectedSkillIds) {
        await ApiService.addTaskSkill(
          taskId: createdTaskId,
          skillId: skillId,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Task creato con successo',
          ),
        ),
      );

      // Dopo la creazione portiamo il manager
      // direttamente nell'elenco dei task.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ManagerTasksScreen(
            user: widget.user,
            teams: widget.teams,
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
          isCreatingTask = false;
        });
      }
    }
  }

  // ============================================================
  // HOME
  // ============================================================

  void openHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManagerHomeScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
      (route) => false,
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
            // ===================================================
            // MANAGER NAVIGATION
            // ===================================================

            ManagerNavigationBar(
              selected:
                  ManagerSection.create,

              onCandidates: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ManagerCandidatesScreen(
                      user:
                          widget.user,
                      teams:
                          widget.teams,
                    ),
                  ),
                );
              },

              onDashboard: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ManagerDashboardScreen(
                      user:
                          widget.user,
                      teams:
                          widget.teams,
                    ),
                  ),
                );
              },

              onCreate: () {},

              onTasks: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ManagerTasksScreen(
                      user:
                          widget.user,
                      teams:
                          widget.teams,
                    ),
                  ),
                );
              },

              onProfile: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileScreen(
                      user:
                          widget.user,
                      teams:
                          widget.teams,
                    ),
                  ),
                );
              },
            ),

            // ===================================================
            // CONTENT
            // ===================================================

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 20,
                  vertical: 25,
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
                      horizontal: 32,
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
                              Colors
                                  .black12,
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
                        // =======================================
                        // TITLE
                        // =======================================

                        const Center(
                          child: Text(
                            'CREARE NUOVA TASK',
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

                        const SizedBox(
                          height: 28,
                        ),

                        // =======================================
                        // TASK TITLE
                        // =======================================

                        const FormLabel(
                          text: 'Titolo',
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        TextField(
                          controller:
                              titleController,
                          decoration:
                              inputDecoration(
                            hint:
                                'Scrivi il titolo del task',
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // =======================================
                        // DESCRIPTION
                        // =======================================

                        const FormLabel(
                          text:
                              'Descrizione',
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        TextField(
                          controller:
                              descriptionController,
                          minLines: 4,
                          maxLines: 6,
                          decoration:
                              inputDecoration(
                            hint:
                                'Scrivere qui...',
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        // =======================================
                        // DEADLINE / PRIORITY
                        // =======================================

                        LayoutBuilder(
                          builder: (
                            context,
                            constraints,
                          ) {
                            if (constraints
                                    .maxWidth <
                                500) {
                              return Column(
                                children: [
                                  buildDeadlineField(),

                                  const SizedBox(
                                    height:
                                        18,
                                  ),

                                  buildPriorityField(),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Expanded(
                                  child:
                                      buildDeadlineField(),
                                ),

                                const SizedBox(
                                  width:
                                      16,
                                ),

                                Expanded(
                                  child:
                                      buildPriorityField(),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        // =======================================
                        // SKILLS TITLE
                        // =======================================

                        const Text(
                          'SKILLS RICHIESTE',
                          style:
                              TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .w500,
                            color:
                                primaryBrown,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        const Text(
                          'Skills da selezionare:',
                          style:
                              TextStyle(
                            fontSize: 14,
                            color:
                                primaryBrown,
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // =======================================
                        // TEAM SKILLS
                        // =======================================

                        if (isLoadingSkills)
                          const Center(
                            child: Padding(
                              padding:
                                  EdgeInsets
                                      .all(
                                20,
                              ),
                              child:
                                  CircularProgressIndicator(),
                            ),
                          )
                        else if (teamSkills
                            .isEmpty)
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
                                0.06,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child:
                                const Text(
                              'Il team non ha ancora skill disponibili.',
                            ),
                          )
                        else
                          Wrap(
                            spacing: 9,
                            runSpacing: 9,
                            children:
                                teamSkills
                                    .map(
                              (skill) {
                                final dynamic rawId =
                                    skill['id'];

                                if (rawId
                                    is! int) {
                                  return const SizedBox
                                      .shrink();
                                }

                                final bool
                                    selected =
                                    selectedSkillIds
                                        .contains(
                                  rawId,
                                );

                                return FilterChip(
                                  label:
                                      Text(
                                    skill['name']
                                            ?.toString() ??
                                        'Skill',
                                  ),

                                  selected:
                                      selected,

                                  showCheckmark:
                                      true,

                                  checkmarkColor:
                                      Colors.white,

                                  selectedColor:
                                      chipColor,

                                  backgroundColor:
                                      const Color
                                          .fromRGBO(
                                    160,
                                    143,
                                    143,
                                    0.35,
                                  ),

                                  labelStyle:
                                      TextStyle(
                                    color: selected
                                        ? Colors
                                            .white
                                        : darkBrown,
                                  ),

                                  onSelected:
                                      (value) {
                                    setState(
                                      () {
                                        if (value) {
                                          selectedSkillIds
                                              .add(
                                            rawId,
                                          );
                                        } else {
                                          selectedSkillIds
                                              .remove(
                                            rawId,
                                          );
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            ).toList(),
                          ),

                        const SizedBox(
                          height: 30,
                        ),

                        // =======================================
                        // ADD NEW SKILL
                        // =======================================

                        const Text(
                          'Aggiungi nuova skill:',
                          style:
                              TextStyle(
                            fontSize: 14,
                            color:
                                primaryBrown,
                          ),
                        ),

                        const SizedBox(
                          height: 9,
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
                                  if (!isCreatingSkill) {
                                    createNewSkill();
                                  }
                                },

                                decoration:
                                    inputDecoration(
                                  hint:
                                      'Scrivi qui...',
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            SizedBox(
                              height: 50,
                              width: 55,
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
                                      chipColor,
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

                                child: isCreatingSkill
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

                        // =======================================
                        // ERROR
                        // =======================================

                        if (errorMessage !=
                            null) ...[
                          const SizedBox(
                            height: 20,
                          ),

                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets
                                    .all(
                              13,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.red
                                      .withValues(
                                alpha:
                                    0.08,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),
                            ),
                            child: Text(
                              errorMessage!,
                              style:
                                  const TextStyle(
                                color:
                                    Colors
                                        .redAccent,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 30,
                        ),

                        // =======================================
                        // CREATE BUTTON
                        // =======================================

                        SizedBox(
                          width:
                              double.infinity,
                          height: 50,
                          child:
                              ElevatedButton
                                  .icon(
                            onPressed:
                                isCreatingTask
                                    ? null
                                    : createTask,

                            icon: isCreatingTask
                                ? const SizedBox
                                    .shrink()
                                : const Icon(
                                    Icons.add_task,
                                  ),

                            label: isCreatingTask
                                ? const SizedBox(
                                    width:
                                        20,
                                    height:
                                        20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'CREA TASK',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          16,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  primaryBrown,

                              foregroundColor:
                                  Colors.white,

                              disabledBackgroundColor:
                                  primaryBrown
                                      .withValues(
                                alpha:
                                    0.65,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // =========================================================
      // HOME BUTTON
      // =========================================================

      floatingActionButton:
          FloatingActionButton(
        onPressed: openHome,
        backgroundColor:
            cardColor,
        foregroundColor:
            primaryBrown,
        tooltip:
            'Home manager',
        child: const Icon(
          Icons.home_outlined,
        ),
      ),
    );
  }

  // ============================================================
  // DEADLINE FIELD
  // ============================================================

  Widget buildDeadlineField() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const FormLabel(
          text: 'Scadenza',
        ),

        const SizedBox(
          height: 8,
        ),

        InkWell(
          onTap: chooseDeadline,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          child: Container(
            width:
                double.infinity,
            height: 52,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            decoration:
                BoxDecoration(
              color: inputColor,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 19,
                  color:
                      primaryBrown,
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    deadline == null
                        ? 'Seleziona'
                        : formatDate(
                            deadline!,
                          ),
                    style:
                        const TextStyle(
                      color:
                          darkBrown,
                    ),
                  ),
                ),

                const Icon(
                  Icons
                      .keyboard_arrow_down,
                  color:
                      primaryBrown,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRIORITY FIELD
  // ============================================================

  Widget buildPriorityField() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const FormLabel(
          text: 'Priorità',
        ),

        const SizedBox(
          height: 8,
        ),

        DropdownButtonFormField<String>(
          initialValue: priority,

          decoration:
              inputDecoration(
            hint: '',
          ),

          items:
              const [
            DropdownMenuItem(
              value: 'low',
              child:
                  Text('Bassa'),
            ),
            DropdownMenuItem(
              value: 'medium',
              child:
                  Text('Media'),
            ),
            DropdownMenuItem(
              value: 'high',
              child:
                  Text('Alta'),
            ),
          ],

          onChanged:
              (value) {
            if (value == null) {
              return;
            }

            setState(() {
              priority = value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,

      filled: true,

      fillColor: inputColor,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              primaryBrown,
          width: 1.5,
        ),
      ),
    );
  }
}


// =============================================================
// FORM LABEL
// =============================================================

class FormLabel extends StatelessWidget {
  final String text;

  const FormLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style:
          const TextStyle(
        fontSize: 14,
        fontWeight:
            FontWeight.w500,
        color:
            Color(
          0xFF573939,
        ),
      ),
    );
  }
}