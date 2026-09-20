import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'skills_screen.dart';

class TaskScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> teams;

  const TaskScreen({
    super.key,
    required this.user,
    required this.teams,
  });

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  static const Color backgroundColor =
      Color.fromRGBO(87, 57, 57, 0.82);

  static const Color primaryBrown =
      Color(0xFF573939);

  static const Color darkBrown =
      Color(0xFF321414);

  static const Color cardColor =
      Color(0xFFE6E0E0);

  bool isLoading = true;
  String? errorMessage;

  List<dynamic> assignments = [];

  @override
  void initState() {
    super.initState();
    loadAssignments();
  }

  // ============================================================
  // LOAD ASSIGNMENTS
  // ============================================================

  Future<void> loadAssignments() async {
    try {
      final result =
          await ApiService.getMyAssignments();

      if (!mounted) return;

      setState(() {
        assignments = result;
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
  // COMPLETE TASK
  // ============================================================

  Future<void> completeTask(
    int taskId,
  ) async {
    try {
      await ApiService.completeTask(
        taskId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Task completato con successo',
          ),
        ),
      );

      await loadAssignments();
    } catch (e) {
      if (!mounted) return;

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
  // NAVIGATION
  // ============================================================

  void openHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
      (route) => false,
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // =====================================================
            // TOP BAR
            // =====================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 10,
              ),
              decoration:
                  const BoxDecoration(
                color: Color.fromRGBO(
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
                  TopNavigationItem(
                    label: 'swipe',
                    imagePath:
                        'assets/images/logo.png',
                    onTap: openHome,
                  ),

                  TopNavigationItem(
                    label: 'task',
                    icon: Icons
                        .assignment_outlined,
                    selected: true,
                    onTap: () {},
                  ),

                  TopNavigationItem(
                    label: 'skills',
                    icon: Icons
                        .settings_suggest_outlined,
                    onTap: () {Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SkillsScreen(
                          user: widget.user,
                          teams: widget.teams,
                        ),
                      ),
                    );},
                  ),

                  TopNavigationItem(
                    label: 'profile',
                    icon:
                        Icons.person_outline,
                    onTap: openProfile,
                  ),
                ],
              ),
            ),

            // =====================================================
            // BODY
            // =====================================================

            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : errorMessage != null
                      ? _buildError()
                      : assignments.isEmpty
                          ? _buildEmpty()
                          : _buildAssignments(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ASSIGNMENTS LIST
  // ============================================================

  Widget _buildAssignments() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      itemCount: assignments.length,
      itemBuilder: (
        context,
        index,
      ) {
        final assignment =
            assignments[index];

        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 18,
          ),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints:
                  const BoxConstraints(
                maxWidth: 620,
              ),
              padding:
                  const EdgeInsets.all(
                26,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    BorderRadius.circular(
                  35,
                ),
                boxShadow: const [
                  BoxShadow(
                    color:
                        Colors.black12,
                    blurRadius: 12,
                    offset:
                        Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    assignment['title']
                            ?.toString()
                            .toUpperCase() ??
                        'TASK',
                    style:
                        const TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.w500,
                      color:
                          primaryBrown,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  InfoRow(
                    icon: Icons
                        .business_outlined,
                    text:
                        'Team ${assignment['team_id']}',
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  InfoRow(
                    icon:
                        Icons.flag_outlined,
                    text:
                        'Stato: ${assignment['status']}',
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  if (assignment[
                          'status'] ==
                      'assigned')
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton.icon(
                        onPressed: () {
                          completeTask(
                            assignment[
                                'task_id'],
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .check_circle_outline,
                        ),
                        label:
                            const Text(
                          'SEGNA COME COMPLETATO',
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              primaryBrown,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 10,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color
                                .fromRGBO(
                          110,
                          156,
                          119,
                          0.15,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child:
                          const Center(
                        child: Text(
                          'COMPLETATO',
                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFF507A59,
                            ),
                            fontWeight:
                                FontWeight
                                    .w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 70,
            color: Colors.white70,
          ),

          const SizedBox(height: 20),

          const Text(
            'Nessun task assegnato',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 15),

          ElevatedButton(
            onPressed:
                loadAssignments,
            child:
                const Text('Aggiorna'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.white,
          ),

          const SizedBox(height: 20),

          Text(
            errorMessage ??
                'Errore',
            style:
                const TextStyle(
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });

              loadAssignments();
            },
            child:
                const Text('Riprova'),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TOP NAVIGATION
// =============================================================

class TopNavigationItem
    extends StatelessWidget {
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

class InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
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

        const SizedBox(
          width: 9,
        ),

        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(
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