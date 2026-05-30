import 'dart:async';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/panel.dart';
import '../widgets/sparkline.dart';

class AgentsView extends StatefulWidget {
  final List<dynamic> providers;
  const AgentsView({super.key, required this.providers});

  @override
  State<AgentsView> createState() => _AgentsViewState();
}

class _AgentsViewState extends State<AgentsView>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _claude;
  Timer? _timer;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fetchClaude();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchClaude());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _fetchClaude() async {
    try {
      final data = await _api.getJson('/api/ai/claude/metrics');
      if (mounted) setState(() => _claude = data as Map<String, dynamic>);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClaudeDashboard(claude: _claude, pulse: _pulse),
          const SizedBox(height: 14),
          if (widget.providers.isNotEmpty) ...[
            _sectionLabel('PROVIDERS'),
            const SizedBox(height: 8),
            _ProvidersGrid(providers: widget.providers),
          ],
        ],
      ),
    );
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

// ─── Claude Dashboard Card ──────────────────────────────────────────────────

class _ClaudeDashboard extends StatelessWidget {
  final Map<String, dynamic>? claude;
  final AnimationController pulse;

  const _ClaudeDashboard({required this.claude, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final hasData = claude?['has_data'] == true;
    final today = (claude?['today'] as Map?)?.cast<String, dynamic>() ?? {};
    final sess = (claude?['session'] as Map?)?.cast<String, dynamic>() ?? {};
    final rawSpark = (claude?['sparkline'] as List?) ?? [];
    final spark = rawSpark.map((v) => (v as num).toDouble()).toList();

    final todayCost = (today['cost'] as num?)?.toDouble() ?? 0;
    final todayMsgs = (today['messages'] as int?) ?? 0;
    final todayTotal = (today['total'] as int?) ?? 0;

    final sessId = sess['id']?.toString() ?? '';
    final sessModel = sess['model']?.toString() ?? '';
    final sessInput = (sess['input'] as int?) ?? 0;
    final sessOutput = (sess['output'] as int?) ?? 0;
    final sessCacheRead = (sess['cache_read'] as int?) ?? 0;
    final sessCost = (sess['cost'] as num?)?.toDouble() ?? 0;
    final sessTotal = (sess['total'] as int?) ?? 0;
    final todayTotalSafe = todayTotal > 0 ? todayTotal : 1;
    final sessPct = ((sessTotal / todayTotalSafe) * 100).clamp(0, 100).round();

    final modelShort = _shortModel(sessModel);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E2D3D), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          _header(hasData),

          // ── Mascot ──
          _mascot(),

          const Divider(color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),

          // ── TODAY ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TODAY',
                    style: TextStyle(
                        color: textDim,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(
                  '\$${todayCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtNum(todayMsgs)} msgs  ·  ${_fmtBig(todayTotal)} tokens',
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),

          // ── SESSION ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('SESSION',
                      style: TextStyle(
                          color: textDim,
                          fontSize: 9,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5)),
                  if (sessId.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      '· ${sessId.length > 8 ? sessId.substring(0, 8) : sessId}',
                      style: TextStyle(
                          color: textDim,
                          fontSize: 9,
                          fontFamily: 'monospace'),
                    ),
                  ],
                  const Spacer(),
                  if (modelShort.isNotEmpty) _modelBadge(modelShort),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _tokenCol('INPUT', sessInput, cyan),
                  const SizedBox(width: 24),
                  _tokenCol('OUTPUT', sessOutput, yellow),
                  const SizedBox(width: 24),
                  _tokenCol('CACHE RD', sessCacheRead, const Color(0xFF8C6EF5)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: sessPct / 100,
                        backgroundColor: border.withValues(alpha: 0.4),
                        color: cyan.withValues(alpha: 0.6),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '\$${sessCost.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  '$sessPct% of today',
                  style: TextStyle(
                      color: textDim, fontSize: 9, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),

          // ── SPARKLINE ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('LAST 30 MIN',
                      style: TextStyle(
                          color: textDim,
                          fontSize: 9,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5)),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (_, __) => Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: green.withValues(alpha: 0.4 + 0.6 * pulse.value),
                        boxShadow: [
                          BoxShadow(
                              color: green.withValues(
                                  alpha: 0.3 * pulse.value),
                              blurRadius: 6)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('LIVE',
                      style: TextStyle(
                          color: green,
                          fontSize: 8,
                          fontFamily: 'monospace',
                          letterSpacing: 1)),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: CustomPaint(
                    painter: SparklinePainter(
                      values: spark.isEmpty ? List.filled(30, 0.0) : spark,
                      color: red,
                      fillColor: red.withValues(alpha: 0.12),
                    ),
                    size: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool live) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(children: [
        AnimatedBuilder(
          animation: pulse,
          builder: (_, __) => Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: live
                  ? red.withValues(alpha: 0.7 + 0.3 * pulse.value)
                  : textDim,
              boxShadow: live
                  ? [BoxShadow(color: red.withValues(alpha: 0.4), blurRadius: 6)]
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('CLAUDE',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const Spacer(),
        Text(
          _timeNow(),
          style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontFamily: 'monospace'),
        ),
      ]),
    );
  }

