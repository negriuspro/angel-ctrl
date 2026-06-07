import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

/// Muestra logs de uno o varios contenedores en un dialog con scroll,
/// botón de refrescar y botón de copiar al portapapeles.
Future<void> showLogsDialog(
  BuildContext context, {
  required String title,
  required Future<String> Function() fetchLogs,
}) {
  return showDialog(
    context: context,
    builder: (_) => _LogsDialog(title: title, fetchLogs: fetchLogs),
  );
}

class _LogsDialog extends StatefulWidget {
  final String title;
  final Future<String> Function() fetchLogs;
  const _LogsDialog({required this.title, required this.fetchLogs});

  @override
  State<_LogsDialog> createState() => _LogsDialogState();
}

class _LogsDialogState extends State<_LogsDialog> {
  String _logs = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final logs = await widget.fetchLogs();
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _logs));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copiados al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border, width: 0.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(children: [
                Icon(Icons.terminal_rounded, color: cyan, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar logs',
                  icon: const Icon(Icons.copy_rounded,
                      size: 16, color: textSecondary),
                  onPressed: _logs.isEmpty ? null : _copy,
                ),
                IconButton(
                  tooltip: 'Refrescar',
                  icon: const Icon(Icons.refresh_rounded,
                      size: 16, color: textSecondary),
                  onPressed: _loading ? null : _refresh,
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
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: blue));
    }
    if (_error != null) {
      return Center(
        child: Text('Error: $_error',
            style: const TextStyle(
                color: red, fontFamily: 'monospace', fontSize: 12)),
      );
    }
    if (_logs.trim().isEmpty) {
      return const Center(
        child: Text('Sin logs disponibles',
            style: TextStyle(
                color: textDim, fontFamily: 'monospace', fontSize: 12)),
      );
    }
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: SelectableText(
          _logs,
          style: const TextStyle(
              color: textSecondary,
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.4),
        ),
      ),
    );
  }
}
