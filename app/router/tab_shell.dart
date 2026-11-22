import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// The root tab scaffold.
///
/// go_router's [StatefulShellRoute] owns one [Navigator] per tab and hands them
/// to us as [branchNavigators]; [CupertinoTabScaffold] owns the bar and the
/// selection.
/// The two are joined here rather than via `StatefulShellRoute.indexedStack`,
/// which would wrap the branches in a second [IndexedStack] underneath the tab
/// scaffold's own.
class TabShell extends StatefulWidget {
  const TabShell({
    required this.navigationShell,
    required this.branchNavigators,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> branchNavigators;

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  late final CupertinoTabController _controller = CupertinoTabController(
    initialIndex: widget.navigationShell.currentIndex,
  );

  @override
  void didUpdateWidget(TabShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The branch can change without a tab tap (deep link, programmatic go).
    if (_controller.index != widget.navigationShell.currentIndex) {
      _controller.index = widget.navigationShell.currentIndex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    // Tapping the active tab pops that branch back to its root, as iOS does.
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _controller,
      tabBar: CupertinoTabBar(
        onTap: _onTap,
        backgroundColor: AppColors.surfacePage,
        activeColor: AppColors.accentPrimary,
        inactiveColor: AppColors.textSecondary,
        border: const Border(
          top: BorderSide(
            color: AppColors.surfaceControl,
            width: 0,
          ),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.flame_fill),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_alt_fill),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) => widget.branchNavigators[index],
    );
  }
}
