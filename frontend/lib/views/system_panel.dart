import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/panel.dart';

class SystemPanel extends StatelessWidget {
  final Map<String, dynamic> hostStats;
  const SystemPanel({super.key, required this.hostStats});

  @override
  Widget build(BuildContext context) {
    final h = hostStats;
    final cpuPct = (h['cpu_percent'] as num?)?.toDouble() ?? 0;
    final memPct = (h['mem_percent'] as num?)?.toDouble() ?? 0;
    final diskPct = (h['disk_percent'] as num?)?.toDouble() ?? 0;
    final netRx = h['net_rx_bytes'] as int? ?? 0;
    final netTx = h['net_tx_bytes'] as int? ?? 0;
    final netTotal = netRx + netTx;

    return Panel(
      title: 'SISTEMA',
      icon: Icons.monitor_rounded,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _systemBar('CPU', cpuPct, cyan),
            const SizedBox(height: 8),
            _systemBar('RAM', memPct, yellow),
            const SizedBox(height: 8),
            _systemBar('DISCO', diskPct, green),
            const SizedBox(height: 8),
            _systemBar(
                'NET',
                min(100,
                    netTotal > 0 ? ((netTotal % 1073741824) / 1073741824 * 100).roundToDouble() : 0),
                red),
            const SizedBox(height: 10),
            Row(children: [
              _sysStat('UP', h['uptime_seconds'] != null
                  ? '${(h['uptime_seconds'] as int) ~/ 86400}d'
                  : '—'),
              const SizedBox(width: 12),
              _sysStat('CPU', '${h['cpu_count'] ?? '?'} nucleos'),
              const SizedBox(width: 12),
              _sysStat(
                  'RAM',
                  h['mem_total_bytes'] != null
                      ? '${((h['mem_total_bytes'] as int) / 1073741824).toStringAsFixed(0)}G'
                      : '—'),
              const SizedBox(width: 12),
              _sysStat(
                  'DISCO',
                  h['disk_total_bytes'] != null
                      ? '${((h['disk_total_bytes'] as int) / 1073741824).toStringAsFixed(0)}G'
                      : '—'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _systemBar(String label, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold)),
            Text('${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: border.withValues(alpha: 0.3),
            color: color,
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _sysStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: textDim, fontSize: 8, fontFamily: 'monospace')),
        Text(value,
            style: TextStyle(
                color: textSecondary, fontSize: 9, fontFamily: 'monospace')),
      ],
    );
  }
}
