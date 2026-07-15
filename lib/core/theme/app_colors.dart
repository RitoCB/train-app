import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Fondos
  static const background   = Color(0xFF0D0F14);
  static const surface      = Color(0xFF111318);
  static const surfaceHigh  = Color(0xFF1A1D24);

  // Bordes
  static const border       = Color(0x0FFFFFFF); // 6% white
  static const borderStrong = Color(0x1AFFFFFF); // 10% white

  // Texto
  static const textPrimary   = Color(0xFFE8EAF0);
  static const textSecondary = Color(0x73E8EAF0); // 45%
  static const textMuted     = Color(0x40E8EAF0); // 25%

  // Acento principal: verde
  static const green        = Color(0xFF4ADE80);
  static const greenDim     = Color(0x1F4ADE80); // 12%
  static const greenBorder  = Color(0x404ADE80); // 25%

  // Deportes
  static const blue         = Color(0xFF38BDF8); // Resistencia
  static const blueDim      = Color(0x1F38BDF8);
  static const purple       = Color(0xFFA78BFA); // Artes marciales
  static const purpleDim    = Color(0x1FA78BFA);
  static const amber        = Color(0xFFFBBF24); // Advertencias / peso
  static const amberDim     = Color(0x1FFBBF24);
  static const red          = Color(0xFFF87171); // Peligro / pérdida
  static const redDim       = Color(0x1FF87171);
}
