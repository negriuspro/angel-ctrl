import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/event.dart';
import 'panel.dart';

class EventLog extends StatefulWidget {
  final List<Event> events;
  const EventLog({super.key, required this.events});

  @override
  State<EventLog> createState() => _EventLogState();
}

class _EventLogState extends State<EventLog> {
  final _scrollCtrl = ScrollController();

  @override
  void didUpdateWidget(EventLog old) {
    super.didUpdateWidget(old);
    if (widget.events.isNotEmpty && old.events.length < widget.events.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients && _scrollCtrl.offset < 100) {
          _scrollCtrl.animateTo(0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'REGISTRO DE EVENTOS',
      icon: Icons.terminal_rounded,
      child: SizedBox(
        height: 200,
        child: widget.events.isEmpty
            ? const Center(
                child: Text('Sin eventos',
                    style: TextStyle(color: textDim, fontFamily: 'monospace')))
            : ListView.builder(
                controller: _scrollCtrl,
                itemCount: widget.events.length,
                itemBuilder: (_, i) {
                  final e = widget.events[i];
                  Color c;
                  switch (e.type) {
                    case 'ok':
                      c = green;
                      break;
                    case 'error':
                      c = red;
                      break;
                    case 'warn':
                      c = yellow;
                      break;
                    default:
                      c = textSecondary;
                  }
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('[${_fmtTime(e.time)}]',
                            style: TextStyle(
                                color: textDim,
                                fontSize: 9,
                                fontFamily: 'monospace')),
                        const SizedBox(width: 6),
                        Text(e.text,
                            style: TextStyle(
                                color: c,
                                fontSize: 9,
                                fontFamily: 'monospace')),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _fmtTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }
}
