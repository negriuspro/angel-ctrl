import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/container.dart';
import '../models/event.dart';
import '../widgets/panel.dart';
import '../widgets/event_log.dart';
import '../widgets/service_card.dart';
import 'system_panel.dart';

class InfrastructureView extends StatelessWidget {
  final Map<String, dynamic> hostStats;
  final List<ContainerMetrics> containers;
  final Map<String, dynamic> system;
  final List<Event> events;
  final VoidCallback onRefresh;

  const InfrastructureView({
    super.key,
    required this.hostStats,
    required this.containers,
    required this.system,
    required this.events,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1100;
    final isMid = MediaQuery.of(context).size.width >= 700;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            title: 'SERVICIOS  (${containers.length})',
            icon: Icons.dns_rounded,
            accentColor: cyan,
            child: _buildServiceGrid(context, isMid),
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

  Widget _buildServiceGrid(BuildContext context, bool isMid) {
    if (containers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No se encontraron contenedores.',
            style: TextStyle(color: textSecondary, fontFamily: 'monospace')),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMid ? 3 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: containers.length,
        itemBuilder: (_, i) => ServiceCard(container: containers[i]),
      ),
    );
  }
}
