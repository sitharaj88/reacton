import 'package:flutter/material.dart';
import '../services/reacton_service.dart';
import 'graph_view.dart';
import 'reacton_inspector.dart';
import 'timeline_view.dart';
import 'performance_view.dart';

/// Main DevTools extension app.
///
/// Provides a tabbed interface with:
/// - Graph View: Interactive dependency graph
/// - Inspector: Reacton values and metadata
/// - Timeline: State change history
/// - Performance: Recomputation metrics
class ReactonDevToolsApp extends StatefulWidget {
  final ReactonDevToolsService service;

  const ReactonDevToolsApp({super.key, required this.service});

  @override
  State<ReactonDevToolsApp> createState() => _ReactonDevToolsAppState();
}

class _ReactonDevToolsAppState extends State<ReactonDevToolsApp>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reacton DevTools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.hub_outlined, size: 20),
              SizedBox(width: 8),
              Text('Reacton DevTools'),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.account_tree), text: 'Graph'),
              Tab(icon: Icon(Icons.search), text: 'Inspector'),
              Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
              Tab(icon: Icon(Icons.speed), text: 'Performance'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            GraphView(service: widget.service),
            ReactonInspector(service: widget.service),
            TimelineView(service: widget.service),
            PerformanceView(service: widget.service),
          ],
        ),
      ),
    );
  }
}
