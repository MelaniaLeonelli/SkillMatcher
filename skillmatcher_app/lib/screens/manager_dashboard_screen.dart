import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'create_task_screen.dart';
import 'manager_candidates_screen.dart';
import 'manager_home_screen.dart';
import 'manager_navigation.dart';
import 'profile_screen.dart';
import 'manager_tasks_screen.dart';

class ManagerDashboardScreen
    extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> teams;

  const ManagerDashboardScreen({
    super.key,
    required this.user,
    required this.teams,
  });

  @override
  State<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends State<ManagerDashboardScreen> {
  static const Color backgroundColor =
      Color.fromRGBO(
    87,
    57,
    57,
    0.82,
  );

  static const Color cardColor =
      Color(0xFFE6E0E0);

  static const Color primaryBrown =
      Color(0xFF573939);

  bool isLoading = true;

  String? errorMessage;

  List<dynamic> tasks = [];

  int get teamId =>
      widget.teams.first['team_id'];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final result =
          await ApiService
              .getTeamTasks(
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

  int countStatus(
    String status,
  ) {
    return tasks
        .where(
          (task) =>
              task['status'] ==
              status,
        )
        .length;
  }

  double percentage(
    int count,
  ) {
    if (tasks.isEmpty) {
      return 0;
    }

    return count / tasks.length;
  }

  String formatDeadline(
    dynamic deadline,
  ) {
    if (deadline == null) {
      return 'Nessuna scadenza';
    }

    final value =
        deadline.toString();

    final parts =
        value.split('-');

    if (parts.length != 3) {
      return value;
    }

    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  List<dynamic>
      get upcomingTasks {
    final result = tasks.where(
      (task) {
        final status =
            task['status'];

        return status !=
                'completed' &&
            status !=
                'closed' &&
            task['deadline'] !=
                null;
      },
    ).toList();

    result.sort(
      (a, b) => a['deadline']
          .toString()
          .compareTo(
            b['deadline']
                .toString(),
          ),
    );

    return result
        .take(4)
        .toList();
  }

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

  @override
  Widget build(BuildContext context) {
    final open =
        countStatus('open');

    final assigned =
        countStatus('assigned');

    final completed =
        countStatus('completed');

    final closed =
        countStatus('closed');

    return Scaffold(
      backgroundColor:
          backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ManagerNavigationBar(
              selected:
                  ManagerSection
                      .dashboard,
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
              onDashboard: () {},
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
                          null
                      ? _error()
                      : _content(
                          open,
                          assigned,
                          completed,
                          closed,
                        ),
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

  Widget _content(
    int open,
    int assigned,
    int completed,
    int closed,
  ) {
    return RefreshIndicator(
      onRefresh: loadTasks,
      child: ListView(
        padding:
            const EdgeInsets.all(
          22,
        ),
        children: [
          Center(
            child: Container(
              width:
                  double.infinity,
              constraints:
                  const BoxConstraints(
                maxWidth: 700,
              ),
              padding:
                  const EdgeInsets
                      .all(
                30,
              ),
              decoration:
                  BoxDecoration(
                color:
                    cardColor,
                borderRadius:
                    BorderRadius
                        .circular(
                  45,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'DASHBOARD',
                    style:
                        TextStyle(
                      fontSize:
                          23,
                      fontWeight:
                          FontWeight
                              .w500,
                      color:
                          primaryBrown,
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SummaryBox(
                        label:
                            'Totali',
                        value:
                            tasks.length,
                        icon: Icons
                            .assignment_outlined,
                      ),
                      SummaryBox(
                        label:
                            'Aperti',
                        value: open,
                        icon: Icons
                            .hourglass_empty,
                      ),
                      SummaryBox(
                        label:
                            'Assegnati',
                        value:
                            assigned,
                        icon: Icons
                            .person_pin_outlined,
                      ),
                      SummaryBox(
                        label:
                            'Completati',
                        value:
                            completed,
                        icon: Icons
                            .task_alt,
                      ),
                      SummaryBox(
                        label:
                            'Chiusi',
                        value:
                            closed,
                        icon: Icons
                            .block_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  const Text(
                    'Stato delle attività',
                    style:
                        TextStyle(
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight
                              .w500,
                      color:
                          primaryBrown,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  StatusBar(
                    label:
                        'Aperti',
                    value:
                        percentage(
                      open,
                    ),
                    count: open,
                  ),

                  StatusBar(
                    label:
                        'Assegnati',
                    value:
                        percentage(
                      assigned,
                    ),
                    count:
                        assigned,
                  ),

                  StatusBar(
                    label:
                        'Completati',
                    value:
                        percentage(
                      completed,
                    ),
                    count:
                        completed,
                  ),
                  StatusBar(
                    label:
                        'Chiusi',
                    value:
                        percentage(
                      closed,
                    ),
                    count:
                        closed,
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  const Divider(),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Prossime scadenze',
                    style:
                        TextStyle(
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight
                              .w500,
                      color:
                          primaryBrown,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  if (upcomingTasks
                      .isEmpty)
                    const Text(
                      'Nessuna scadenza in programma.',
                    )
                  else
                    ...upcomingTasks
                        .map(
                      (task) =>
                          DeadlineRow(
                        title: task[
                                    'title']
                                ?.toString() ??
                            'Task',
                        date:
                            formatDeadline(
                          task[
                              'deadline'],
                        ),
                        status: task[
                                    'status']
                                ?.toString() ??
                            '',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            errorMessage!,
            style:
                const TextStyle(
              color:
                  Colors.white,
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading =
                    true;
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
    );
  }
}

class SummaryBox
    extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const SummaryBox({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 125,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color.fromRGBO(
          87,
          57,
          57,
          0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
                const Color(
              0xFF573939,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            '$value',
            style:
                const TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(
                0xFF573939,
              ),
            ),
          ),
          Text(
            label,
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
      ),
    );
  }
}

class StatusBar
    extends StatelessWidget {
  final String label;
  final double value;
  final int count;

  const StatusBar({
    super.key,
    required this.label,
    required this.value,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF573939,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                LinearProgressIndicator(
              value: value,
              minHeight: 10,
              borderRadius:
                  BorderRadius
                      .circular(
                10,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Text(
            '$count',
          ),
        ],
      ),
    );
  }
}

class DeadlineRow
    extends StatelessWidget {
  final String title;
  final String date;
  final String status;

  const DeadlineRow({
    super.key,
    required this.title,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .calendar_today_outlined,
            size: 18,
            color:
                Color(
              0xFF573939,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              title,
            ),
          ),
          Text(
            date,
            style:
                const TextStyle(
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