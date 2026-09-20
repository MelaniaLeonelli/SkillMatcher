import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'profile_screen.dart';
import 'task_screen.dart';
import 'skills_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> teams;

  const HomeScreen({
    super.key,
    required this.user,
    required this.teams,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  bool isProcessingTask = false;

  String? errorMessage;

  List<dynamic> recommendations = [];

  static const Color backgroundColor =
      Color.fromRGBO(87, 57, 57, 0.82);

  static const Color darkBrown = Color(0xFF321414);
  static const Color primaryBrown = Color(0xFF573939);
  static const Color cardColor = Color(0xFFE6E0E0);

  @override
  void initState() {
    super.initState();
    loadRecommendations();
  }

  // ============================================================
  // LOAD RECOMMENDATIONS
  // ============================================================

  Future<void> loadRecommendations() async {
    try {
      final team = widget.teams.first;
      final int teamId = team['team_id'];

      final result =
          await ApiService.getRecommendations(teamId);

      if (!mounted) return;

      setState(() {
        recommendations = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // CURRENT TASK
  // ============================================================

  Map<String, dynamic>? get currentTask {
    if (recommendations.isEmpty) {
      return null;
    }

    return recommendations.first as Map<String, dynamic>;
  }

  // ============================================================
  // APPLY
  // ============================================================

  Future<bool> applyToTask(
    Map<String, dynamic> task,
  ) async {
    if (isProcessingTask) {
      return false;
    }

    final int taskId = task['task_id'];
    final int employeeId = widget.user['id'];

    setState(() {
      isProcessingTask = true;
      errorMessage = null;
    });

    try {
      await ApiService.applyToTask(
        taskId: taskId,
        employeeId: employeeId,
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      setState(() {
        errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
      });

      return false;
    } finally {
      if (mounted) {
        setState(() {
          isProcessingTask = false;
        });
      }
    }
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<bool> rejectTask(
    Map<String, dynamic> task,
  ) async {
    if (isProcessingTask) {
      return false;
    }

    final int taskId = task['task_id'];
    final int employeeId = widget.user['id'];

    setState(() {
      isProcessingTask = true;
      errorMessage = null;
    });

    try {
      await ApiService.rejectTask(
        taskId: taskId,
        employeeId: employeeId,
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      setState(() {
        errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
      });

      return false;
    } finally {
      if (mounted) {
        setState(() {
          isProcessingTask = false;
        });
      }
    }
  }

  // ============================================================
  // SWIPE
  //
  // DESTRA = CANDIDATURA
  // SINISTRA = RIFIUTO
  // ============================================================

  Future<bool> handleSwipe(
    DismissDirection direction,
    Map<String, dynamic> task,
  ) async {
    // Destra = candidatura
    if (direction == DismissDirection.startToEnd) {
      return await applyToTask(task);
    }

    // Sinistra = rifiuto
    if (direction == DismissDirection.endToStart) {
      return await rejectTask(task);
    }

    return false;
  }

  // ============================================================
  // AFTER SWIPE
  // ============================================================

  void handleDismissed(
    DismissDirection direction,
  ) {
    if (recommendations.isNotEmpty) {
      recommendations.removeAt(0);
    }

    setState(() {});

    // Destra = candidatura
    if (direction == DismissDirection.startToEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Candidatura inviata con successo',
          ),
        ),
      );
    } else {
      // Sinistra = rifiuto
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task rifiutato'),
        ),
      );
    }
  }

  // ============================================================
  // FORMAT DEADLINE
  // ============================================================

  String formatDeadline(String? deadline) {
    if (deadline == null || deadline.isEmpty) {
      return 'Nessuna scadenza';
    }

    final parts = deadline.split('-');

    if (parts.length != 3) {
      return deadline;
    }

    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void openTaskScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskScreen(
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
        builder: (context) => ProfileScreen(
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
  Widget build(BuildContext context) {
    final team = widget.teams.first;
    final task = currentTask;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // =====================================================
            // NAVIGATION SUPERIORE
            // =====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(
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
                  TopNavigationItem(
                    label: 'swipe',
                    selected: true,
                    imagePath: 'assets/images/logo.png',
                    onTap: () {},
                  ),
                  TopNavigationItem(
                    label: 'task',
                    icon: Icons.assignment_outlined,
                    onTap: openTaskScreen,
                  ),
                  TopNavigationItem(
                    label: 'skills',
                    icon:
                        Icons.settings_suggest_outlined,
                    onTap: () {
                      Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                      builder: (context) => SkillsScreen(
                      user: widget.user,
                      teams: widget.teams,
                    ),
                    ),
                  );
                    },
                  ),
                  TopNavigationItem(
                    label: 'profile',
                    icon: Icons.person_outline,
                    onTap: openProfile,
                  ),
                ],
              ),
            ),

            // =====================================================
            // MAIN CONTENT
            // =====================================================

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : errorMessage != null &&
                          task == null
                      ? _buildError()
                      : task == null
                          ? _buildNoTasks()
                          : _buildTaskContent(
                              task: task,
                              team: team,
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TASK CONTENT
  // ============================================================

  Widget _buildTaskContent({
    required Map<String, dynamic> task,
    required dynamic team,
  }) {
    final String title =
        task['title']?.toString() ?? 'Task';

    final double compatibility =
        (task['compatibility'] as num?)
                ?.toDouble() ??
            0;

    final String description =
        task['description']?.toString() ??
            'Nessuna descrizione disponibile';

    final String? deadline =
        task['deadline']?.toString();

    final List<dynamic> skills =
        task['skills'] is List
            ? task['skills'] as List<dynamic>
            : [];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight - 48,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                // =================================================
                // SWIPEABLE CARD
                // =================================================

                ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 620,
                  ),
                  child: Dismissible(
                    key: ValueKey(
                      task['task_id'],
                    ),

                    direction:
                        DismissDirection.horizontal,

                    confirmDismiss: (direction) {
                      return handleSwipe(
                        direction,
                        task,
                      );
                    },

                    onDismissed:
                        handleDismissed,

                    // =================================================
                    // SWIPE DESTRA = RIFIUTA
                    // =================================================

                    background: Container(
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF9E5148,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          50,
                        ),
                      ),
                      padding:
                          const EdgeInsets
                              .only(
                        left: 40,
                      ),
                      alignment:
                          Alignment
                              .centerLeft,
                      child: const Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Icon(
                            Icons.close,
                            color:
                                Colors.white,
                            size: 50,
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            'RIFIUTA',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // =================================================
                    // SWIPE SINISTRA = CANDIDATI
                    // =================================================

                    secondaryBackground:
                        Container(
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF7DA786,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          50,
                        ),
                      ),
                      padding:
                          const EdgeInsets
                              .only(
                        right: 40,
                      ),
                      alignment:
                          Alignment
                              .centerRight,
                      child: const Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Icon(
                            Icons.favorite,
                            color:
                                Colors.white,
                            size: 50,
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            'CANDIDATI',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // =================================================
                    // CARD
                    // =================================================

                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 32,
                        vertical: 30,
                      ),
                      decoration:
                          BoxDecoration(
                        color: cardColor,
                        borderRadius:
                            BorderRadius
                                .circular(
                          50,
                        ),
                        boxShadow:
                            const [
                          BoxShadow(
                            color: Colors
                                .black12,
                            blurRadius: 15,
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
                          // ===========================================
                          // TITLE
                          // ===========================================

                          Text(
                            title
                                .toUpperCase(),
                            style:
                                const TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight
                                      .w500,
                              color:
                                  primaryBrown,
                            ),
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          // ===========================================
                          // TEAM + DEADLINE + COMPATIBILITY
                          // ===========================================

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    InfoRow(
                                      icon: Icons
                                          .business_outlined,
                                      text:
                                          '${team['name'] ?? 'Team'}',
                                    ),

                                    const SizedBox(
                                      height: 10,
                                    ),

                                    InfoRow(
                                      icon: Icons
                                          .calendar_today_outlined,
                                      text:
                                          'Scadenza: ${formatDeadline(deadline)}',
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                width: 24,
                              ),

                              CompatibilityIndicator(
                                value:
                                    compatibility,
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 26,
                          ),

                          // ===========================================
                          // DESCRIPTION
                          // ===========================================

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Icon(
                                Icons
                                    .description_outlined,
                                color:
                                    primaryBrown,
                                size: 21,
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Text(
                                      'Descrizione',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            15,
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

                                    Text(
                                      description,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            14,
                                        height: 1.4,
                                        color:
                                            primaryBrown,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 22,
                          ),

                          const Divider(
                            color:
                                Color.fromRGBO(
                              87,
                              57,
                              57,
                              0.18,
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ===========================================
                          // SKILLS
                          // ===========================================

                          const Text(
                            'Skills richieste',
                            style:
                                TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight
                                      .w500,
                              color:
                                  primaryBrown,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          if (skills.isEmpty)
                            const Text(
                              'Nessuna skill specificata',
                              style:
                                  TextStyle(
                                fontSize:
                                    13,
                                color:
                                    primaryBrown,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children:
                                  skills
                                      .map(
                                (skill) {
                                  return SkillChip(
                                    label: skill
                                        .toString(),
                                  );
                                },
                              ).toList(),
                            ),

                          if (errorMessage !=
                              null) ...[
                            const SizedBox(
                              height: 20,
                            ),
                            Text(
                              errorMessage!,
                              style:
                                  const TextStyle(
                                color: Colors
                                    .redAccent,
                                fontSize:
                                    13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // =================================================
                // SWIPE INDICATOR
                // =================================================

                if (isProcessingTask)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                else
                  const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: darkBrown,
                        size: 25,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'CANDIDATI',
                        style: TextStyle(
                          color: darkBrown,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 18),
                      Text(
                        'swipe',
                        style: TextStyle(
                          color: darkBrown,
                          fontSize: 17,
                          fontStyle:
                              FontStyle.italic,
                        ),
                      ),
                      SizedBox(width: 18),
                      Text(
                        'RIFIUTA',
                        style: TextStyle(
                          color: darkBrown,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: darkBrown,
                        size: 25,
                      ),
                    ],
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // NO TASKS
  // ============================================================

  Widget _buildNoTasks() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.task_alt,
              size: 70,
              color: Colors.white70,
            ),

            const SizedBox(height: 20),

            const Text(
              'Nessun task disponibile al momento',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                });

                loadRecommendations();
              },
              child:
                  const Text('Aggiorna'),
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
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 60,
            ),

            const SizedBox(height: 20),

            Text(
              errorMessage ?? 'Errore',
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });

                loadRecommendations();
              },
              child:
                  const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// TOP NAVIGATION
// =============================================================

class TopNavigationItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? imagePath;
  final bool selected;
  final VoidCallback onTap;

  const TopNavigationItem({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.imagePath,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(30),
      child: Container(
        padding:
            EdgeInsets.symmetric(
          horizontal:
              selected ? 22 : 18,
          vertical:
              selected ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color.fromRGBO(
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
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              )
            else
              Icon(
                icon,
                size: 30,
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

// =============================================================
// INFO ROW
// =============================================================

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color:
              const Color(
            0xFF573939,
          ),
        ),

        const SizedBox(width: 9),

        Flexible(
          child: Text(
            text,
            style:
                const TextStyle(
              fontSize: 14,
              color:
                  Color(
                0xFF573939,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// COMPATIBILITY
// =============================================================

class CompatibilityIndicator extends StatelessWidget {
  final double value;

  const CompatibilityIndicator({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final double safeValue =
        value.clamp(
          0,
          100,
        ).toDouble();

    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment:
                Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child:
                    CircularProgressIndicator(
                  value:
                      safeValue / 100,
                  strokeWidth: 8,
                  backgroundColor:
                      const Color(
                    0xFFC8C8C8,
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
                  fontSize: 23,
                  color:
                      Color(
                    0xFF573939,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Compatibilità',
          style: TextStyle(
            fontSize: 13,
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

// =============================================================
// SKILL CHIP
// =============================================================

class SkillChip extends StatelessWidget {
  final String label;

  const SkillChip({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(
          87,
          57,
          57,
          0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          25,
        ),
      ),
      child: Text(
        label,
        style:
            const TextStyle(
          fontSize: 13,
          color:
              Color(
            0xFF573939,
          ),
        ),
      ),
    );
  }
}