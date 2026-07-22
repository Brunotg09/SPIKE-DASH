import 'package:flutter/material.dart';

/// Avatares compartilhados entre telas.
class AppAvatars {
  AppAvatars._();

  static const List<IconData> icons = [
    Icons.person,
    Icons.star,
    Icons.local_fire_department,
    Icons.emoji_events,
    Icons.military_tech,
    Icons.workspace_premium,
    Icons.diamond,
  ];

  static const List<Color> cores = [
    Color(0xFF71717A),
    Color(0xFFFFE600),
    Color(0xFFFF5500),
    Color(0xFF00FF66),
    Color(0xFF00FFFF),
    Color(0xFFFF3366),
    Color(0xFFFFE600),
  ];

  static const List<String> nomes = [
    'Padrao',
    'Estrela',
    'Fogo',
    'Trofeu',
    'Premium',
    'Elite',
    'Coroa',
  ];

  static IconData getIcon(int avatarId) {
    if (avatarId < 0 || avatarId >= icons.length) return icons[0];
    return icons[avatarId];
  }

  static Color getCor(int avatarId) {
    if (avatarId < 0 || avatarId >= cores.length) return cores[0];
    return cores[avatarId];
  }
}
