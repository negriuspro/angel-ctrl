import 'dart:async';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/panel.dart';

class AgentsView extends StatefulWidget {
  final List<dynamic> providers;
  const AgentsView({super.key, required this.providers});

  @override
  State<AgentsView> createState() => _AgentsViewState();
}

class _AgentsViewState extends State<AgentsView> {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _claude;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchClaude();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchClaude());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchClaude() async {
    try {
      final data = await _api.getJson('/api/ai/claude/metrics');
      if (mounted) setState(() => _claude = data as Map<String, dynamic>);
    } catch (_) {}
  }

  /// Codex no está activo como agente en este dashboard.
  List<dynamic> get _gridProviders => widget.providers
      .where((p) => (p as Map)['provider_id']?.toString() != 'codex')
      .toList();

  @override
  Widget build(BuildContext context) {
    final gridProviders = _gridProviders;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PROVIDERS'),
          const SizedBox(height: 8),
          _providersSummary(gridProviders),
          const SizedBox(height: 12),
          _ProvidersGrid(providers: gridProviders, claude: _claude),
        ],
      ),
    );
  }

  Widget _providersSummary(List<dynamic> providers) {
    final configured =
        providers.where((p) => (p as Map)['health'] != 'not_configured').length;
    final online = providers.where((p) => (p as Map)['health'] == 'ok').length;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      SummaryChip(label: 'TOTAL', value: '${providers.length}', color: cyan),
      SummaryChip(label: 'ONLINE', value: '$online', color: green),
      SummaryChip(label: 'CONFIG', value: '$configured', color: yellow),
    ]);
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
            color: textDim,
            fontSize: 9,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5),
      );
}

// ─── Providers Grid ──────────────────────────────────────────────────────────

class _ProvidersGrid extends StatelessWidget {
  final List<dynamic> providers;
  final Map<String, dynamic>? claude;
  const _ProvidersGrid({required this.providers, required this.claude});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const minCardWidth = 360.0;
      const spacing = 12.0;
      final columns =
          (constraints.maxWidth / (minCardWidth + spacing)).floor().clamp(1, 3);
      final cardWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: providers.map((p) {
          final pm = (p as Map).cast<String, dynamic>();
          final isClaude = pm['provider_id']?.toString() == 'claude';
          return SizedBox(
            width: cardWidth,
            child: _ProviderCard(p: pm, claudeExtra: isClaude ? claude : null),
          );
        }).toList(),
      );
    });
  }
}

/// Tarjeta de proveedor estilo "mini dashboard": cifras grandes, jerarquía
/// visual clara y solo datos reales que expone el backend (sin información
/// técnica cruda). Cuando el proveedor es Claude, complementa las métricas
/// genéricas con los datos reales de /api/ai/claude/metrics (costo de hoy,
/// tokens de cache).
class _ProviderCard extends StatelessWidget {
  final Map<String, dynamic> p;
  final Map<String, dynamic>? claudeExtra;
  const _ProviderCard({required this.p, this.claudeExtra});

