import 'package:flutter/material.dart';

import '../services/api_service.dart';

import 'create_task_screen.dart';
import 'manager_candidates_screen.dart';
import 'manager_dashboard_screen.dart';
import 'manager_home_screen.dart';
import 'manager_navigation.dart';
import 'profile_screen.dart';

class ManagerTasksScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> teams;

  const ManagerTasksScreen({
    super.key,
    required this.user,
    required this.teams,
  });

  @override
  State<ManagerTasksScreen> createState() =>
      _ManagerTasksScreenState();
}

class _ManagerTasksScreenState
    extends State<ManagerTasksScreen> {
  static const Color background =
      Color.fromRGBO(
    87,
    57,
    57,
    0.82,
  );

  static const Color card =
      Color(0xFFE6E0E0);

  static const Color brown =
      Color(0xFF573939);

  static const Color darkBrown =
      Color(0xFF321414);

  List<dynamic> tasks = [];

  bool isLoading = true;

  String? errorMessage;

  String filter = 'all';

  int? processingTaskId;

  int get teamId =>
      widget.teams.first['team_id'];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadTasks();
  }

  // ============================================================
  // LOAD TASKS
  // ============================================================

  Future<void> loadTasks() async {
    try {
      final result =
          await ApiService.getTeamTasksWithSkills(
        teamId,
      );

      if (!mounted) return;

      setState(() {
        tasks = result;
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
  // FILTERED TASKS
  // ============================================================

  List<dynamic> get filteredTasks {
    if (filter == 'all') {
      return tasks;
    }

    return tasks
        .where(
          (task) =>
              task['status'] == filter,
        )
        .toList();
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String date(
    dynamic value,
  ) {
    if (value == null) {
      return 'Nessuna';
    }

    final String raw =
        value.toString();

    final parts =
        raw.split('-');

    if (parts.length != 3) {
      return raw;
    }

    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  DateTime? parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime.parse(
        value.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // EDIT TASK
  // ============================================================

  Future<void> editTask(
    dynamic task,
  ) async {
    List<dynamic> catalogSkills;
    List<dynamic> currentTaskSkills;

    try {
      catalogSkills =
          await ApiService.getTeamSkills(
        teamId,
      );

      currentTaskSkills =
          await ApiService.getTaskSkills(
        task['id'],
      );
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

      return;
    }

    if (!mounted) return;

    final titleController =
        TextEditingController(
      text:
          task['title']?.toString() ??
              '',
    );

    final descriptionController =
        TextEditingController(
      text:
          task['description']
                  ?.toString() ??
              '',
    );

    String selectedPriority =
        task['priority']?.toString().toLowerCase() ??
            'medium';

    const allowedPriorities = [
      'low',
      'medium',
      'high',
    ];

    if (!allowedPriorities.contains(selectedPriority)) {
      selectedPriority = 'medium';
    }

    DateTime? selectedDeadline =
        parseDate(
      task['deadline'],
    );

    final Set<int> selectedSkillIds =
        currentTaskSkills
            .map<int>(
              (item) =>
                  (item['skill_id'] as num)
                      .toInt(),
            )
            .toSet();

    String? dialogError;
    bool saving = false;

    final bool? saved =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title:
                  const Text(
                'Modifica task',
              ),
              content:
                  SizedBox(
                width: 520,
                child:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      TextField(
                        controller:
                            titleController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Titolo',
                          prefixIcon:
                              Icon(
                            Icons.title,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextField(
                        controller:
                            descriptionController,
                        maxLines: 4,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Descrizione',
                          prefixIcon:
                              Icon(
                            Icons
                                .description_outlined,
                          ),
                          alignLabelWithHint:
                              true,
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      DropdownButtonFormField<String>(
                        value:
                            selectedPriority,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Priorità',
                          prefixIcon:
                              Icon(
                            Icons
                                .flag_outlined,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        items:
                            const [
                          DropdownMenuItem(
                            value:
                                'low',
                            child:
                                Text(
                              'Bassa',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'medium',
                            child:
                                Text(
                              'Media',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'high',
                            child:
                                Text(
                              'Alta',
                            ),
                          ),
                        ],
                        onChanged:
                            saving
                                ? null
                                : (value) {
                                    if (value ==
                                        null) {
                                      return;
                                    }

                                    setDialogState(
                                      () {
                                        selectedPriority =
                                            value;
                                      },
                                    );
                                  },
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      const Text(
                        'Scadenza',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w500,
                          color:
                              brown,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          border:
                              Border.all(
                            color:
                                Colors.black26,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child:
                            Row(
                          children: [
                            const Icon(
                              Icons
                                  .calendar_today_outlined,
                              size: 20,
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child:
                                  Text(
                                selectedDeadline ==
                                        null
                                    ? 'Nessuna scadenza'
                                    : '${selectedDeadline!.day.toString().padLeft(2, '0')}/'
                                        '${selectedDeadline!.month.toString().padLeft(2, '0')}/'
                                        '${selectedDeadline!.year}',
                              ),
                            ),

                            IconButton(
                              tooltip:
                                  'Seleziona data',
                              onPressed:
                                  saving
                                      ? null
                                      : () async {
                                          final now =
                                              DateTime
                                                  .now();

                                          final picked =
                                              await showDatePicker(
                                            context:
                                                context,
                                            initialDate:
                                                selectedDeadline ??
                                                    now,
                                            firstDate:
                                                DateTime(
                                              now.year -
                                                  1,
                                            ),
                                            lastDate:
                                                DateTime(
                                              now.year +
                                                  10,
                                            ),
                                          );

                                          if (picked ==
                                              null) {
                                            return;
                                          }

                                          setDialogState(
                                            () {
                                              selectedDeadline =
                                                  picked;
                                            },
                                          );
                                        },
                              icon:
                                  const Icon(
                                Icons
                                    .edit_calendar_outlined,
                              ),
                            ),

                            if (selectedDeadline !=
                                null)
                              IconButton(
                                tooltip:
                                    'Rimuovi scadenza',
                                onPressed:
                                    saving
                                        ? null
                                        : () {
                                            setDialogState(
                                              () {
                                                selectedDeadline =
                                                    null;
                                              },
                                            );
                                          },
                                icon:
                                    const Icon(
                                  Icons.close,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      const Divider(),

                      const SizedBox(
                        height: 12,
                      ),

                      const Text(
                        'Skill richieste',
                        style:
                            TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w500,
                          color:
                              brown,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'Seleziona le competenze richieste per questo task.',
                        style:
                            TextStyle(
                          fontSize: 12,
                          color:
                              darkBrown,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      if (catalogSkills
                          .isEmpty)
                        const Text(
                          'Il catalogo delle skill è vuoto.',
                        )
                      else
                        Container(
                          constraints:
                              const BoxConstraints(
                            maxHeight: 260,
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
                              16,
                            ),
                          ),
                          child:
                              ListView.builder(
                            shrinkWrap:
                                true,
                            itemCount:
                                catalogSkills
                                    .length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final skill =
                                  catalogSkills[
                                      index];

                              final int
                                  skillId =
                                  (skill['id']
                                          as num)
                                      .toInt();

                              final bool
                                  checked =
                                  selectedSkillIds
                                      .contains(
                                skillId,
                              );

                              return CheckboxListTile(
                                value:
                                    checked,
                                activeColor:
                                    brown,
                                title:
                                    Text(
                                  skill['name']
                                          ?.toString() ??
                                      'Skill',
                                ),
                                onChanged:
                                    saving
                                        ? null
                                        : (value) {
                                            setDialogState(
                                              () {
                                                if (value ==
                                                    true) {
                                                  selectedSkillIds
                                                      .add(
                                                    skillId,
                                                  );
                                                } else {
                                                  selectedSkillIds
                                                      .remove(
                                                    skillId,
                                                  );
                                                }
                                              },
                                            );
                                          },
                              );
                            },
                          ),
                        ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        '${selectedSkillIds.length} skill selezionate',
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              brown,
                        ),
                      ),

                      if (dialogError !=
                          null) ...[
                        const SizedBox(
                          height: 15,
                        ),

                        Text(
                          dialogError!,
                          style:
                              const TextStyle(
                            color:
                                Colors.redAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving
                          ? null
                          : () {
                              Navigator.pop(
                                dialogContext,
                                false,
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
                        brown,
                    foregroundColor:
                        Colors.white,
                  ),
                  onPressed:
                      saving
                          ? null
                          : () async {
                              final title =
                                  titleController
                                      .text
                                      .trim();

                              final description =
                                  descriptionController
                                      .text
                                      .trim();

                              final priority =
                                  selectedPriority;

                              if (title
                                  .isEmpty) {
                                setDialogState(
                                  () {
                                    dialogError =
                                        'Inserisci il titolo del task';
                                  },
                                );
                                return;
                              }

                              if (selectedSkillIds
                                  .isEmpty) {
                                setDialogState(
                                  () {
                                    dialogError =
                                        'Seleziona almeno una skill richiesta';
                                  },
                                );
                                return;
                              }

                              setDialogState(
                                () {
                                  saving =
                                      true;
                                  dialogError =
                                      null;
                                },
                              );

                              try {
                                final String?
                                    deadline =
                                    selectedDeadline ==
                                            null
                                        ? null
                                        : '${selectedDeadline!.year.toString().padLeft(4, '0')}-'
                                            '${selectedDeadline!.month.toString().padLeft(2, '0')}-'
                                            '${selectedDeadline!.day.toString().padLeft(2, '0')}';

                                await ApiService
                                    .updateTask(
                                  taskId:
                                      task['id'],
                                  title:
                                      title,
                                  description:
                                      description,
                                  priority:
                                      priority,
                                  deadline:
                                      deadline,
                                  teamId:
                                      teamId,
                                );

                                await ApiService
                                    .updateTaskSkills(
                                  taskId:
                                      task['id'],
                                  skillIds:
                                      selectedSkillIds
                                          .toList(),
                                );

                                if (!mounted) {
                                  return;
                                }

                                Navigator.pop(
                                  dialogContext,
                                  true,
                                );
                              } catch (e) {
                                setDialogState(
                                  () {
                                    saving =
                                        false;
                                    dialogError =
                                        e
                                            .toString()
                                            .replaceFirst(
                                              'Exception: ',
                                              '',
                                            );
                                  },
                                );
                              }
                            },
                  child:
                      saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'Salva modifiche',
                            ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (saved != true) {
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Task e skill modificati con successo',
        ),
      ),
    );

    setState(() {
      isLoading = true;
    });

    await loadTasks();
  }


// ============================================================
  // CLOSE TASK
  // ============================================================

  Future<void> closeTask(
    dynamic task,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,

      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title:
              const Text(
            'Chiudi task',
          ),

          content:
              Text(
            'Vuoi chiudere "${task['title']}"?\n\n'
            'Il task non verrà più mostrato tra le attività disponibili '
            'e non potrà ricevere nuove candidature.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
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

              child:
                  const Text(
                'Chiudi task',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      processingTaskId =
          task['id'];
    });

    try {
      await ApiService.closeTask(
        task['id'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Task chiuso con successo',
          ),
        ),
      );

      await loadTasks();
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
    } finally {
      if (mounted) {
        setState(() {
          processingTaskId =
              null;
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

      (
        route,
      ) =>
          false,
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
          background,

      body:
          SafeArea(
        child: Column(
          children: [
            // ===================================================
            // NAVIGATION
            // ===================================================

            ManagerNavigationBar(
              selected:
                  ManagerSection.tasks,

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

              onCreate: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateTaskScreen(
                      user:
                          widget.user,
                      teams:
                          widget.teams,
                    ),
                  ),
                );
              },

              onTasks: () {},

              onProfile: () {
                Navigator.pushReplacement(
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
            // BODY
            // ===================================================

            Expanded(
              child:
                  isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                          ),
                        )
                      : errorMessage !=
                              null
                          ? _buildError()
                          : _body(),
            ),
          ],
        ),
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed:
            openHome,

        backgroundColor:
            card,

        foregroundColor:
            brown,

        child:
            const Icon(
          Icons.home_outlined,
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
              size: 55,
              color: Colors.white,
            ),

            const SizedBox(
              height: 15,
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
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            ElevatedButton(
              onPressed:
                  () {
                setState(() {
                  isLoading =
                      true;
                  errorMessage =
                      null;
                });

                loadTasks();
              },

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
  // BODY
  // ============================================================

  Widget _body() {
    return RefreshIndicator(
      onRefresh:
          loadTasks,

      child:
          ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(
          20,
        ),

        children: [
          Center(
            child:
                Container(
              width:
                  double.infinity,

              constraints:
                  const BoxConstraints(
                maxWidth: 750,
              ),

              padding:
                  const EdgeInsets.all(
                28,
              ),

              decoration:
                  BoxDecoration(
                color:
                    card,

                borderRadius:
                    BorderRadius.circular(
                  45,
                ),
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // =============================================
                  // HEADER
                  // =============================================

                  const Row(
                    children: [
                      Icon(
                        Icons
                            .assignment_outlined,
                        color:
                            brown,
                        size: 29,
                      ),

                      SizedBox(
                        width: 10,
                      ),

                      Text(
                        'TASK',
                        style:
                            TextStyle(
                          fontSize:
                              23,
                          fontWeight:
                              FontWeight.w500,
                          color:
                              brown,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  const Text(
                    'Consulta e gestisci le attività del team.',
                    style:
                        TextStyle(
                      color:
                          brown,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // =============================================
                  // FILTERS
                  // =============================================

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filter(
                        'all',
                        'Tutti',
                      ),

                      _filter(
                        'open',
                        'Aperti',
                      ),

                      _filter(
                        'assigned',
                        'Assegnati',
                      ),

                      _filter(
                        'completed',
                        'Completati',
                      ),

                      _filter(
                        'closed',
                        'Chiusi',
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // =============================================
                  // TASKS
                  // =============================================

                  if (filteredTasks
                      .isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 40,
                      ),

                      child:
                          Center(
                        child:
                            Column(
                          children: [
                            Icon(
                              Icons
                                  .assignment_late_outlined,
                              size:
                                  45,
                              color:
                                  brown,
                            ),

                            SizedBox(
                              height:
                                  12,
                            ),

                            Text(
                              'Nessun task',
                              style:
                                  TextStyle(
                                color:
                                    brown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredTasks.map(
                      (
                        task,
                      ) {
                        final bool isOpen =
                            task['status'] ==
                                'open';

                        return ManagerTaskCard(
                          task:
                              task,

                          date:
                              date(
                            task[
                                'deadline'],
                          ),

                          isProcessing:
                              processingTaskId ==
                                  task['id'],

                          onCandidates:
                              isOpen
                                  ? () {
                                      Navigator.push(
                                        context,

                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ManagerCandidatesScreen(
                                            user:
                                                widget.user,
                                            teams:
                                                widget.teams,
                                            initialTaskId:
                                                task['id'],
                                          ),
                                        ),
                                      );
                                    }
                                  : null,

                          onEdit:
                              isOpen
                                  ? () {
                                      editTask(
                                        task,
                                      );
                                    }
                                  : null,

                          onClose:
                              isOpen
                                  ? () {
                                      closeTask(
                                        task,
                                      );
                                    }
                                  : null,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  Widget _filter(
    String value,
    String label,
  ) {
    return ChoiceChip(
      label:
          Text(
        label,
      ),

      selected:
          filter == value,

      onSelected:
          (_) {
        setState(() {
          filter = value;
        });
      },
    );
  }
}

// =============================================================
// MANAGER TASK CARD
// =============================================================

class ManagerTaskCard
    extends StatelessWidget {
  final dynamic task;

  final String date;

  final VoidCallback?
      onCandidates;

  final VoidCallback?
      onEdit;

  final VoidCallback?
      onClose;

  final bool isProcessing;

  const ManagerTaskCard({
    super.key,
    required this.task,
    required this.date,
    required this.isProcessing,
    this.onCandidates,
    this.onEdit,
    this.onClose,
  });

  static const Color brown =
      Color(0xFF573939);

  static const Color darkBrown =
      Color(0xFF321414);

  @override
  Widget build(
    BuildContext context,
  ) {
    final String status =
        task['status']
                ?.toString() ??
            '';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      padding:
          const EdgeInsets.all(
        18,
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
          25,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // =====================================================
          // TITLE
          // =====================================================

          Row(
            children: [
              Expanded(
                child:
                    Text(
                  task['title']
                          ?.toString() ??
                      'Task',

                  style:
                      const TextStyle(
                    fontSize:
                        17,

                    fontWeight:
                        FontWeight
                            .w500,

                    color:
                        brown,
                  ),
                ),
              ),

              TaskStatusBadge(
                status:
                    status,
              ),
            ],
          ),

          const SizedBox(
            height: 9,
          ),

          // =====================================================
          // DESCRIPTION
          // =====================================================

          Text(
            task['description']
                    ?.toString() ??
                '',

            style:
                const TextStyle(
              color:
                  darkBrown,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // =====================================================
          // INFORMATION
          // =====================================================

          Wrap(
            spacing: 15,
            runSpacing: 8,
            children: [
              TaskInfo(
                icon:
                    Icons
                        .flag_outlined,
                text:
                    'Priorità: ${task['priority'] ?? '-'}',
              ),

              TaskInfo(
                icon:
                    Icons
                        .calendar_today_outlined,
                text:
                    'Scadenza: $date',
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // =====================================================
          // REQUIRED SKILLS
          // =====================================================

          Builder(
            builder: (
              context,
            ) {
              final List<dynamic>
                  requiredSkills =
                  task['required_skills']
                          is List
                      ? task['required_skills']
                          as List<dynamic>
                      : [];

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons
                            .school_outlined,
                        size: 17,
                        color:
                            brown,
                      ),

                      SizedBox(
                        width: 6,
                      ),

                      Text(
                        'Skill richieste',
                        style:
                            TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight
                                  .w500,
                          color:
                              brown,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  if (requiredSkills
                      .isEmpty)
                    const Text(
                      'Nessuna skill richiesta',
                      style:
                          TextStyle(
                        fontSize: 12,
                        color:
                            darkBrown,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children:
                          requiredSkills
                              .map<Widget>(
                        (
                          skill,
                        ) {
                          return Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  10,
                              vertical:
                                  6,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color
                                      .fromRGBO(
                                87,
                                57,
                                57,
                                0.10,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),
                            ),
                            child:
                                Text(
                              skill['name']
                                      ?.toString() ??
                                  'Skill',
                              style:
                                  const TextStyle(
                                fontSize:
                                    11,
                                color:
                                    brown,
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                ],
              );
            },
          ),

          // =====================================================
          // OPEN TASK ACTIONS
          // =====================================================

          if (onCandidates !=
                  null ||
              onEdit != null ||
              onClose !=
                  null) ...[
            const SizedBox(
              height: 16,
            ),

            const Divider(),

            const SizedBox(
              height: 8,
            ),

            if (isProcessing)
              const Center(
                child:
                    Padding(
                  padding:
                      EdgeInsets.all(
                    8,
                  ),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else
              Wrap(
                alignment:
                    WrapAlignment.end,

                spacing: 8,
                runSpacing: 8,

                children: [
                  // =============================================
                  // CANDIDATES
                  // =============================================

                  if (onCandidates !=
                      null)
                    TextButton.icon(
                      onPressed:
                          onCandidates,

                      icon:
                          const Icon(
                        Icons
                            .people_outline,
                      ),

                      label:
                          const Text(
                        'Candidati',
                      ),
                    ),

                  // =============================================
                  // EDIT
                  // =============================================

                  if (onEdit !=
                      null)
                    OutlinedButton.icon(
                      onPressed:
                          onEdit,

                      icon:
                          const Icon(
                        Icons
                            .edit_outlined,
                      ),

                      label:
                          const Text(
                        'Modifica',
                      ),

                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            brown,
                      ),
                    ),

                  // =============================================
                  // CLOSE
                  // =============================================

                  if (onClose !=
                      null)
                    ElevatedButton.icon(
                      onPressed:
                          onClose,

                      icon:
                          const Icon(
                        Icons
                            .block_outlined,
                      ),

                      label:
                          const Text(
                        'Chiudi',
                      ),

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors
                                .redAccent,

                        foregroundColor:
                            Colors
                                .white,
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

// =============================================================
// STATUS BADGE
// =============================================================

class TaskStatusBadge
    extends StatelessWidget {
  final String status;

  const TaskStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    late String label;

    late IconData icon;

    switch (status) {
      case 'open':
        label = 'Aperto';
        icon =
            Icons.lock_open_outlined;
        break;

      case 'assigned':
        label = 'Assegnato';
        icon =
            Icons.person_outline;
        break;

      case 'completed':
        label = 'Completato';
        icon =
            Icons.check_circle_outline;
        break;

      case 'closed':
        label = 'Chiuso';
        icon =
            Icons.block_outlined;
        break;

      default:
        label =
            status.isEmpty
                ? '-'
                : status;

        icon =
            Icons.info_outline;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color.fromRGBO(
          87,
          57,
          57,
          0.10,
        ),

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 14,
            color:
                const Color(
              0xFF573939,
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            label,

            style:
                const TextStyle(
              fontSize: 11,
              color:
                  Color(
                0xFF573939,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TASK INFO
// =============================================================

class TaskInfo
    extends StatelessWidget {
  final IconData icon;

  final String text;

  const TaskInfo({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,

      children: [
        Icon(
          icon,
          size: 16,
          color:
              const Color(
            0xFF573939,
          ),
        ),

        const SizedBox(
          width: 5,
        ),

        Text(
          text,

          style:
              const TextStyle(
            fontSize: 12,
            color:
                Color(
              0xFF573939,
            ),
          ),
        ),
      ],
    );
  }
}