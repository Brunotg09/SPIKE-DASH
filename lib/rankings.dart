// lib/rankings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/usuario_provider.dart';
import 'providers/ranking_provider.dart';
import 'services/firestore_service.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  int _currentTab = 0;
  int _activeFilter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RankingProvider>();
      provider.iniciarStreamRanking();
      final usuario = context.read<UsuarioProvider>().usuario;
      if (usuario != null) {
        provider.carregarAmigos(usuario.uid);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RankingProvider>().refreshStream();
    });
  }

  void _showAdicionarAmigo() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ADICIONAR AMIGO',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Insira o código (UID) do jogador:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Código do amigo',
                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final codigo = controller.text.trim();
              if (codigo.isEmpty) return;
              final usuario = context.read<UsuarioProvider>().usuario;
              if (usuario == null) return;
              final firestore = FirestoreService();
              final success = await firestore.enviarPedidoAmizade(usuario.uid, codigo);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Amigo adicionado!' : 'Código inválido ou já é amigo',
                      style: const TextStyle(fontSize: 14),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
                if (success) {
                  context.read<RankingProvider>().carregarAmigos(usuario.uid);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Adicionar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
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
                      'LIDERANÇA',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (_activeFilter == 2)
                      IconButton(
                        onPressed: _showAdicionarAmigo,
                        icon: const Icon(Icons.person_add, color: AppColors.primary),
                      )
                    else
                      const SizedBox(width: 70),
                  ],
                ),
                const SizedBox(height: 16),

                // ==================== ABAS ====================
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(0, 'GLOBAL'),
                      _buildTabButton(1, 'SEMANAL'),
                      _buildTabButton(2, 'AMIGOS'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==================== PODIO (TOP 3) ====================
                _buildPodio(),
                const SizedBox(height: 20),

                // ==================== LISTA COMPLETA ====================
                Expanded(
                  child: _buildRankingList(),
                ),

                // ==================== POSICAO DO JOGADOR ====================
                _buildMinhaPosicao(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodio() {
    return Consumer2<RankingProvider, UsuarioProvider>(
      builder: (context, rankingProvider, usuarioProvider, child) {
        if (rankingProvider.stream == null) {
          if (_activeFilter == 2 && rankingProvider.uidsAmigos.isEmpty) {
            return const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Adicione amigos para ver o ranking!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            );
          }
          return const SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        return StreamBuilder<QuerySnapshot>(
          stream: rankingProvider.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 160,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              final isEmptyFriends = _activeFilter == 2;
              return SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    isEmptyFriends
                        ? 'Adicione amigos para ver o ranking!'
                        : 'Nenhum jogador no ranking ainda.\nJogue para aparecer aqui!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            if (docs.length < 3) {
              return SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    _activeFilter == 2
                        ? 'Adicione mais amigos para o pódio!'
                        : 'Jogadores insuficientes para pódio.',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPodiumPosition(
                  name: docs[1]['nickname'] ?? '???',
                  score: '${docs[1]['trofeus'] ?? 0} t',
                  avatarColor: AppColors.textMuted,
                  podiumHeight: 50,
                  podiumLabel: 'II',
                  badgeNumber: '2',
                ),
                const SizedBox(width: 12),
                _buildPodiumPosition(
                  name: docs[0]['nickname'] ?? '???',
                  score: '${docs[0]['trofeus'] ?? 0} t',
                  avatarColor: AppColors.accent,
                  podiumHeight: 75,
                  podiumLabel: 'I',
                  badgeNumber: '1',
                  isFirst: true,
                ),
                const SizedBox(width: 12),
                _buildPodiumPosition(
                  name: docs[2]['nickname'] ?? '???',
                  score: '${docs[2]['trofeus'] ?? 0} t',
                  avatarColor: AppColors.warning,
                  podiumHeight: 40,
                  podiumLabel: 'III',
                  badgeNumber: '3',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRankingList() {
    return Consumer2<RankingProvider, UsuarioProvider>(
      builder: (context, rankingProvider, usuarioProvider, child) {
        if (rankingProvider.stream == null) {
          if (_activeFilter == 2 && rankingProvider.uidsAmigos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      color: AppColors.textMuted.withOpacity(0.3), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhum amigo adicionado.\nToque em + para adicionar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.5),
                        fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return StreamBuilder<QuerySnapshot>(
          stream: rankingProvider.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              final isEmptyFriends = _activeFilter == 2;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEmptyFriends ? Icons.people_outline : Icons.emoji_events_outlined,
                      color: AppColors.textMuted.withOpacity(0.3), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      isEmptyFriends
                          ? 'Nenhum amigo encontrado.\nAdicione amigos pelo código!'
                          : 'Ranking vazio.\nJogue para ser o primeiro!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textMuted.withOpacity(0.5),
                          fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;
            final myUid = usuarioProvider.usuario?.uid;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final isMe = docs[index].id == myUid;
                final pos = '#${index + 1}';
                final name = data['nickname'] ?? '???';
                final score = '${data['trofeus'] ?? 0} t';
                final tag = data['titulo'] ?? 'ROOKIE';

                return _buildListRow(
                    pos, name, score, tag, isMe);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMinhaPosicao() {
    return Consumer2<RankingProvider, UsuarioProvider>(
      builder: (context, rankingProvider, usuarioProvider, child) {
        final usuario = usuarioProvider.usuario;
        final stream = rankingProvider.stream;

        if (stream == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.6), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('#--',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(width: 12),
                    Text('${usuario?.nickname ?? 'JOGADOR'} (Tu)',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('${usuario?.trofeus ?? 0} troféus',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            String myPosition = '#--';
            if (snapshot.hasData && usuario != null) {
              final docs = snapshot.data!.docs;
              for (int i = 0; i < docs.length; i++) {
                if (docs[i].id == usuario.uid) {
                  myPosition = '#${i + 1}';
                  break;
                }
              }
            }

            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.6), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(myPosition,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primary, width: 1)),
                        child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.surfaceElevated,
                            child: Icon(Icons.person,
                                size: 12, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 8),
                      Text('${usuario?.nickname ?? 'JOGADOR'} (Tu)',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('${usuario?.trofeus ?? 0} troféus',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _activeFilter == index;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() => _activeFilter = index);
            context.read<RankingProvider>().setFilter(index);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumPosition({
    required String name,
    required String score,
    required Color avatarColor,
    required double podiumHeight,
    required String podiumLabel,
    required String badgeNumber,
    bool isFirst = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: avatarColor, width: isFirst ? 2 : 1),
                boxShadow: isFirst
                    ? [
                        BoxShadow(
                            color: avatarColor.withOpacity(0.3),
                            blurRadius: 12)
                      ]
                    : null,
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.border,
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration:
                  BoxDecoration(color: avatarColor, shape: BoxShape.circle),
              child: Text(badgeNumber,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        Text(score,
            style: TextStyle(
                color: avatarColor,
                fontSize: 11,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Container(
          width: 75,
          height: podiumHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Center(
            child: Text(
              podiumLabel,
              style: TextStyle(
                  color: avatarColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListRow(
      String pos, String name, String score, String tag, bool isMe) {
    final tagColor = isMe ? AppColors.primary : AppColors.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.borderSubtle,
          width: isMe ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(pos,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
              const SizedBox(width: 14),
              const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.border,
                  child: Icon(Icons.person,
                      size: 14, color: Colors.white)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color:
                              isMe ? AppColors.primary : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: AppColors.borderLight)),
                    child: Text(tag,
                        style: TextStyle(
                            color: tagColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ],
          ),
          Text(score,
              style: TextStyle(
                  color: isMe
                      ? AppColors.primary
                      : AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
