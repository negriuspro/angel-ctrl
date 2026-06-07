import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../models/container.dart';
import '../models/event.dart';
import '../widgets/panel.dart';
import '../widgets/event_log.dart';
import '../widgets/project_card.dart';
import 'system_panel.dart';

class InfrastructureView extends StatelessWidget {
  final Map<String, dynamic> hostStats;
  final List<ContainerMetrics> containers;
  final Map<String, dynamic> system;
  final List<Event> events;
  final VoidCallback onRefresh;
  final ApiClient api;
  final void Function(String text, {String type}) onEvent;

  const InfrastructureView({
    super.key,
    required this.hostStats,
    required this.containers,
    required this.system,
    required this.events,
    required this.onRefresh,
    required this.api,
    required this.onEvent,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            title: 'PROYECTOS  (${_groupByProject().length})',
            icon: Icons.dns_rounded,
            accentColor: cyan,
            child: _buildProjectList(context),
          ),
          const SizedBox(height: 10),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: SystemPanel(hostStats: hostStats)),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: EventLog(events: events)),
              ],
            )
          else
            Column(
              children: [
                SystemPanel(hostStats: hostStats),
                const SizedBox(height: 10),
                EventLog(events: events),
              ],
            ),
        ],
      ),
    );
  }

  Map<String, List<ContainerMetrics>> _groupByProject() {
    final groups = <String, List<ContainerMetrics>>{};
    for (final c in containers) {
      groups.putIfAbsent(c.project, () => []).add(c);
    }
    return groups;
  }

  Widget _buildProjectList(BuildContext context) {
    if (containers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No se encontraron contenedores.',
            style: TextStyle(color: textSecondary, fontFamily: 'monospace')),
      );
    }
    final groups = _groupByProject();
    final names = groups.keys.toList()..sort();
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1400
        ? 5
        : width >= 1100
            ? 4
            : width >= 760
                ? 3
                : 2;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: names.length,
        itemBuilder: (_, i) => ProjectCard(
          project: names[i],
          containers: groups[names[i]]!,
          api: api,
          onEvent: onEvent,
        ),
      ),
    );
  }
}
