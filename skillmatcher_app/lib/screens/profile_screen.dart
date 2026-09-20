import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

import 'create_task_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'manager_candidates_screen.dart';
import 'manager_dashboard_screen.dart';
import 'manager_home_screen.dart';
import 'manager_tasks_screen.dart';
import 'skills_screen.dart';
import 'task_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> teams;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.teams,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  Uint8List? profileImage;

  List<Map<String, dynamic>> mySkills = [];

  List<dynamic> teamSkills = [];

  String description = 'Web Developer';

  // ============================================================
  // ROLE
  // ============================================================

  String get currentRole {
    if (widget.teams.isEmpty) {
      return '';
    }

    return widget.teams.first['role']
            ?.toString()
            .toLowerCase() ??
        '';
  }

  bool get isManager =>
      currentRole == 'manager';

  int get teamId =>
      widget.teams.first['team_id'];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> loadProfile() async {
    await loadProfileImage();

    if (!isManager) {
      await loadSkills();
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  String get profileImageKey {
    return 'profile_image_${widget.user['id']}';
  }

  Future<void> loadProfileImage() async {
    final prefs =
        await SharedPreferences.getInstance();

    final imageBase64 =
        prefs.getString(profileImageKey);

    if (imageBase64 == null) {
      return;
    }

    try {
      profileImage =
          base64Decode(imageBase64);
    } catch (_) {
      profileImage = null;
    }
  }

  Future<void> chooseProfileImage() async {
    final picker =
        ImagePicker();

    final image =
        await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    final bytes =
        await image.readAsBytes();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      profileImageKey,
      base64Encode(bytes),
    );

    if (!mounted) return;

    setState(() {
      profileImage = bytes;
    });
  }

  // ============================================================
  // SKILLS
  // ============================================================

  Future<void> loadSkills() async {
    try {
      if (widget.teams.isEmpty) {
        return;
      }

      final employeeSkills =
          await ApiService.getMySkills();

      final catalog =
          await ApiService.getTeamSkills(
        teamId,
      );

      final List<Map<String, dynamic>>
          resolvedSkills = [];

      for (final employeeSkill
          in employeeSkills) {
        final int skillId =
            employeeSkill['skill_id'];

        final matches =
            catalog.where(
          (skill) =>
              skill['id'] ==
              skillId,
        );

        if (matches.isEmpty) {
          continue;
        }

        final skill =
            matches.first;

        resolvedSkills.add({
          'id': skillId,
          'name': skill['name'],
          'level':
              employeeSkill['level'] ??
                  1,
        });
      }

      if (!mounted) return;

      setState(() {
        mySkills = resolvedSkills;
        teamSkills = catalog;
        errorMessage = null;
      });
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
    }
  }

  // ============================================================
  // ADD SKILL
  // ============================================================

  Future<void> showAddSkillDialog() async {
    if (isManager) {
      return;
    }

    final currentIds =
        mySkills
            .map(
              (skill) =>
                  skill['id'],
            )
            .toSet();

    final availableSkills =
        teamSkills
            .where(
              (skill) =>
                  !currentIds.contains(
                skill['id'],
              ),
            )
            .toList();

    if (availableSkills.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Non ci sono altre skill disponibili nel team',
          ),
        ),
      );

      return;
    }

    int selectedSkillId =
        availableSkills.first['id'];

    int selectedLevel = 1;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Aggiungi skill',
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue:
                        selectedSkillId,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Skill',
                    ),
                    items:
                        availableSkills.map(
                      (skill) {
                        return DropdownMenuItem<int>(
                          value:
                              skill['id'],
                          child: Text(
                            skill['name'],
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      selectedSkillId =
                          value;
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Row(
                    children: [
                      const Text(
                        'Livello:',
                      ),

                      const SizedBox(
                        width: 15,
                      ),

                      Expanded(
                        child: Slider(
                          value:
                              selectedLevel
                                  .toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label:
                              '$selectedLevel',
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

                      Text(
                        '$selectedLevel/5',
                      ),
                    ],
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
                  child: const Text(
                    'Annulla',
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiService
                          .addEmployeeSkill(
                        userId:
                            widget.user[
                                'id'],
                        skillId:
                            selectedSkillId,
                        level:
                            selectedLevel,
                      );

                      if (!mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );

                      await loadSkills();
                    } catch (e) {
                      if (!mounted) {
                        return;
                      }

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
                  },
                  child: const Text(
                    'Aggiungi',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  void editDescription() {
    final controller =
        TextEditingController(
      text: description,
    );

    showDialog(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Modifica descrizione',
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration:
                const InputDecoration(
              hintText:
                  'Scrivi una breve descrizione',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Annulla',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  description =
                      controller.text
                          .trim();
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Salva',
              ),
            ),
          ],
        );
      },
    );
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
  // HOME
  // ============================================================

  void openHome() {
    if (isManager) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
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

      return;
    }

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

  // ============================================================
  // MANAGER NAVIGATION
  // ============================================================

  void openManagerCandidates() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) =>
            ManagerCandidatesScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  void openManagerDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) =>
            ManagerDashboardScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  void openCreateTask() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) =>
            CreateTaskScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  void openManagerTasks() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) =>
            ManagerTasksScreen(
          user: widget.user,
          teams: widget.teams,
        ),
      ),
    );
  }

  // ============================================================
  // EMPLOYEE NAVIGATION
  // ============================================================

  void openEmployeeTasks() {
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

  void openSkills() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) =>
            SkillsScreen(
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
    final team =
        widget.teams.isNotEmpty
            ? widget.teams.first
            : null;

    return Scaffold(
      backgroundColor:
          backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            if (isManager)
              _buildManagerNavigation()
            else
              _buildEmployeeNavigation(),

            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Colors.white,
                      ),
                    )
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                        vertical: 24,
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
                                  .symmetric(
                            horizontal: 32,
                            vertical: 32,
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
                            children: [
                              // ================================
                              // AVATAR
                              // ================================

                              Stack(
                                clipBehavior:
                                    Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 58,
                                    backgroundColor:
                                        const Color(
                                      0xFFD9D9D9,
                                    ),
                                    backgroundImage:
                                        profileImage !=
                                                null
                                            ? MemoryImage(
                                                profileImage!,
                                              )
                                            : null,
                                    child:
                                        profileImage ==
                                                null
                                            ? const Icon(
                                                Icons
                                                    .person,
                                                size:
                                                    72,
                                                color:
                                                    primaryBrown,
                                              )
                                            : null,
                                  ),

                                  Positioned(
                                    right: -2,
                                    bottom: 2,
                                    child: InkWell(
                                      onTap:
                                          chooseProfileImage,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        30,
                                      ),
                                      child:
                                          Container(
                                        width: 38,
                                        height: 38,
                                        decoration:
                                            const BoxDecoration(
                                          shape:
                                              BoxShape
                                                  .circle,
                                          color:
                                              primaryBrown,
                                        ),
                                        child:
                                            const Icon(
                                          Icons
                                              .camera_alt_outlined,
                                          size: 20,
                                          color:
                                              Colors
                                                  .white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 20,
                              ),

                              // ================================
                              // NAME
                              // ================================

                              Text(
                                widget.user[
                                            'name']
                                        ?.toString() ??
                                    'Utente',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    const TextStyle(
                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight
                                          .w500,
                                  color:
                                      darkBrown,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                isManager
                                    ? 'Manager'
                                    : description,
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    const TextStyle(
                                  fontSize: 15,
                                  color:
                                      primaryBrown,
                                ),
                              ),

                              if (!isManager)
                                TextButton.icon(
                                  onPressed:
                                      editDescription,
                                  icon:
                                      const Icon(
                                    Icons.edit,
                                    size: 16,
                                  ),
                                  label:
                                      const Text(
                                    'Modifica descrizione',
                                  ),
                                ),

                              const SizedBox(
                                height: 15,
                              ),

                              // ================================
                              // EMAIL
                              // ================================

                              ProfileInfoCard(
                                icon: Icons
                                    .email_outlined,
                                label: 'Email',
                                value: widget
                                            .user[
                                        'email']
                                    ?.toString() ??
                                    '',
                              ),

                              // ================================
                              // TEAM
                              // ================================

                              if (team !=
                                  null) ...[
                                const SizedBox(
                                  height: 10,
                                ),

                                ProfileInfoCard(
                                  icon: Icons
                                      .business_outlined,
                                  label: 'Team',
                                  value: team[
                                              'name']
                                          ?.toString() ??
                                      '',
                                ),

                                const SizedBox(
                                  height: 10,
                                ),

                                ProfileInfoCard(
                                  icon: Icons
                                      .badge_outlined,
                                  label: 'Ruolo',
                                  value: isManager
                                      ? 'Manager'
                                      : 'Employee',
                                ),

                                // ==============================
                                // TEAM CODE - MANAGER ONLY
                                // ==============================

                                if (isManager) ...[
                                  const SizedBox(
                                    height: 10,
                                  ),

                                  TeamCodeCard(
                                    code: team[
                                                'invite_code']
                                            ?.toString() ??
                                        '',
                                  ),
                                ],
                              ],

                              const SizedBox(
                                height: 26,
                              ),

                              const Divider(),

                              const SizedBox(
                                height: 16,
                              ),

                              // ================================
                              // EMPLOYEE SKILLS
                              // ================================

                              if (!isManager) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    const Text(
                                      'Skills possedute',
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

                                    TextButton.icon(
                                      onPressed:
                                          openSkills,
                                      icon:
                                          const Icon(
                                        Icons
                                            .settings_suggest_outlined,
                                        size: 18,
                                      ),
                                      label:
                                          const Text(
                                        'Gestisci',
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                if (mySkills
                                    .isEmpty)
                                  const Align(
                                    alignment:
                                        Alignment
                                            .centerLeft,
                                    child: Text(
                                      'Nessuna skill inserita',
                                    ),
                                  )
                                else
                                  ...mySkills
                                      .map(
                                    (
                                      skill,
                                    ) =>
                                        SkillLevelRow(
                                      name: skill[
                                          'name'],
                                      level: skill[
                                              'level'] ??
                                          1,
                                    ),
                                  ),
                              ],

                              // ================================
                              // MANAGER INFO
                              // ================================

                              if (isManager)
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
                                      20,
                                    ),
                                  ),
                                  child:
                                      const Row(
                                    children: [
                                      Icon(
                                        Icons
                                            .admin_panel_settings_outlined,
                                        color:
                                            primaryBrown,
                                      ),

                                      SizedBox(
                                        width: 12,
                                      ),

                                      Expanded(
                                        child:
                                            Text(
                                          'Gestisci task, candidature e attività del team attraverso la dashboard manager.',
                                          style:
                                              TextStyle(
                                            color:
                                                primaryBrown,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // ================================
                              // ERROR
                              // ================================

                              if (errorMessage !=
                                  null) ...[
                                const SizedBox(
                                  height: 15,
                                ),

                                Text(
                                  errorMessage!,
                                  textAlign:
                                      TextAlign
                                          .center,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors
                                            .redAccent,
                                  ),
                                ),
                              ],

                              const SizedBox(
                                height: 30,
                              ),

                              // ================================
                              // LOGOUT
                              // ================================

                              SizedBox(
                                width:
                                    double.infinity,
                                height: 48,
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed:
                                      logout,
                                  icon:
                                      const Icon(
                                    Icons.logout,
                                  ),
                                  label:
                                      const Text(
                                    'LOGOUT',
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

      // ========================================================
      // HOME BUTTON
      // ========================================================

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
  // EMPLOYEE NAVIGATION BAR
  // ============================================================

  Widget _buildEmployeeNavigation() {
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
          ProfileNavigationItem(
            label: 'swipe',
            imagePath:
                'assets/images/logo.png',
            onTap: openHome,
          ),

          ProfileNavigationItem(
            label: 'task',
            icon: Icons
                .assignment_outlined,
            onTap:
                openEmployeeTasks,
          ),

          ProfileNavigationItem(
            label: 'skills',
            icon: Icons
                .settings_suggest_outlined,
            onTap:
                openSkills,
          ),

          ProfileNavigationItem(
            label: 'profile',
            icon: Icons
                .person_outline,
            selected: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MANAGER NAVIGATION BAR
  // ============================================================

  Widget _buildManagerNavigation() {
    return Container(
      width:
          double.infinity,
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
            MainAxisAlignment.spaceEvenly,
        children: [
          ProfileNavigationItem(
            label: 'candidati',
            icon:
                Icons.people_outline,
            onTap:
                openManagerCandidates,
          ),

          ProfileNavigationItem(
            label: 'dashboard',
            icon: Icons
                .dashboard_outlined,
            onTap:
                openManagerDashboard,
          ),

          ProfileNavigationItem(
            label: 'crea',
            icon: Icons
                .add_circle_outline,
            onTap:
                openCreateTask,
          ),

          ProfileNavigationItem(
            label: 'task',
            icon: Icons
                .assignment_outlined,
            onTap:
                openManagerTasks,
          ),

          ProfileNavigationItem(
            label: 'profile',
            icon: Icons
                .person_outline,
            selected: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// =============================================================
// NAVIGATION ITEM
// =============================================================

class ProfileNavigationItem
    extends StatelessWidget {
  final String label;

  final IconData? icon;

  final String? imagePath;

  final bool selected;

  final VoidCallback onTap;

  const ProfileNavigationItem({
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
              selected ? 15 : 11,
          vertical:
              selected ? 9 : 7,
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
          mainAxisSize:
              MainAxisSize.min,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              )
            else
              Icon(
                icon,
                size:
                    selected ? 32 : 29,
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
}

// =============================================================
// PROFILE INFO CARD
// =============================================================

class ProfileInfoCard
    extends StatelessWidget {
  final IconData icon;

  final String label;

  final String value;

  const ProfileInfoCard({
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
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
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
      child: Row(
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
            width: 10,
          ),

          Text(
            '$label:',
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

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              value,
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
      ),
    );
  }
}

// =============================================================
// TEAM INVITE CODE CARD
// =============================================================

class TeamCodeCard
    extends StatelessWidget {
  final String code;

  const TeamCodeCard({
    super.key,
    required this.code,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    const Color primaryBrown =
        Color(0xFF573939);

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
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
      child: Row(
        children: [
          const Icon(
            Icons.vpn_key_outlined,
            size: 20,
            color:
                primaryBrown,
          ),

          const SizedBox(
            width: 10,
          ),

          const Text(
            'Codice team:',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w500,
              color:
                  primaryBrown,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child:
                SelectableText(
              code.isEmpty
                  ? 'Non disponibile'
                  : code,
              style:
                  const TextStyle(
                color:
                    primaryBrown,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          if (code.isNotEmpty)
            IconButton(
              tooltip:
                  'Copia codice',

              icon:
                  const Icon(
                Icons.copy_outlined,
                size: 20,
                color:
                    primaryBrown,
              ),

              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: code,
                  ),
                );

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(
                  context,
                ).hideCurrentSnackBar();

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Codice team copiato',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// =============================================================
// SKILL LEVEL
// =============================================================

class SkillLevelRow
    extends StatelessWidget {
  final String name;

  final int level;

  const SkillLevelRow({
    super.key,
    required this.name,
    required this.level,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style:
                  const TextStyle(
                fontSize: 14,
                color:
                    Color(
                  0xFF321414,
                ),
              ),
            ),
          ),

          Row(
            children:
                List.generate(
              5,
              (
                index,
              ) {
                final active =
                    index < level;

                return Icon(
                  active
                      ? Icons.star
                      : Icons
                          .star_border,
                  size: 19,
                  color: active
                      ? const Color(
                          0xFF8B7474,
                        )
                      : const Color(
                          0xFFB8B8B8,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}