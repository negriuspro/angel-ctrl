import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/config.dart';

class AppNav extends StatelessWidget {
  final Map<String, dynamic> hostStats;
  final DashboardMode mode;
  final ValueChanged<DashboardMode> onModeChanged;

  const AppNav({
    super.key,
    required this.hostStats,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 900;
    final hostname   = hostStats['hostname']?.toString() ?? '—';
    final containers = (hostStats['containers_running'] ?? 0) as int;
    final lanIp      = hostStats['lan_ip']?.toString() ?? '—';

    return Container(
      width: compact ? 68 : 220,
      decoration: const BoxDecoration(
        color: surface,
        border: Border(right: BorderSide(color: border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Logo(compact: compact),
          const SizedBox(height: 10),
          _NavItem(
            icon: Icons.dns_rounded,
            label: 'Infraestructura',
            mode: DashboardMode.infrastructure,
            current: mode,
            compact: compact,
            onTap: () => onModeChanged(DashboardMode.infrastructure),
          ),
          _NavItem(
            icon: Icons.psychology_rounded,
            label: 'Sistemas IA',
            mode: DashboardMode.aiSystems,
            current: mode,
            compact: compact,
            onTap: () => onModeChanged(DashboardMode.aiSystems),
          ),
          _NavItem(
            icon: Icons.account_tree_rounded,
            label: 'Agentes',
            mode: DashboardMode.agents,
            current: mode,
            compact: compact,
            onTap: () => onModeChanged(DashboardMode.agents),
          ),
          _NavItem(
            icon: Icons.bolt_rounded,
            label: 'Automatizaciones',
            mode: DashboardMode.automations,
            current: mode,
            compact: compact,
            onTap: () => onModeChanged(DashboardMode.automations),
          ),
          const Spacer(),
          _HostStatus(
            hostname: hostname,
            containers: containers,
            lanIp: lanIp,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final bool compact;
  const _Logo({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
      alignment: compact ? Alignment.center : Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: compact
          ? Icon(
              Icons.hub_rounded,
              color: blue,
              size: 24,
              shadows: [Shadow(color: blue.withValues(alpha: 0.7), blurRadius: 14)],
            )
          : Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      blue.withValues(alpha: 0.25),
                      purple.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: blue.withValues(alpha: 0.35), width: 0.5),
                ),
                child: const Icon(Icons.hub_rounded, color: blue, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANGEL CTRL',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'control center',
                    style: TextStyle(color: textDim, fontSize: 9, letterSpacing: 0.4),
                  ),
                ],
              ),
            ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final DashboardMode mode;
  final DashboardMode current;
  final bool compact;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.mode,
    required this.current,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = mode == current;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          highlightColor: blue.withValues(alpha: 0.06),
          splashColor: blue.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: selected ? blue.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? blue.withValues(alpha: 0.25) : Colors.transparent,
                width: 0.5,
              ),
            ),
            child: compact
                ? Center(
                    child: Icon(
                      icon,
                      color: selected ? blue : textDim,
                      size: 21,
                    ),
                  )
                : Row(children: [
                    Icon(icon, color: selected ? blue : textDim, size: 19),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected ? textPrimary : textSecondary,
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: blue,
                          boxShadow: [
                            BoxShadow(
                              color: blue.withValues(alpha: 0.6),
                              blurRadius: 6,
                            )
                          ],
                        ),
                      ),
                  ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HostStatus extends StatelessWidget {
  final String hostname;
  final int containers;
  final String lanIp;
  final bool compact;

  const _HostStatus({
    required this.hostname,
    required this.containers,
    required this.lanIp,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      child: compact
          ? Center(child: _dot())
          : Row(children: [
              _dot(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hostname.toUpperCase(),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$containers containers · $lanIp',
                      style: TextStyle(color: textDim, fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ]),
    );
  }

  Widget _dot() => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: green,
          boxShadow: [BoxShadow(color: green.withValues(alpha: 0.5), blurRadius: 6)],
        ),
      );
}
