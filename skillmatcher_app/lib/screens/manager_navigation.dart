import 'package:flutter/material.dart';

enum ManagerSection {
  candidates,
  dashboard,
  create,
  tasks,
  profile,
}

class ManagerNavigationBar extends StatelessWidget {
  final ManagerSection? selected;

  final VoidCallback onCandidates;
  final VoidCallback onDashboard;
  final VoidCallback onCreate;
  final VoidCallback onTasks;
  final VoidCallback onProfile;

  const ManagerNavigationBar({
    super.key,
    required this.onCandidates,
    required this.onDashboard,
    required this.onCreate,
    required this.onTasks,
    required this.onProfile,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 9,
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ManagerNavigationItem(
            label: 'candidati',
            icon: Icons.people_outline,
            selected:
                selected == ManagerSection.candidates,
            onTap: onCandidates,
          ),
          ManagerNavigationItem(
            label: 'dashboard',
            icon: Icons.dashboard_outlined,
            selected:
                selected == ManagerSection.dashboard,
            onTap: onDashboard,
          ),
          ManagerNavigationItem(
            label: 'crea',
            icon: Icons.add_circle_outline,
            selected:
                selected == ManagerSection.create,
            onTap: onCreate,
          ),
          ManagerNavigationItem(
            label: 'task',
            icon: Icons.assignment_outlined,
            selected:
                selected == ManagerSection.tasks,
            onTap: onTasks,
          ),
          ManagerNavigationItem(
            label: 'profile',
            icon: Icons.person_outline,
            selected:
                selected == ManagerSection.profile,
            onTap: onProfile,
          ),
        ],
      ),
    );
  }
}

class ManagerNavigationItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const ManagerNavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 15 : 11,
          vertical: selected ? 9 : 7,
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
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: selected ? 32 : 29,
              color: const Color(0xFF321414),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF321414),
              ),
            ),
          ],
        ),
      ),
    );
  }
}