  Widget _mascot() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Column(children: [
          CustomPaint(
            painter: _ClawdPainter(),
            size: const Size(48, 40),
          ),
          const SizedBox(height: 6),
          Text('clawd · watching your tokens',
              style: TextStyle(
                  color: textDim,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5)),
        ]),
      ),
    );
  }

  Widget _tokenCol(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: textDim, fontSize: 8, fontFamily: 'monospace')),
        const SizedBox(height: 2),
        Text(_fmtBig(value),
            style: TextStyle(
                color: color,
                fontSize: 16,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _modelBadge(String model) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: const Color(0xFF8C6EF5).withValues(alpha: 0.12),
        border: Border.all(
            color: const Color(0xFF8C6EF5).withValues(alpha: 0.35), width: 0.5),
      ),
      child: Text(model,
          style: const TextStyle(
              color: Color(0xFF8C6EF5),
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold)),
    );
  }

  static String _shortModel(String m) {
    if (m.isEmpty) return '';
    final lower = m.toLowerCase();
    if (lower.contains('opus')) {
      final match = RegExp(r'opus[-\s]?(\d+[-\.]?\d*)').firstMatch(lower);
      return match != null ? 'opus-${match.group(1)}' : 'opus';
    }
    if (lower.contains('sonnet')) {
      final match = RegExp(r'sonnet[-\s]?(\d+[-\.]?\d*)').firstMatch(lower);
      return match != null ? 'sonnet-${match.group(1)}' : 'sonnet';
    }
    if (lower.contains('haiku')) return 'haiku';
    return m.length > 12 ? m.substring(0, 12) : m;
  }

  static String _fmtBig(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static String _fmtNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static String _timeNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ─── Clawd Pixel Art ────────────────────────────────────────────────────────

class _ClawdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const grid = [
      '00111100',
      '01111110',
      '11011011',
      '11111111',
      '01111110',
      '00100100',
      '01011010',
      '10000001',
    ];
    final pw = size.width / grid[0].length;
    final ph = size.height / grid.length;
    final paint = Paint()..color = const Color(0xFFE53935);

    for (var r = 0; r < grid.length; r++) {
      for (var c = 0; c < grid[r].length; c++) {
        if (grid[r][c] == '1') {
          canvas.drawRect(
            Rect.fromLTWH(c * pw, r * ph, pw - 1, ph - 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Providers List ──────────────────────────────────────────────────────────

class _ProvidersGrid extends StatelessWidget {
  final List<dynamic> providers;
  const _ProvidersGrid({required this.providers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: providers
          .map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProviderCard(p: p as Map<String, dynamic>),
              ))
          .toList(),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final Map<String, dynamic> p;
  const _ProviderCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final health = p['health']?.toString() ?? 'unknown';
    final m = (p['metrics'] as Map?)?.cast<String, dynamic>() ?? {};
    final models = (p['models'] as List?) ?? [];
    final caps = (p['capabilities'] as List?) ?? [];
    final events = (p['events'] as List?) ?? [];
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

    final bool configured = health != 'not_configured';

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
                      ? [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 6)]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p['label']?.toString() ?? p['provider_id']?.toString() ?? '—',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
              ),
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
                          color: textDim, fontSize: 11, fontFamily: 'monospace')),
                  const SizedBox(height: 4),
                  Text('Agrega la key en el archivo .env y reinicia el backend.',
                      style: TextStyle(
                          color: textDim, fontSize: 9, fontFamily: 'monospace')),
                ],
              ),
            )
          else ...[
            // ── Token stats ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(children: [
                _tokenCol('INPUT', tokIn, cyan),
                const SizedBox(width: 28),
                _tokenCol('OUTPUT', tokOut, yellow),
                const SizedBox(width: 28),
                _tokenCol('REQUESTS', reqs, green),
                if (latency != null) ...[
                  const SizedBox(width: 28),
                  _tokenColStr('LATENCY', '${latency.toStringAsFixed(0)}ms', red),
                ],
              ]),
            ),

            const SizedBox(height: 10),

            // ── Token bars ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Column(children: [
                Row(children: [
                  Expanded(child: tokenBar('IN', tokIn, tokIn + tokOut, cyan)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Expanded(child: tokenBar('OUT', tokOut, tokIn + tokOut, yellow)),
                ]),
              ]),
            ),

            // ── Models ──
            if (models.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),
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
                      children: models.take(6).map((m) => tag(m.toString(), cyan)).toList(),
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
                  children: caps.take(4).map((c) => tag(c.toString(), textSecondary)).toList(),
                ),
              ),
            ],

            // ── Events ──
            if (events.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(color: Color(0xFF1E2D3D), height: 1, thickness: 0.5),
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
                            color: textDim, fontSize: 8, fontFamily: 'monospace'),
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

  Widget _tokenCol(String label, int value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: textDim, fontSize: 8, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(_fmtBig(value),
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold)),
        ],
      );

  Widget _tokenColStr(String label, String value, Color color) => Column(
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

  static String _fmtBig(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
