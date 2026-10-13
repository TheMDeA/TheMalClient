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

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // Silent daily update check after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoCheckUpdate();
    });
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
      body: widget.shell,
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
