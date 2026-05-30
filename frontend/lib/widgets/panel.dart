import 'package:flutter/material.dart';

import '../core/theme.dart';

class Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accentColor;
  final Widget? trailing;

  const Panel({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? blue;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(children: [
              if (icon != null) ...[
                Icon(icon, color: accent, size: 15),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ]),
          ),
          const Divider(height: 0, color: border, thickness: 0.5),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const SummaryChip(
      {super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: textSecondary, fontSize: 10),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Widget statusDot(Color c) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c,
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 5)]));

Widget miniBadge(String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
        borderRadius: BorderRadius.circular(5)),
    child: Text(
      '$label $value',
      style: TextStyle(
        color: color,
        fontSize: 10,
        letterSpacing: 0.4,
      ),
    ),
  );
}

Widget statLabel(String label, String value) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label:',
          style: TextStyle(color: textDim, fontSize: 10)),
      const SizedBox(width: 5),
      Text(value,
          style: TextStyle(color: textSecondary, fontSize: 10)),
    ],
  );
}

Widget tag(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: color.withValues(alpha: 0.08),
      border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
    ),
    child: Text(text,
        style: TextStyle(color: color, fontSize: 9, fontFamily: 'monospace')),
  );
}

Widget metricChip(String label, String value) {
  return Text('$label: $value',
      style: TextStyle(color: textSecondary, fontSize: 10));
}

Widget badge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: color.withValues(alpha: 0.12),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
  );
}

Widget agentStat(String label, String value, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(color: textDim, fontSize: 10, letterSpacing: 0.4)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 18,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold)),
    ],
  );
}

Widget agentMetric(String label, String value, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: textDim, fontSize: 8)),
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold)),
    ],
  );
}

Widget tokenBar(String label, int value, int total, Color color) {
  final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
  return Row(children: [
    Text('$label ',
        style: TextStyle(color: textDim, fontSize: 9, fontFamily: 'monospace')),
    Expanded(
        child: ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: pct,
        backgroundColor: border.withValues(alpha: 0.3),
        color: color,
        minHeight: 5,
      ),
    )),
    const SizedBox(width: 6),
    Text(_fmtToken(value),
        style: TextStyle(color: color, fontSize: 9, fontFamily: 'monospace')),
  ]);
}

String _fmtToken(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

Widget miniBar(double pct, Color color) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: LinearProgressIndicator(
      value: (pct / 100).clamp(0.0, 1.0),
      backgroundColor: border.withValues(alpha: 0.3),
      color: color,
      minHeight: 5,
    ),
  );
}
