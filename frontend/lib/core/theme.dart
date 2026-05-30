import 'package:flutter/material.dart';

// ── Backgrounds ──────────────────────────────────────────────────────────────
const Color bg       = Color(0xFF080C15);
const Color surface  = Color(0xFF0E1420);
const Color surface2 = Color(0xFF141C2B);
const Color surface3 = Color(0xFF1A2437);
const Color border   = Color(0xFF1E2D42);

// ── Accents ──────────────────────────────────────────────────────────────────
const Color blue   = Color(0xFF4F8EF7);   // primary
const Color cyan   = Color(0xFF22D3EE);
const Color green  = Color(0xFF34D399);
const Color red    = Color(0xFFF87171);
const Color yellow = Color(0xFFFBBF24);
const Color purple = Color(0xFFA78BFA);
const Color orange = Color(0xFFFB923C);

// ── Text ─────────────────────────────────────────────────────────────────────
const Color textPrimary   = Color(0xFFEEF2FF);
const Color textSecondary = Color(0xFF94A3B8);
const Color textDim       = Color(0xFF4B6078);

ThemeData buildDarkTheme() {
  return ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: bg,
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: border, width: 0.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
  );
}
