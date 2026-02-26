import 'package:flutter/material.dart';

import 'features/counter/counter_page.dart';
import 'features/todos/todos_page.dart';
import 'features/auth/auth_page.dart';
import 'features/form/registration_page.dart';
import 'features/time_travel/time_travel_page.dart';
import 'features/dashboard/dashboard_page.dart';

// ============================================================================
// ShowcaseApp -- Material 3 shell with NavigationRail
//
// Each destination maps to a feature page that demonstrates a distinct set of
// Reacton capabilities.
// ============================================================================

class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reacton Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const _ShellPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation destinations
// ---------------------------------------------------------------------------

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
  final String subtitle;

  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
    required this.subtitle,
  });
}

const _destinations = <_Destination>[
  _Destination(
    label: 'Counter',
    icon: Icons.add_circle_outline,
    selectedIcon: Icons.add_circle,
    page: CounterPage(),
    subtitle: 'reacton, computed, context.watch/set',
  ),
  _Destination(
    label: 'Todos',
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist,
    page: TodosPage(),
    subtitle: 'reactonList, lens, computed filters',
  ),
  _Destination(
    label: 'Auth',
    icon: Icons.lock_outline,
    selectedIcon: Icons.lock,
    page: AuthPage(),
    subtitle: 'stateMachine, send, ReactonListener',
  ),
  _Destination(
    label: 'Form',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
    page: RegistrationPage(),
    subtitle: 'reactonField, reactonForm, validators',
  ),
  _Destination(
    label: 'Time Travel',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
    page: TimeTravelPage(),
    subtitle: 'enableHistory, undo/redo, snapshot',
  ),
  _Destination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    page: DashboardPage(),
    subtitle: 'family, selector, batch, computed chains',
  ),
];

// ---------------------------------------------------------------------------
// Shell page with adaptive navigation (rail on wide, bottom on narrow)
// ---------------------------------------------------------------------------

class _ShellPage extends StatefulWidget {
  const _ShellPage();

  @override
  State<_ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<_ShellPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
    );
  }

  // --- Wide: NavigationRail + content ---
  Widget _buildWideLayout() {
    final theme = Theme.of(context);
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(Icons.science, color: theme.colorScheme.primary, size: 32),
                const SizedBox(height: 4),
                Text(
                  'Reacton',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          destinations: [
            for (final d in _destinations)
              NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.label),
              ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: _destinations[_selectedIndex].page,
        ),
      ],
    );
  }

  // --- Narrow: content only (bottom nav provides navigation) ---
  Widget _buildNarrowLayout() {
    return _destinations[_selectedIndex].page;
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      destinations: [
        for (final d in _destinations)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ),
      ],
    );
  }
}
