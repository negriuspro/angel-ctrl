import 'package:flutter/material.dart';

import '../core/theme.dart';

class PlaceholderView extends StatelessWidget {
  final String label;
  const PlaceholderView({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: blue.withValues(alpha: 0.2), width: 0.5),
              ),
              child: const Icon(Icons.bolt_rounded, color: blue, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Módulo en preparación',
              style: TextStyle(color: textDim, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  const ErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: red.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: red.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: red, size: 28),
            const SizedBox(height: 10),
            Text(
              'Error de conexión',
              style: TextStyle(color: red, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(color: textSecondary, fontSize: 10, fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
