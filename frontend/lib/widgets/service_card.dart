import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/container.dart';
import 'sparkline.dart';

class ServiceCard extends StatelessWidget {
  final ContainerMetrics container;
  const ServiceCard({super.key, required this.container});

  String _serviceName(String name) {
    return name
        .replaceAll(RegExp(r'^interfazdocker[-_]'), '')
        .replaceAll(RegExp(r'[-_]1$'), '');
  }

  String _fmtBytes(int bytes) {
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(1)}G';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(0)}M';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)}K';
    return '$bytes';
  }

  String _fmtUptime(int secs) {
    final d = secs ~/ 86400;
    final h = (secs % 86400) ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  IconData _serviceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('nginx') || n.contains('web')) return Icons.language_rounded;
    if (n.contains('redis') || n.contains('cache')) return Icons.memory_rounded;
    if (n.contains('postgres') || n.contains('mysql') || n.contains('db')) {
      return Icons.table_chart_rounded;
    }
    if (n.contains('backend') || n.contains('api') || n.contains('server')) {
      return Icons.api_rounded;
    }
    if (n.contains('worker') || n.contains('celery')) return Icons.settings_rounded;
    return Icons.dns_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final running      = container.status == 'running';
    final statusColor  = running ? green : textDim;
    final name         = _serviceName(container.name);
    final uptime       = running && container.uptimeSeconds > 0
        ? _fmtUptime(container.uptimeSeconds)
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: running ? border : border.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: statusColor.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Icon(_serviceIcon(container.name), color: statusColor, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    running ? 'RUNNING' : container.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (uptime.isNotEmpty)
              Text(
                uptime,
                style: TextStyle(
                    color: textDim, fontSize: 9, fontFamily: 'monospace'),
              ),
          ]),

          // ── Metrics ─────────────────────────────────────────────────────────
          if (running && container.cpuPercent != null) ...[
            const SizedBox(height: 12),
            _metricRow('CPU', container.cpuPercent!, cyan),
            const SizedBox(height: 5),
            _metricRow('MEM', container.memoryPercent ?? 0, yellow),
            const SizedBox(height: 5),
            Row(children: [
              Text('NET',
                  style: TextStyle(
                      color: textDim, fontSize: 9, fontFamily: 'monospace')),
              const SizedBox(width: 6),
              Text(
                '↓ ${_fmtBytes(container.networkRxBytes ?? 0)}',
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                    fontFamily: 'monospace'),
              ),
              const Spacer(),
              Text(
                '↑ ${_fmtBytes(container.networkTxBytes ?? 0)}',
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                    fontFamily: 'monospace'),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 18,
              child: CustomPaint(
                size: const Size(double.infinity, 18),
                painter: SparklinePainter(
                  values: container.cpuHistory,
                  color: cyan,
                  fillColor: cyan.withValues(alpha: 0.08),
                ),
              ),
            ),
          ] else if (!running) ...[
            const SizedBox(height: 8),
            Text(
              container.image.split('/').last,
              style: TextStyle(
                  color: textDim, fontSize: 9, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricRow(String label, double pct, Color color) {
    return Row(children: [
      SizedBox(
        width: 32,
        child: Text(label,
            style: TextStyle(
                color: textDim, fontSize: 9, fontFamily: 'monospace')),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: border.withValues(alpha: 0.3),
            color: color,
            minHeight: 5,
          ),
        ),
      ),
      const SizedBox(width: 6),
      SizedBox(
        width: 32,
        child: Text(
          '${pct.toStringAsFixed(0)}%',
          textAlign: TextAlign.right,
          style: TextStyle(
              color: color, fontSize: 9, fontFamily: 'monospace'),
        ),
      ),
    ]);
  }
}
