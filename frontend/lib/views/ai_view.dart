import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/panel.dart';

class AiSystemsView extends StatelessWidget {
  final List<dynamic> providers;
  const AiSystemsView({super.key, required this.providers});

  @override
  Widget build(BuildContext context) {
    final configured =
        providers.where((p) => (p as Map)['health'] != 'not_configured').length;
    final online =
        providers.where((p) => (p as Map)['health'] == 'ok').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary chips ──
          Wrap(spacing: 8, runSpacing: 8, children: [
            SummaryChip(label: 'TOTAL', value: '${providers.length}', color: cyan),
            SummaryChip(label: 'ONLINE', value: '$online', color: green),
            SummaryChip(label: 'CONFIG', value: '$configured', color: yellow),
          ]),
          const SizedBox(height: 14),

          // ── Provider cards ──
          ...providers.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProviderDashCard(
                  provider: (p as Map).cast<String, dynamic>()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderDashCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  const _ProviderDashCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final health = provider['health']?.toString() ?? 'unknown';
    final models = (provider['models'] as List?) ?? [];
    final caps = (provider['capabilities'] as List?) ?? [];
    final events = (provider['events'] as List?) ?? [];
    final m = (provider['metrics'] as Map?)?.cast<String, dynamic>() ?? {};

    final tokIn = (m['token_input'] as int?) ?? 0;
    final tokOut = (m['token_output'] as int?) ?? 0;
    final reqs = (m['request_count'] as int?) ?? 0;
    final latency = (m['latency_ms'] as num?)?.toDouble();

    final (statusColor, statusLabel) = switch (health) {
      'ok' => (green, 'ONLINE'),
      'not_configured' => (textDim, 'NO CONFIG'),
      'error' => (red, 'ERROR'),
      _ => (yellow, health.toUpperCase()),
    };

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: health == 'ok'
                      ? [BoxShadow(
                          color: statusColor.withValues(alpha: 0.5),
                          blurRadius: 6)]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider['label']?.toString() ??
                      provider['provider_id']?.toString() ??
                      '—',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold),
                ),
              ),
              badge(statusLabel, statusColor),
            ]),
          ),

          const Divider(color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),

          if (health == 'not_configured')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('API key no configurada',
                      style: TextStyle(
                          color: textDim,
                          fontSize: 11,
                          fontFamily: 'monospace')),
                  const SizedBox(height: 4),
                  Text(
                      'Agrega la key en .env y reinicia el backend.',
                      style: TextStyle(
                          color: textDim,
                          fontSize: 9,
                          fontFamily: 'monospace')),
                ],
              ),
            )
          else ...[
            // ── Metrics ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(children: [
                _col('INPUT', _fmt(tokIn), cyan),
                const SizedBox(width: 28),
                _col('OUTPUT', _fmt(tokOut), yellow),
                const SizedBox(width: 28),
                _col('REQUESTS', '$reqs', green),
                if (latency != null) ...[
                  const SizedBox(width: 28),
                  _col('LATENCY', '${latency.toStringAsFixed(0)}ms', red),
                ],
              ]),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Column(children: [
                Row(children: [
                  Expanded(child: tokenBar('IN', tokIn, tokIn + tokOut, cyan)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Expanded(
                      child: tokenBar('OUT', tokOut, tokIn + tokOut, yellow)),
                ]),
              ]),
            ),

            // ── Models ──
            if (models.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(
                  color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MODELS',
                        style: TextStyle(
                            color: textDim,
                            fontSize: 8,
                            fontFamily: 'monospace',
                            letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: models
                          .take(8)
                          .map((m) => tag(m.toString(), cyan))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],

            // ── Capabilities ──
            if (caps.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: caps
                      .take(4)
                      .map((c) => tag(c.toString(), textSecondary))
                      .toList(),
                ),
              ),
            ],

            // ── Events ──
            if (events.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(
                  color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EVENTS',
                        style: TextStyle(
                            color: textDim,
                            fontSize: 8,
                            fontFamily: 'monospace',
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    ...events.take(3).map((e) {
                      final ev = (e as Map).cast<String, dynamic>();
                      return Text(
                        '› ${ev['type'] ?? 'event'}: ${ev['message'] ?? ''}',
                        style: TextStyle(
                            color: textDim,
                            fontSize: 8,
                            fontFamily: 'monospace'),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _col(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: textDim, fontSize: 8, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold)),
        ],
      );

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
