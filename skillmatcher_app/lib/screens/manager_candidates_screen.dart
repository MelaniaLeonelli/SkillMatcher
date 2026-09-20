import 'package:flutter/material.dart';

import '../services/api_service.dart';

import 'create_task_screen.dart';
import 'manager_dashboard_screen.dart';
import 'manager_home_screen.dart';
import 'manager_navigation.dart';
import 'manager_tasks_screen.dart';
import 'profile_screen.dart';

class ManagerCandidatesScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> teams;
  final int? initialTaskId;

  const ManagerCandidatesScreen({
    super.key,
    required this.user,
    required this.teams,
    this.initialTaskId,
  });

  @override
  State<ManagerCandidatesScreen> createState() =>
      _ManagerCandidatesScreenState();
}

class _ManagerCandidatesScreenState
    extends State<ManagerCandidatesScreen> {
  static const Color backgroundColor =
      Color.fromRGBO(87, 57, 57, 0.82);

  static const Color cardColor =
      Color(0xFFE6E0E0);

  static const Color primaryBrown =
      Color(0xFF573939);

  static const Color darkBrown =
      Color(0xFF321414);

  bool isLoadingTasks = true;
  bool isLoadingEmployees = false;

  String? errorMessage;

  List<dynamic> openTasks = [];
  List<dynamic> employees = [];

  int? selectedTaskId;
  int? assigningEmployeeId;

  // ============================================================
  // TEAM
  // ============================================================

  int get teamId =>
      widget.teams.first['team_id'];

  // ============================================================
  // FILTER EMPLOYEES
  // ============================================================

  List<dynamic> get candidates {
    return employees.where(
      (employee) =>
          employee['response_status'] == 'applied',
    ).toList();
  }

  List<dynamic> get otherEmployees {
    return employees.where(
      (employee) =>
          employee['response_status'] != 'applied',
    ).toList();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    selectedTaskId =
        widget.initialTaskId;

    loadOpenTasks();
  }

  // ============================================================
  // LOAD OPEN TASKS
  // ============================================================

  Future<void> loadOpenTasks() async {
    try {
      final result =
          await ApiService.getTeamTasks(
        teamId,
      );

      final tasks = result
          .where(
            (task) =>
                task['status'] == 'open',
          )
          .toList();

      if (!mounted) return;

      setState(() {
        openTasks = tasks;
        isLoadingTasks = false;
        errorMessage = null;
      });

      if (selectedTaskId != null) {
        final exists = openTasks.any(
          (task) =>
              task['id'] ==
              selectedTaskId,
        );

        if (exists) {
          await loadEmployees(
            selectedTaskId!,
          );
        } else {
          setState(() {
            selectedTaskId = null;
            employees = [];
          });
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingTasks = false;

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
  // LOAD ALL EMPLOYEES FOR TASK
  // ============================================================

  Future<void> loadEmployees(
    int taskId,
  ) async {
    setState(() {
      selectedTaskId = taskId;
      isLoadingEmployees = true;
      employees = [];
      errorMessage = null;
    });

    try {
      final result =
          await ApiService.getTaskEmployees(
        taskId,
      );

      if (!mounted) return;

      setState(() {
        employees = result;
        isLoadingEmployees = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingEmployees = false;

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
  // SELECTED TASK
  // ============================================================

  dynamic get selectedTask {
    if (selectedTaskId == null) {
      return null;
    }

    for (final task in openTasks) {
      if (task['id'] ==
          selectedTaskId) {
        return task;
      }
    }

    return null;
  }

  // ============================================================
  // ASSIGN TASK
  // ============================================================

  Future<void> assignTask(
    int employeeId,
  ) async {
    if (selectedTaskId == null) {
      return;
    }

    final employee =
        employees.firstWhere(
      (item) =>
          item['employee_id'] ==
          employeeId,
      orElse: () => null,
    );

    final String employeeName =
        employee?['name']
                ?.toString() ??
            'questo dipendente';

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Assegna task',
          ),
          content: Text(
            'Vuoi assegnare questo task a $employeeName?',
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
                    primaryBrown,
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
                'Assegna',
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
      assigningEmployeeId =
          employeeId;
    });

    try {
      await ApiService.assignTask(
        taskId:
            selectedTaskId!,
        employeeId:
            employeeId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Task assegnato a $employeeName',
          ),
        ),
      );

      setState(() {
        selectedTaskId = null;
        employees = [];
        assigningEmployeeId = null;
        isLoadingTasks = true;
      });

      await loadOpenTasks();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        assigningEmployeeId =
            null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
            // NAVIGATION
            // ===================================================

            ManagerNavigationBar(
              selected:
                  ManagerSection.candidates,

              onCandidates: () {},

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
              child: isLoadingTasks
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Colors.white,
                      ),
                    )
                  : _buildBody(),
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
        tooltip:
            'Home manager',
        child: const Icon(
          Icons.home_outlined,
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh:
          loadOpenTasks,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(
          20,
        ),

        children: [
          Center(
            child: Container(
              width:
                  double.infinity,

              constraints:
                  const BoxConstraints(
                maxWidth: 760,
              ),

              padding:
                  const EdgeInsets.all(
                30,
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // =============================================
                  // HEADER
                  // =============================================

                  const Text(
                    'ASSEGNAZIONE TASK',
                    style:
                        TextStyle(
                      fontSize: 23,
                      fontWeight:
                          FontWeight.w500,
                      color:
                          primaryBrown,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'Seleziona un task per visualizzare i candidati e gli altri dipendenti del team. '
                    'Il manager può assegnare il task anche a un dipendente che non si è candidato.',
                    style:
                        TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color:
                          primaryBrown,
                    ),
                  ),

                  const SizedBox(
                    height: 26,
                  ),

                  // =============================================
                  // TASK SELECTOR
                  // =============================================

                  const Text(
                    'Task',
                    style:
                        TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w500,
                      color:
                          primaryBrown,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  if (openTasks.isEmpty)
                    Container(
                      width:
                          double.infinity,
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
                          20,
                        ),
                      ),
                      child:
                          const Text(
                        'Non ci sono task aperti.',
                        style:
                            TextStyle(
                          color:
                              primaryBrown,
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue:
                          selectedTaskId,

                      decoration:
                          InputDecoration(
                        hintText:
                            'Seleziona un task',

                        filled: true,

                        fillColor:
                            const Color(
                          0xFFD9D9D9,
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),

                      items:
                          openTasks.map(
                        (task) {
                          return DropdownMenuItem<int>(
                            value:
                                task['id'],
                            child:
                                Text(
                              task['title']
                                      ?.toString() ??
                                  'Task',
                            ),
                          );
                        },
                      ).toList(),

                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        loadEmployees(
                          value,
                        );
                      },
                    ),

                  // =============================================
                  // SELECTED TASK
                  // =============================================

                  if (selectedTask !=
                      null) ...[
                    const SizedBox(
                      height: 28,
                    ),

                    _buildSelectedTask(),

                    const SizedBox(
                      height: 30,
                    ),

                    if (isLoadingEmployees)
                      const Center(
                        child:
                            Padding(
                          padding:
                              EdgeInsets.all(
                            30,
                          ),
                          child:
                              CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      // =========================================
                      // CANDIDATES
                      // =========================================

                      _buildSectionTitle(
                        icon:
                            Icons.how_to_reg_outlined,
                        title:
                            'Dipendenti candidati',
                        subtitle:
                            '${candidates.length} candidat${candidates.length == 1 ? 'o' : 'i'}',
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      if (candidates.isEmpty)
                        _buildNoCandidates()
                      else
                        ...candidates.map(
                          (candidate) =>
                              EmployeeEvaluationCard(
                            employee:
                                candidate,
                            isAssigning:
                                assigningEmployeeId ==
                                    candidate[
                                        'employee_id'],
                            onAssign: () {
                              assignTask(
                                candidate[
                                    'employee_id'],
                              );
                            },
                          ),
                        ),

                      const SizedBox(
                        height: 30,
                      ),

                      const Divider(),

                      const SizedBox(
                        height: 22,
                      ),

                      // =========================================
                      // OTHER EMPLOYEES
                      // =========================================

                      _buildSectionTitle(
                        icon:
                            Icons.groups_outlined,
                        title:
                            'Altri dipendenti',
                        subtitle:
                            'Puoi assegnare il task anche senza candidatura',
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      if (otherEmployees.isEmpty)
                        _buildNoOtherEmployees()
                      else
                        ...otherEmployees.map(
                          (employee) =>
                              EmployeeEvaluationCard(
                            employee:
                                employee,
                            isAssigning:
                                assigningEmployeeId ==
                                    employee[
                                        'employee_id'],
                            onAssign: () {
                              assignTask(
                                employee[
                                    'employee_id'],
                              );
                            },
                          ),
                        ),
                    ],
                  ],

                  if (errorMessage !=
                      null) ...[
                    const SizedBox(
                      height: 20,
                    ),

                    Text(
                      errorMessage!,
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
        ],
      ),
    );
  }

  // ============================================================
  // SELECTED TASK CARD
  // ============================================================

  Widget _buildSelectedTask() {
    return Container(
      width:
          double.infinity,

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
          22,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            selectedTask['title']
                    ?.toString()
                    .toUpperCase() ??
                '',
            style:
                const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w500,
              color:
                  primaryBrown,
            ),
          ),

          if (selectedTask[
                  'description'] !=
              null) ...[
            const SizedBox(
              height: 6,
            ),

            Text(
              selectedTask[
                      'description']
                  .toString(),
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    primaryBrown,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration:
              const BoxDecoration(
            color:
                Color.fromRGBO(
              87,
              57,
              57,
              0.10,
            ),
            shape:
                BoxShape.circle,
          ),
          child: Icon(
            icon,
            color:
                primaryBrown,
            size: 23,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w500,
                  color:
                      primaryBrown,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                subtitle,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      primaryBrown,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NO CANDIDATES
  // ============================================================

  Widget _buildNoCandidates() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color.fromRGBO(
          87,
          57,
          57,
          0.06,
        ),

        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 40,
            color:
                primaryBrown,
          ),

          SizedBox(
            height: 10,
          ),

          Text(
            'Nessun candidato',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w500,
              color:
                  primaryBrown,
            ),
          ),

          SizedBox(
            height: 4,
          ),

          Text(
            'Nessun dipendente si è candidato. Puoi comunque assegnare il task scegliendo un dipendente dalla sezione sottostante.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 13,
              color:
                  primaryBrown,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO OTHER EMPLOYEES
  // ============================================================

  Widget _buildNoOtherEmployees() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color.fromRGBO(
          87,
          57,
          57,
          0.06,
        ),

        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),

      child:
          const Text(
        'Non ci sono altri dipendenti disponibili nel team.',
        textAlign:
            TextAlign.center,
        style:
            TextStyle(
          color:
              primaryBrown,
        ),
      ),
    );
  }
}

// =============================================================
// EMPLOYEE EVALUATION CARD
// =============================================================

class EmployeeEvaluationCard
    extends StatelessWidget {
  final dynamic employee;

  final bool isAssigning;

  final VoidCallback onAssign;

  const EmployeeEvaluationCard({
    super.key,
    required this.employee,
    required this.isAssigning,
    required this.onAssign,
  });

  static const Color primaryBrown =
      Color(0xFF573939);

  static const Color darkBrown =
      Color(0xFF321414);

  @override
  Widget build(
    BuildContext context,
  ) {
    final double compatibility =
        (employee[
                    'compatibility']
                as num?)
            ?.toDouble() ??
        0;

    final int activeTasks =
        (employee[
                    'active_tasks']
                as num?)
            ?.toInt() ??
        0;

    final String employeeStatus =
        employee['response_status']
                ?.toString() ??
            'none';

    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),

      padding:
          const EdgeInsets.all(
        20,
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

      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              // ===============================================
              // AVATAR
              // ===============================================

              const CircleAvatar(
                radius: 30,

                backgroundColor:
                    Color(
                  0xFFD9D9D9,
                ),

                child: Icon(
                  Icons.person,
                  size: 34,
                  color:
                      primaryBrown,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              // ===============================================
              // NAME + STATUS
              // ===============================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee['name']
                              ?.toString() ??
                          'Dipendente',
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w500,
                        color:
                            primaryBrown,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    EmployeeStatusBadge(
                      status:
                          employeeStatus,
                    ),
                  ],
                ),
              ),

              // ===============================================
              // COMPATIBILITY
              // ===============================================

              CandidateCompatibility(
                value:
                    compatibility,
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          const Divider(),

          const SizedBox(
            height: 14,
          ),

          // ===============================================
          // EVALUATION
          // ===============================================

          Row(
            children: [
              Expanded(
                child:
                    CandidateInfoBox(
                  icon:
                      Icons.percent,
                  label:
                      'Compatibilità',
                  value:
                      '${compatibility.toStringAsFixed(0)}%',
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    CandidateInfoBox(
                  icon:
                      Icons.work_outline,
                  label:
                      'Carico di lavoro',
                  value:
                      activeTasks == 1
                          ? '1 task attivo'
                          : '$activeTasks task attivi',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // ===============================================
          // ASSIGN
          // ===============================================

          SizedBox(
            width:
                double.infinity,
            height: 44,

            child:
                ElevatedButton.icon(
              onPressed:
                  isAssigning
                      ? null
                      : onAssign,

              icon:
                  isAssigning
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
                          Icons
                              .assignment_ind_outlined,
                        ),

              label:
                  Text(
                isAssigning
                    ? 'ASSEGNAZIONE...'
                    : 'ASSEGNA TASK',
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
        ],
      ),
    );
  }
}

// =============================================================
// STATUS BADGE
// =============================================================

class EmployeeStatusBadge
    extends StatelessWidget {
  final String status;

  const EmployeeStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    late String text;
    late IconData icon;
    late Color color;

    switch (status) {
      case 'applied':
        text = 'Candidato';
        icon =
            Icons.check_circle_outline;
        color =
            const Color(
          0xFF507A59,
        );
        break;

      case 'rejected':
        text = 'Rifiutato';
        icon =
            Icons.close;
        color =
            const Color(
          0xFF9E5148,
        );
        break;

      default:
        text =
            'Nessuna risposta';
        icon =
            Icons.remove_circle_outline;
        color =
            const Color(
          0xFF7A6B6B,
        );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.12,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            text,
            style:
                TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// COMPATIBILITY INDICATOR
// =============================================================

class CandidateCompatibility
    extends StatelessWidget {
  final double value;

  const CandidateCompatibility({
    super.key,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final safeValue =
        value
            .clamp(
              0,
              100,
            )
            .toDouble();

    return SizedBox(
      width: 64,
      height: 64,

      child: Stack(
        alignment:
            Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,

            child:
                CircularProgressIndicator(
              value:
                  safeValue /
                      100,

              strokeWidth:
                  6,

              backgroundColor:
                  const Color(
                0xFFC7C7C7,
              ),

              color:
                  const Color(
                0xFF6E9C77,
              ),
            ),
          ),

          Text(
            '${safeValue.toStringAsFixed(0)}%',

            style:
                const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w500,
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
// INFO BOX
// =============================================================

class CandidateInfoBox
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const CandidateInfoBox({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        14,
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
          18,
        ),
      ),

      child: Column(
        children: [
          Icon(
            icon,
            size: 21,
            color:
                const Color(
              0xFF573939,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            label,
            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Color(
                0xFF573939,
              ),
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            value,
            textAlign:
                TextAlign.center,

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
          ),
        ],
      ),
    );
  }
}