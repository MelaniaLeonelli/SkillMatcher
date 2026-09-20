import 'package:flutter/material.dart';

import 'create_task_screen.dart';
import 'manager_candidates_screen.dart';
import 'manager_dashboard_screen.dart';
import 'profile_screen.dart';
import 'manager_tasks_screen.dart';

export 'manager_navigation.dart';
class ManagerHomeScreen
    extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> teams;

  const ManagerHomeScreen({
    super.key,
    required this.user,
    required this.teams,
  });

  @override
  State<ManagerHomeScreen> createState() =>
      _ManagerHomeScreenState();
}

class _ManagerHomeScreenState
    extends State<ManagerHomeScreen> {
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

  static const Color darkBrown =
      Color(0xFF321414);

  void openCandidates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManagerCandidatesScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  void openDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManagerDashboardScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  void openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateTaskScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  void openTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManagerTasksScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team =
        widget.teams.first;

    return Scaffold(
      backgroundColor:
          backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Nella Home non evidenziamo
            // nessuna sezione.
            _HomeManagerBar(
              onCandidates:
                  openCandidates,
              onDashboard:
                  openDashboard,
              onCreate: openCreate,
              onTasks: openTasks,
              onProfile:
                  openProfile,
            ),

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: Center(
                  child: Container(
                    width:
                        double.infinity,
                    constraints:
                        const BoxConstraints(
                      maxWidth: 620,
                    ),
                    padding:
                        const EdgeInsets
                            .all(
                      32,
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
                        Text(
                          'Ciao ${widget.user['name'] ?? ''}',
                          style:
                              const TextStyle(
                            fontSize:
                                27,
                            fontWeight:
                                FontWeight
                                    .w500,
                            color:
                                darkBrown,
                          ),
                        ),

                        const SizedBox(
                          height: 7,
                        ),

                        Text(
                          'Manager di ${team['name'] ?? 'Team'}',
                          style:
                              const TextStyle(
                            fontSize:
                                15,
                            color:
                                primaryBrown,
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        const Text(
                          'Gestione team',
                          style:
                              TextStyle(
                            fontSize:
                                21,
                            fontWeight:
                                FontWeight
                                    .w500,
                            color:
                                primaryBrown,
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        ManagerHomeCard(
                          icon: Icons
                              .add_task_outlined,
                          title:
                              'Crea un nuovo task',
                          description:
                              'Definisci attività, scadenza, priorità e skills richieste.',
                          onTap:
                              openCreate,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        ManagerHomeCard(
                          icon: Icons
                              .people_outline,
                          title:
                              'Candidati',
                          description:
                              'Visualizza candidature, compatibilità e carico di lavoro.',
                          onTap:
                              openCandidates,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        ManagerHomeCard(
                          icon: Icons
                              .dashboard_outlined,
                          title:
                              'Dashboard',
                          description:
                              'Ottieni una visione sintetica dello stato delle attività.',
                          onTap:
                              openDashboard,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        ManagerHomeCard(
                          icon: Icons
                              .assignment_outlined,
                          title:
                              'Gestione task',
                          description:
                              'Consulta task aperti, assegnati e completati.',
                          onTap:
                              openTasks,
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
    );
  }
}

// =============================================================
// HOME BAR
// =============================================================

class _HomeManagerBar
    extends StatelessWidget {
  final VoidCallback onCandidates;
  final VoidCallback onDashboard;
  final VoidCallback onCreate;
  final VoidCallback onTasks;
  final VoidCallback onProfile;

  const _HomeManagerBar({
    required this.onCandidates,
    required this.onDashboard,
    required this.onCreate,
    required this.onTasks,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(
      String label,
      IconData icon,
      VoidCallback onTap,
    ) {
      return InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(30),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 29,
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
                  fontSize: 12,
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

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 9,
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
            MainAxisAlignment
                .spaceEvenly,
        children: [
          item(
            'candidati',
            Icons.people_outline,
            onCandidates,
          ),
          item(
            'dashboard',
            Icons.dashboard_outlined,
            onDashboard,
          ),
          item(
            'crea',
            Icons.add_circle_outline,
            onCreate,
          ),
          item(
            'task',
            Icons.assignment_outlined,
            onTasks,
          ),
          item(
            'profile',
            Icons.person_outline,
            onProfile,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// HOME CARD
// =============================================================

class ManagerHomeCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const ManagerHomeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
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
            0.08,
          ),
          borderRadius:
              BorderRadius.circular(
            25,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration:
                  const BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    Color.fromRGBO(
                  87,
                  57,
                  57,
                  0.12,
                ),
              ),
              child: Icon(
                icon,
                color:
                    const Color(
                  0xFF573939,
                ),
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight
                              .w500,
                      color:
                          Color(
                        0xFF573939,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    description,
                    style:
                        const TextStyle(
                      fontSize:
                          13,
                      color:
                          Color(
                        0xFF573939,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color:
                  Color(
                0xFF573939,
              ),
            ),
          ],
        ),
      ),
    );
  }
}