import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';

/// The app's four destinations, behind a floating pill tab bar (the Qonto
/// pattern): a raised capsule that sits *on* the paper rather than a slab
/// welded to the bottom edge.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  late int _index = widget.initialIndex;

  static const _tabs = [
    (Icons.local_fire_department_outlined, Icons.local_fire_department,
        'Desires'),
    (Icons.insights_outlined, Icons.insights, 'Wealth'),
    (Icons.workspace_premium_outlined, Icons.workspace_premium, 'Pro'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pages keep their scroll position and state across tab switches.
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          DashboardScreen(),
          PaywallScreen(embedded: true),
          SettingsScreen(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.paperHigh,
              borderRadius: BorderRadius.circular(32),
              boxShadow: AppColors.cardShadow(opacity: 0.12),
            ),
            child: Row(
              children: [
                for (final (i, tab) in _tabs.indexed)
                  Expanded(
                    child: _Tab(
                      icon: tab.$1,
                      activeIcon: tab.$2,
                      label: tab.$3,
                      selected: i == _index,
                      onTap: () {
                        if (i == _index) return;
                        HapticFeedback.selectionClick();
                        setState(() => _index = i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab: the active one grows a soft pill behind it and swaps to the
/// filled icon, so the selection reads without relying on color alone.
class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textMid;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? activeIcon : icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
