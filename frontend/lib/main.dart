import 'dart:async';

import 'package:flutter/material.dart';

import 'core/api.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'views/infrastructure_view.dart';
import 'views/agents_view.dart';
import 'views/automations_view.dart';
import 'models/container.dart';
import 'models/event.dart';
import 'widgets/header_bar.dart';

void main() {
  runApp(const AntigravityApp());
}

class AntigravityApp extends StatelessWidget {
  const AntigravityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Angel Ctrl',
      theme: buildDarkTheme(),
      home: const DashboardShell(),
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});
  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  DashboardMode _mode = DashboardMode.infrastructure;
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _hostStats = {};
  Map<String, dynamic> _system = {};
  List<ContainerMetrics> _containers = [];
  List<dynamic> _aiProviders = [];
  List<Event> _events = [];

  Timer? _timer;
  int _tick = 0;
  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
        Duration(seconds: pollingIntervalSeconds), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addEvent(String text, {String type = 'info'}) {
    setState(() {
      _events.insert(0, Event(time: DateTime.now(), text: text, type: type));
      if (_events.length > maxEvents)
        _events.removeRange(maxEvents, _events.length);
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _api.getJson('/api/stats/host'),
        _api.getJson('/system/info'),
        _api.getJson('/api/containers'),
        _api.getJson('/api/ai/providers'),
      ]);

      final host = results[0] as Map<String, dynamic>;
      final system = results[1] as Map<String, dynamic>;
      final containersRaw = results[2] as List<dynamic>;
      final aiProviders = results[3] as List<dynamic>;

      final runningIds = containersRaw
          .where((c) => (c as Map)['status'] == 'running')
          .map((c) => (c as Map)['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final metricsResults = await Future.wait(
        runningIds.map((id) => _api
            .getJson('/api/containers/$id/metrics')
            .catchError((_) => <String, dynamic>{})),
      );

      final newMetrics = <String, Map<String, dynamic>>{};
      for (var i = 0; i < runningIds.length; i++) {
        final m = metricsResults[i];
        if (m is Map<String, dynamic> && m.isNotEmpty) {
          newMetrics[runningIds[i]] = m;
        }
      }

      if (!mounted) return;

      final oldMap = <String, ContainerMetrics>{
        for (final c in _containers) c.id: c
      };
      final newContainers = <ContainerMetrics>[];
      for (final r in containersRaw) {
        final cData = r as Map<String, dynamic>;
        final id = cData['id']?.toString() ?? '';
        final m = newMetrics[id];
        final old = oldMap[id];

        double? cpu = (m?['cpu_percent'] as num?)?.toDouble();
        double? mem = (m?['memory_percent'] as num?)?.toDouble();

        final cpuHistory = <double>[]..addAll(old?.cpuHistory ?? []);
        final memHistory = <double>[]..addAll(old?.memHistory ?? []);
        if (cpu != null) {
          cpuHistory.add(cpu);
          if (cpuHistory.length > sparklinePoints) cpuHistory.removeAt(0);
        }
        if (mem != null) {
          memHistory.add(mem);
          if (memHistory.length > sparklinePoints) memHistory.removeAt(0);
        }

        newContainers.add(ContainerMetrics(
          id: id,
          name: cData['name']?.toString() ?? 'unknown',
          project: cData['project']?.toString() ?? 'otros',
          image: cData['image']?.toString() ?? '',
          status: cData['status']?.toString() ?? 'unknown',
          state: cData['state']?.toString() ?? '',
          uptimeSeconds: cData['uptime_seconds'] as int? ?? 0,
          restartCount: cData['restart_count'] as int? ?? 0,
          cpuPercent: cpu,
          memoryPercent: mem,
          memoryUsageBytes: m?['memory_usage_bytes'] as int?,
          memoryLimitBytes: m?['memory_limit_bytes'] as int?,
          networkRxBytes: m?['network_rx_bytes'] as int?,
          networkTxBytes: m?['network_tx_bytes'] as int?,
          cpuHistory: cpuHistory,
          memHistory: memHistory,
        ));
      }

      _tick++;
      if (_tick % 2 == 0) {
        _addEvent('Health OK  ·  ${host['hostname'] ?? 'sistema'}', type: 'ok');
      }

      if (!mounted) return;
      setState(() {
        _hostStats = host;
        _system = system;
        _containers = newContainers;
        _aiProviders = aiProviders;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      _addEvent(
        'Error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e.toString()}',
        type: 'error',
      );
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            AppNav(
              hostStats: _hostStats,
              mode: _mode,
              onModeChanged: (m) => setState(() => _mode = m),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: blue))
                    : _error != null
                        ? ErrorState(message: _error!)
                        : _body(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_mode) {
      case DashboardMode.infrastructure:
        return InfrastructureView(
          hostStats: _hostStats,
          containers: _containers,
          system: _system,
          events: _events,
          onRefresh: () => _load(),
          api: _api,
          onEvent: _addEvent,
        );
      case DashboardMode.agents:
        return AgentsView(providers: _aiProviders);
      case DashboardMode.automations:
        return const PlaceholderView(label: 'Automatizaciones');
    }
  }
}