  /// Logo real (asset/logos/) y color de acento de cada proveedor.
  static (String, Color) _visual(String providerId) => switch (providerId) {
        'claude' => ('asset/logos/claude.png', Color(0xFFD9774F)),
        'gemini' => ('asset/logos/geminis.jpeg', Color(0xFF4285F4)),
        'openrouter' => ('asset/logos/openrouter.jpeg', Color(0xFF94A3B8)),
        'groq' => ('asset/logos/groq.png', Color(0xFFF0563A)),
        'cerebras' => ('asset/logos/cerebras.png', Color(0xFFE8531D)),
        'sambanova' => ('asset/logos/sambanova.webp', Color(0xFF6D4AAE)),
        _ => ('', textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    final providerId = p['provider_id']?.toString() ?? '';
    final label = p['label']?.toString() ?? providerId;
    final health = p['health']?.toString() ?? 'unknown';
    final m = (p['metrics'] as Map?)?.cast<String, dynamic>() ?? {};
    final models = (p['models'] as List?) ?? [];

    final bool isClaude = providerId == 'claude';
    final bool isOpenRouter = providerId == 'openrouter';
    final claudeToday =
        (claudeExtra?['today'] as Map?)?.cast<String, dynamic>();
    final claudeSession =
        (claudeExtra?['session'] as Map?)?.cast<String, dynamic>();

    // El polling dedicado (claudeExtra) puede no haber resuelto aún o fallar;
    // se usa metrics del backend (m) como respaldo para no mostrar "—" vacíos.
    final todayCost = (claudeToday?['cost'] as num?)?.toDouble() ??
        (m['cost_today'] as num?)?.toDouble();
    // OpenRouter no reporta gasto "de hoy" sino consumo acumulado real vía
    // /v1/credits — se muestra como cifra principal en lugar de "Today Cost".
    final costTotal = (m['cost_total'] as num?)?.toDouble();
    final creditsLeft = (m['credits_remaining'] as num?)?.toDouble();
    // null = el proveedor no expone uso real (no hardcodeamos "0", que se
    // vería como consumo real); solo Claude (sesiones locales) lo reporta hoy.
    final tokIn =
        (claudeSession?['input'] as int?) ?? (m['token_input'] as int?);
    final tokOut =
        (claudeSession?['output'] as int?) ?? (m['token_output'] as int?);
    final cacheTokens =
        (claudeSession?['cache_read'] as int?) ?? (m['cache_read'] as int?);
    final latency = (m['latency_ms'] as num?)?.toDouble();
    final msgsToday =
        (claudeToday?['messages'] as int?) ?? (m['request_count'] as int?);

    final (_, accent) = _visual(providerId);
    final (statusColor, statusLabel) = switch (health) {
      'ok' => (green, 'ONLINE'),
      'not_configured' => (textDim, 'OFFLINE'),
      'error' => (red, 'ERROR'),
      _ => (yellow, health.toUpperCase()),
    };
    final bool configured = health != 'not_configured';

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(children: [
              _logo(providerId),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              badge(statusLabel, statusColor),
            ]),
          ),

          const Divider(color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),

          if (!configured)
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
                      'Agrega la key en el archivo .env y reinicia el backend.',
                      style: TextStyle(
                          color: textDim,
                          fontSize: 9,
                          fontFamily: 'monospace')),
                ],
              ),
            )
          else ...[
            // ── Cifra destacada: costo de hoy ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isOpenRouter ? 'TOTAL USAGE' : 'TODAY COST',
                      style: TextStyle(
                          color: textDim,
                          fontSize: 9,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(
                    () {
                      final value = isOpenRouter ? costTotal : todayCost;
                      return value != null
                          ? '\$${value.toStringAsFixed(2)}'
                          : '—';
                    }(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOpenRouter && creditsLeft != null
                        ? 'crédito restante: \$${creditsLeft.toStringAsFixed(2)}'
                        : (tokIn != null && tokOut != null
                            ? '${_fmtBig(tokIn + tokOut)} tokens totales'
                            : 'uso no rastreado'),
                    style: TextStyle(
                        color: textSecondary,
                        fontSize: 10,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Grilla 2x2: input / output / cache / latencia ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: _metricTile(
                          'INPUT', tokIn != null ? _fmtBig(tokIn) : '—', cyan)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _metricTile('OUTPUT',
                          tokOut != null ? _fmtBig(tokOut) : '—', yellow)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _metricTile(
                          'CACHE',
                          cacheTokens != null ? _fmtBig(cacheTokens) : '—',
                          const Color(0xFF8C6EF5))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: isClaude
                          // Claude corre vía plan Pro (sesiones locales), no
                          // hay latencia de API que medir; se muestra en su
                          // lugar la actividad real del día.
                          ? _metricTile('MSGS TODAY',
                              msgsToday != null ? _fmtBig(msgsToday) : '—', red)
                          : _metricTile(
                              'LATENCY',
                              latency != null
                                  ? '${latency.toStringAsFixed(0)}ms'
                                  : '—',
                              red)),
                ]),
              ]),
            ),

            // ── Acceso a la lista completa de modelos ──
            if (models.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        _showModelsSheet(context, label, models, accent),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                            color: accent.withValues(alpha: 0.3), width: 0.5),
                      ),
                    ),
                    icon: const Icon(Icons.view_list_rounded, size: 14),
                    label: Text(
                      'VIEW MODELS · ${models.length}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  /// Insignia con el logo real del proveedor de IA.
  Widget _logo(String providerId) {
    final (asset, color) = _visual(providerId);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: asset.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset(asset, fit: BoxFit.contain),
            )
          : Icon(Icons.smart_toy_rounded, color: color, size: 15),
    );
  }

  /// Tile rectangular con borde para una métrica individual.
  Widget _metricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: textDim,
                  fontSize: 8,
                  fontFamily: 'monospace',
                  letterSpacing: 0.8)),
        ],
      ),
    );
  }

  /// Bottom sheet con la lista completa de modelos, mostrando solo el
  /// nombre amigable (nunca el objeto JSON crudo).
  void _showModelsSheet(
      BuildContext context, String label, List<dynamic> models, Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(children: [
                Expanded(
                  child: Text(
                    '$label  ·  ${models.length} modelos',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
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
            const Divider(color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: models.length,
                separatorBuilder: (_, __) => const Divider(
                    color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),
                itemBuilder: (_, i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Icon(Icons.psychology_alt_rounded, size: 14, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _modelName(models[i]),
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extrae un nombre amigable de un modelo, sin importar si el backend
  /// lo entrega como string o como objeto {id, name}.
  static String _modelName(dynamic model) {
    if (model is Map) {
      final name = model['name'] ?? model['id'];
      return name?.toString() ?? '—';
    }
    return model.toString();
  }

  static String _fmtBig(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
