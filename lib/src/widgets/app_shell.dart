import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/services/update_service.dart';
import 'package:malclient/src/features/settings/update_sheet.dart';

/// Bottom-navigation shell for the 5 main tabs (M3 NavigationBar).
/// Runs the silent daily update check on startup.
class AppShell extends StatefulWidget {
  final StatefulNavigationShell shell;

  const AppShell({super.key, required this.shell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tabFade;
  late int _lastIndex;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.shell.currentIndex;
    _tabFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1.0,
    );
    // Silent daily update check after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoCheckUpdate();
    });
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Soft fade-in on tab switch. The shell itself stays mounted so
    // go_router keeps every tab's navigation stack intact.
    if (widget.shell.currentIndex != _lastIndex) {
      _lastIndex = widget.shell.currentIndex;
      _tabFade.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _tabFade.dispose();
    super.dispose();
  }

  Future<void> _autoCheckUpdate() async {
    final info = await maybeAutoCheckUpdate();
    if (!mounted || info == null) return;
    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update available: v${info.version}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            if (mounted) showUpdateSheet(context, info);
          },
        ),
        duration: const Duration(seconds: 8),
      ),
    );
    // Don't nag: swiping away or timing out snoozes this version.
    controller.closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        dismissUpdateVersion(info.version);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _tabFade,
        child: widget.shell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (index) => widget.shell.goBranch(
          index,
          initialLocation: index == widget.shell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'My List',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
