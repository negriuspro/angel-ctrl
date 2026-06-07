import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../models/container.dart';
import 'logs_dialog.dart';
import 'service_card.dart';

/// Tile cuadrado que representa un proyecto (docker-compose) con sus
/// métricas agregadas. Al pulsarlo abre un diálogo con los contenedores
/// individuales, cada uno con su propio botón de reinicio y logs.
class ProjectCard extends StatelessWidget {
  final String project;
  final List<ContainerMetrics> containers;
  final ApiClient api;
  final void Function(String text, {String type}) onEvent;

  const ProjectCard({
    super.key,
    required this.project,
    required this.containers,
    required this.api,
    required this.onEvent,
  });

  static String displayName(String project) {
    if (project.isEmpty) return 'otros';
    return project[0].toUpperCase() + project.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final running = containers.where((c) => c.status == 'running').toList();
    final anyRunning = running.isNotEmpty;
    final statusColor = anyRunning ? green : textDim;

    final totalCpu =
        running.fold<double>(0, (sum, c) => sum + (c.cpuPercent ?? 0));
    final totalMem =
        running.fold<double>(0, (sum, c) => sum + (c.memoryPercent ?? 0));

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDialog(
          context: context,
          builder: (_) => _ProjectDialog(
            project: project,
            containers: containers,
            api: api,
            onEvent: onEvent,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 0.5),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.25), width: 0.5),
                  ),
                  child:
                      Icon(Icons.layers_rounded, color: statusColor, size: 18),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                          color: statusColor.withValues(alpha: 0.6),
                          blurRadius: 6)
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Text(
                displayName(project),
                style: const TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${running.length}/${containers.length} en ejecución',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    letterSpacing: 0.6,
                    fontFamily: 'monospace'),
              ),
              const Spacer(),
              if (anyRunning) ...[
                _aggMetric('CPU', totalCpu, cyan),
                const SizedBox(height: 6),
                _aggMetric('MEM', totalMem, yellow),
              ] else
                Text(
                  'Detenido',
                  style: TextStyle(
                      color: textDim, fontSize: 10, fontFamily: 'monospace'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _aggMetric(String label, double value, Color color) {
    return Row(children: [
      SizedBox(
        width: 28,
        child: Text(label,
            style: TextStyle(
                color: textDim, fontSize: 9, fontFamily: 'monospace')),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            backgroundColor: border.withValues(alpha: 0.3),
            color: color,
            minHeight: 5,
          ),
        ),
      ),
      const SizedBox(width: 6),
      SizedBox(
        width: 36,
        child: Text(
          '${value.toStringAsFixed(0)}%',
          textAlign: TextAlign.right,
          style: TextStyle(color: color, fontSize: 9, fontFamily: 'monospace'),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Diálogo que muestra los contenedores de un proyecto en una grilla
/// rectangular compacta, con acciones de reinicio y logs por contenedor
/// y combinadas para todo el proyecto.
class _ProjectDialog extends StatefulWidget {
  final String project;
  final List<ContainerMetrics> containers;
  final ApiClient api;
  final void Function(String text, {String type}) onEvent;

  const _ProjectDialog({
    required this.project,
    required this.containers,
    required this.api,
    required this.onEvent,
  });

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  bool _busy = false;

  Future<void> _restartContainer(ContainerMetrics c) async {
    try {
      await widget.api.postJson('/api/containers/${c.id}/restart');
      widget.onEvent('Reiniciado: ${c.name}', type: 'ok');
    } catch (e) {
      widget.onEvent('Error al reiniciar ${c.name}: $e', type: 'error');
    }
  }

  Future<void> _restartProject() async {
    if (_busy) return;
    setState(() => _busy = true);
    for (final c in widget.containers) {
      await _restartContainer(c);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<String> _fetchLogs(ContainerMetrics c) async {
    final res =
        await widget.api.getJson('/api/containers/${c.id}/logs?tail=400');
    return (res as Map)['logs']?.toString() ?? '';
  }

  Future<String> _fetchCombinedLogs() async {
    final buffer = StringBuffer();
    for (final c in widget.containers) {
      buffer.writeln('━━━ ${c.name} ━━━');
      try {
        buffer.writeln(await _fetchLogs(c));
      } catch (e) {
        buffer.writeln('(error al obtener logs: $e)');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  void _viewContainerLogs(ContainerMetrics c) {
    showLogsDialog(
      context,
      title: 'Logs · ${c.name}',
      fetchLogs: () => _fetchLogs(c),
    );
  }

  void _viewCombinedLogs() {
    showLogsDialog(
      context,
      title: 'Logs combinados · ${ProjectCard.displayName(widget.project)}',
      fetchLogs: _fetchCombinedLogs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final containers = widget.containers;
    final running = containers.where((c) => c.status == 'running').toList();
    final statusColor = running.isNotEmpty ? green : textDim;
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border, width: 0.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(children: [
                Icon(Icons.layers_rounded, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ProjectCard.displayName(widget.project)}  ·  ${running.length}/${containers.length} en ejecución',
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Tooltip(
                  message: 'Reiniciar proyecto',
                  child: IconButton(
                    icon: _busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: textSecondary),
                          )
                        : const Icon(Icons.restart_alt_rounded,
                            size: 17, color: textSecondary),
                    onPressed: _busy ? null : _restartProject,
                  ),
                ),
                Tooltip(
                  message: 'Ver logs combinados',
                  child: IconButton(
                    icon: const Icon(Icons.terminal_rounded,
                        size: 17, color: textSecondary),
                    onPressed: _viewCombinedLogs,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
            ),
            const Divider(height: 1, color: border, thickness: 0.5),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.7,
                  ),
                  itemCount: containers.length,
                  itemBuilder: (_, i) {
                    final c = containers[i];
                    return ServiceCard(
                      container: c,
                      onRestart: () => _restartContainer(c),
                      onViewLogs: () => _viewContainerLogs(c),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
