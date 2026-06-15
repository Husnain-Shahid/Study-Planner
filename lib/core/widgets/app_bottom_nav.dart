import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navBg = Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).colorScheme.surface;
    final navIsDark = navBg.computeLuminance() < 0.5;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 0, // Set to 0 if you want the sleek dark look from your image
      color: navBg,
      padding: EdgeInsets.zero, // 🚀 Fix: Removes default M3 padding that causes overflows
      height: 70, // 🚀 Fix: Explicit height for the bar
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.task_alt_rounded,
            label: 'Tasks',
            selected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(width: 52), // Space for the floating FAB
          _NavItem(
            icon: Icons.quiz_rounded,
            label: 'AI Quiz',
            selected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Analysis',
            selected: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navBg = Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).colorScheme.surface;
    final navIsDark = navBg.computeLuminance() < 0.5;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 🚀 Center content vertically
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selected 
                      ? (navIsDark ? Colors.white.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.12)) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? (navIsDark ? Colors.white : AppColors.primary) : (navIsDark ? Colors.white60 : Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'Poppins',
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? (navIsDark ? Colors.white : AppColors.primary) : (navIsDark ? Colors.white60 : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
