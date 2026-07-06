// lib/menu_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/usuario_provider.dart';
import 'providers/partida_provider.dart';
import 'perfect_timing.dart';
import 'profile.dart';
import 'rankings.dart';
import 'reflex_duel.dart';
import 'stroop_shot.dart';
import 'tap_precision.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _currentTab = 1;
  int _hoveredCardIndex = -1;

  @override
  void initState() {
    super.initState();
    // Carrega dados do cache Hive na inicialização
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioProvider>().recarregarDoCache();
      context.read<PartidaProvider>().carregarHistorico();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarrega do Hive ao voltar para esta tela (ex: após jogar)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioProvider>().recarregarDoCache();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==================== HEADER ====================
                _buildHeader(),
                const SizedBox(height: 20),

                // ==================== GRID DE STATS ====================
                _buildStatsGrid(),
                const SizedBox(height: 20),

                // ==================== LISTA DE MODOS ====================
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildMenuCard(
                          index: 0,
                          category: 'MELHORIA DE REFLEXOS',
                          title: 'TAP PRECISION',
                          description:
                              'Reage rapidamente aos alvos que surgem na tela. Treino solo.',
                          icon: Icons.track_changes,
                          themeColor: AppColors.tapPrecision,
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          index: 1,
                          category: 'MULTIJOGADOR LOCAL',
                          title: 'REFLEX DUEL',
                          description:
                              'Espera pelo verde. Dispara primeiro mas evita falsas partidas!',
                          icon: Icons.bolt,
                          themeColor: AppColors.reflexDuel,
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          index: 2,
                          category: 'DESAFIO DE RITMO',
                          title: 'PERFECT TIMING EVO',
                          description:
                              'Acerte na zona central que se transforma, encolhe e muda de cor!',
                          icon: Icons.timer,
                          themeColor: AppColors.perfectTiming,
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          index: 3,
                          category: 'PRESSAO COGNITIVA',
                          title: 'STROOP SHOT',
                          description:
                              'Novo modo! Decifre o enigma das cores em modo Solo ou 1x1 dividido.',
                          icon: Icons.lens_blur,
                          themeColor: AppColors.stroopShot,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ==================== BARRA DE NAVEGACAO ====================
                _buildNavBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<UsuarioProvider>(
      builder: (context, provider, child) {
        final usuario = provider.usuario;
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surface,
                child: Icon(Icons.sentiment_satisfied_alt,
                    color: AppColors.primary, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        usuario?.nickname ?? 'JOGADOR',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          usuario?.titulo ?? 'ROOKIE',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ID: #${usuario?.uid.substring(0, 5).toUpperCase() ?? '-----'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.border,
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: AppColors.accent, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${usuario?.trofeus ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return Consumer<UsuarioProvider>(
      builder: (context, provider, child) {
        final u = provider.usuario;
        return Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'VITÓRIAS', '${u?.vitorias ?? 0}', Colors.white)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatCard(
                    'TROFÉUS', '${u?.trofeus ?? 0}', AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatCard(
                    'PRECISÃO',
                    '${u?.precisaoMedia.toStringAsFixed(1) ?? "0.0"}%',
                    AppColors.accent)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required int index,
    required String category,
    required String title,
    required String description,
    required IconData icon,
    required Color themeColor,
  }) {
    final isHovered = _hoveredCardIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredCardIndex = index),
      onExit: (_) => setState(() => _hoveredCardIndex = -1),
      child: GestureDetector(
        onTap: () {
          Widget targetScreen;
          switch (index) {
            case 0:
              targetScreen = const TapPrecisionScreen();
              break;
            case 1:
              targetScreen = const ReflexDuelScreen();
              break;
            case 2:
              targetScreen = const PerfectTimingScreen();
              break;
            case 3:
              targetScreen = const StroopShotScreen();
              break;
            default:
              return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(
              color: isHovered ? themeColor : AppColors.border,
              width: isHovered ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: themeColor.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: themeColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 72,
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCustomNavItem(
            index: 0,
            icon: Icons.bar_chart_rounded,
            label: 'RANKINGS',
          ),
          _buildCustomNavItem(
            index: 1,
            icon: Icons.sports_esports_rounded,
            label: 'JOGAR',
            hasGlow: true,
          ),
          _buildCustomNavItem(
            index: 2,
            icon: Icons.person_rounded,
            label: 'PERFIL',
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool hasGlow = false,
  }) {
    final isSelected = _currentTab == index;
    final Color activeColor = AppColors.primary;
    final Color inactiveColor = AppColors.textMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _currentTab = index);
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RankingsScreen()),
            ).then((_) => setState(() => _currentTab = 1));
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ).then((_) => setState(() => _currentTab = 1));
          }
        },
        child: Container(
          width: 90,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: hasGlow && isSelected
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(0.35),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      )
                    : null,
                child: Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
