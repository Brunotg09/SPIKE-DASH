// lib/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/partida_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentTab = 2;
  int _selectedAchievement = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartidaProvider>().carregarHistorico();
      context.read<UsuarioProvider>().recarregarDoCache();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartidaProvider>().carregarHistorico();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 14, color: Colors.white),
                      label: const Text(
                        'Voltar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                    const Text(
                      'PERFIL',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 70),
                  ],
                ),
                const SizedBox(height: 16),

                // ==================== CARD DO JOGADOR ====================
                Consumer<UsuarioProvider>(
                  builder: (context, provider, child) {
                    final usuario = provider.usuario;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.borderLight, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.secondary, width: 2),
                                ),
                                child: const CircleAvatar(
                                  radius: 32,
                                  backgroundColor: AppColors.surface,
                                  child: Icon(Icons.person,
                                      color: AppColors.secondary, size: 36),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.refresh,
                                    color: Colors.black, size: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            usuario?.nickname ?? 'JOGADOR',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'TITULO: ${usuario?.titulo ?? 'ROOKIE'}',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.bolt,
                                    color: Colors.black, size: 12),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'NÍVEL ${usuario?.nivel ?? 1} (${usuario?.nivelNome ?? 'ROOKIE'})',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${((usuario?.nivelProgresso ?? 0) * 100).toInt()}% PARA LVL ${(usuario?.nivel ?? 1) + 1}',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: usuario?.nivelProgresso ?? 0.0,
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.secondary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ==================== CONQUISTAS ====================
                const Text(
                  'CONQUISTAS',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAchievementCard(
                        0, 'Fast', Icons.bolt, AppColors.conquistaFast),
                    _buildAchievementCard(1, 'Combo',
                        Icons.local_fire_department, AppColors.conquistaCombo),
                    _buildAchievementCard(2, 'Ritmo', Icons.hourglass_top,
                        AppColors.conquistaRitmo),
                    _buildAchievementCard(3, 'Glória', Icons.emoji_events,
                        AppColors.conquistaGloria),
                  ],
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Selecione uma conquista para equipar ou ver requisitos.',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),

                // ==================== HISTORICO RECENTE ====================
                const Text(
                  'HISTÓRICO RECENTE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Consumer<PartidaProvider>(
                    builder: (context, provider, child) {
                      final historico = provider.historico;
                      if (historico.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhuma partida registrada ainda.',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        );
                      }
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: historico.length.clamp(0, 5),
                        itemBuilder: (context, index) {
                          final partida = historico[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildHistoryCard(
                              _formatarModo(partida.modoJogo),
                              _formatarTempo(partida.dataPartida),
                              '+${partida.pontuacao} TR',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // ==================== BOTAO TERMINAR SESSAO ====================
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: TextButton(
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF222222)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'TERMINAR SESSÃO',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.logout, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatarModo(String modo) {
    switch (modo) {
      case 'tap_precision':
        return 'Tap Precision (Solo)';
      case 'reflex_duel':
        return 'Reflex Duel (Duelo)';
      case 'perfect_timing':
        return 'Perfect Timing (Solo)';
      case 'stroop_shot':
        return 'Stroop Shot (Solo)';
      default:
        return modo;
    }
  }

  String _formatarTempo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inHours < 1) return 'Há ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Há ${diff.inHours} h';
    return 'Há ${diff.inDays} d';
  }

  Widget _buildAchievementCard(
      int index, String title, IconData icon, Color color) {
    final isSelected = _selectedAchievement == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedAchievement = index),
      child: Container(
        width: 85,
        height: 75,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(String title, String time, String points) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: AppColors.primary, size: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(time,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            points,
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
