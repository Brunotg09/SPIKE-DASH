// lib/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'config/avatars.dart';
import 'providers/auth_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/partida_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<IconData> _avatarIcons = [
    Icons.person,
    Icons.star,
    Icons.local_fire_department,
    Icons.emoji_events,
    Icons.military_tech,
    Icons.workspace_premium,
    Icons.diamond,
  ];

  static const List<String> _avatarLabels = [
    'Padrão',
    'Estrela',
    'Fogo',
    'Troféu',
    ' militar',
    'Premium',
    'Coroa',
  ];

  static const Map<int, int> _avatarNivelRequerido = {
    0: 1,
    1: 3,
    2: 5,
    3: 7,
    4: 10,
    5: 13,
    6: 16,
  };

  static const List<String> _allTitles = [
    'ROOKIE',
    'VETERANO',
    'EXPERT',
    'MESTRE',
    'LENDA',
    'DIVINO',
  ];

  static const Map<String, int> _tituloNivelRequerido = {
    'ROOKIE': 1,
    'VETERANO': 4,
    'EXPERT': 7,
    'MESTRE': 10,
    'LENDA': 13,
    'DIVINO': 16,
  };

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
                              GestureDetector(
                                onTap: () => _showAvatarSelector(context, provider),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppAvatars.getCor(usuario?.avatarId ?? 0), width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundColor: AppColors.surface,
                                    child: Icon(
                                      AppAvatars.getIcon(usuario?.avatarId ?? 0),
                                      color: AppAvatars.getCor(usuario?.avatarId ?? 0),
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit,
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
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              if (usuario?.uid != null) {
                                final codigo = usuario!.uid.substring(0, 5).toUpperCase();
                                Clipboard.setData(ClipboardData(text: codigo));
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Código $codigo copiado! Compartilhe com amigos.',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Código: ${usuario?.uid.substring(0, 5).toUpperCase() ?? '-----'}',
                                    style: TextStyle(
                                      color: AppColors.textMuted.withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.copy, size: 10, color: AppColors.textMuted.withOpacity(0.7)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showTitleSelector(context, provider),
                            child: Container(
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
                                  const Icon(Icons.edit,
                                      color: Colors.black, size: 12),
                                ],
                              ),
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
                                '${usuario?.xp ?? 0} XP',
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
                          const SizedBox(height: 4),
                          Text(
                            '${((usuario?.nivelProgresso ?? 0) * 100).toInt()}% PARA LVL ${(usuario?.nivel ?? 1) + 1}',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
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
                Consumer<UsuarioProvider>(
                  builder: (context, provider, child) {
                    final usuario = provider.usuario;
                    final conquistas = usuario?.conquistasDesbloqueadas ?? [];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAchievementCard(
                          0,
                          'Fast',
                          Icons.bolt,
                          AppColors.conquistaFast,
                          conquistas.contains('fast'),
                          'Precisão > 90%',
                        ),
                        _buildAchievementCard(
                          1,
                          'Combo',
                          Icons.local_fire_department,
                          AppColors.conquistaCombo,
                          conquistas.contains('combo'),
                          'Combo >= 10',
                        ),
                        _buildAchievementCard(
                          2,
                          'Ritmo',
                          Icons.hourglass_top,
                          AppColors.conquistaRitmo,
                          conquistas.contains('ritmo'),
                          '10 partidas',
                        ),
                        _buildAchievementCard(
                          3,
                          'Glória',
                          Icons.emoji_events,
                          AppColors.conquistaGloria,
                          conquistas.contains('gloria'),
                          '5 vitórias',
                        ),
                      ],
                    );
                  },
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

  void _showAvatarSelector(BuildContext context, UsuarioProvider provider) {
    final usuario = provider.usuario;
    if (usuario == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SELECIONAR AVATAR',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nível atual: ${usuario.nivel}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 7,
              itemBuilder: (context, index) {
                final isUnlocked = usuario.avatarsDesbloqueados.contains(index);
                final isSelected = usuario.avatarId == index;
                final nivelRequerido = _avatarNivelRequerido[index] ?? 1;
                return GestureDetector(
                  onTap: isUnlocked
                      ? () {
                          provider.setAvatar(index);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : isUnlocked
                                ? AppColors.borderLight
                                : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppAvatars.getIcon(index),
                          color: isUnlocked
                              ? AppAvatars.getCor(index)
                              : AppColors.textMuted.withOpacity(0.3),
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUnlocked
                              ? AppAvatars.nomes[index]
                              : 'Nv.$nivelRequerido',
                          style: TextStyle(
                            color: isUnlocked
                                ? Colors.white
                                : AppColors.textMuted.withOpacity(0.5),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTitleSelector(BuildContext context, UsuarioProvider provider) {
    final usuario = provider.usuario;
    if (usuario == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SELECIONAR TÍTULO',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nível atual: ${usuario.nivel}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_allTitles.length, (index) {
              final titulo = _allTitles[index];
              final isUnlocked =
                  usuario.titulosDesbloqueados.contains(titulo);
              final isSelected = usuario.titulo == titulo;
              final nivelRequerido = _tituloNivelRequerido[titulo] ?? 1;
              return GestureDetector(
                onTap: isUnlocked
                    ? () {
                        provider.setTitulo(titulo);
                        Navigator.pop(context);
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isUnlocked
                              ? AppColors.borderLight
                              : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isUnlocked
                            ? AppColors.primary
                            : AppColors.textMuted.withOpacity(0.3),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        titulo,
                        style: TextStyle(
                          color: isUnlocked
                              ? Colors.white
                              : AppColors.textMuted.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (!isUnlocked)
                        Text(
                          'Nv.$nivelRequerido',
                          style: TextStyle(
                            color: AppColors.textMuted.withOpacity(0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
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
    int index,
    String title,
    IconData icon,
    Color color,
    bool isUnlocked,
    String requisito,
  ) {
    return GestureDetector(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppColors.surface
              : AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? color : AppColors.border,
            width: isUnlocked ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isUnlocked ? color : AppColors.textMuted.withOpacity(0.3),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isUnlocked ? Colors.white : AppColors.textMuted.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isUnlocked ? 'Desbloqueado' : requisito,
              style: TextStyle(
                color: isUnlocked
                    ? color
                    : AppColors.textMuted.withOpacity(0.4),
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
