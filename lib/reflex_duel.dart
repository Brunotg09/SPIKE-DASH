// lib/reflex_duel_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/partida.dart';
import 'models/usuario.dart';
import 'providers/partida_provider.dart';
import 'providers/usuario_provider.dart';
import 'services/hive_service.dart';
import 'services/firestore_service.dart';

class ReflexDuelScreen extends StatefulWidget {
  const ReflexDuelScreen({super.key});

  @override
  State<ReflexDuelScreen> createState() => _ReflexDuelScreenState();
}

enum DuelState {
  idle,
  countdown,
  waiting,
  fire,
  penalty,
  roundOver,
  gameOver,
}

class _ReflexDuelScreenState extends State<ReflexDuelScreen> {
  DuelState _gameState = DuelState.idle;

  int _p1Score = 0;
  int _p2Score = 0;

  String _statusText = "PREPAREM-SE";
  String _subStatusText = "O primeiro a fazer 3 pontos vence";
  String _countdownText = "";

  Timer? _stateTimer;
  final Stopwatch _reactionStopwatch = Stopwatch();
  final Random _random = Random();

  int _lastReactionTime = 0;
  int _matchWinner = 0;
  bool _saved = false;

  @override
  void dispose() {
    _stateTimer?.cancel();
    _reactionStopwatch.stop();
    _salvarPartida();
    super.dispose();
  }

  void _salvarPartida() {
    if (_matchWinner == 0 || _saved) return;
    _saved = true;
    final pontuacao = _matchWinner == 1 ? _p1Score * 50 : _p2Score * 50;
    final partida = Partida(
      modoJogo: 'reflex_duel',
      pontuacao: _matchWinner == 1 ? _p1Score : _p2Score,
      precisao: 100.0,
      comboMaximo: 0,
    );

    try {
      context.read<PartidaProvider>().registrarPartida(partida);
      context.read<UsuarioProvider>().adicionarTrofeus(pontuacao);
      context.read<UsuarioProvider>().adicionarVitoria();
      context.read<UsuarioProvider>().atualizarPrecisao(100.0);
      debugPrint('[ReflexDuel] Salvo via Provider OK');
      return;
    } catch (e) {
      debugPrint('[ReflexDuel] Provider falhou ($e), salvando via services...');
    }

    _salvarViaServices(partida, pontuacao);
  }

  void _salvarViaServices(Partida partida, int trofeus) async {
    try {
      final hive = HiveService();
      final firestore = FirestoreService();
      final uid = hive.cachedUid;
      if (uid == null) return;

      final novosTrofeus = hive.cachedTrofeus + trofeus;
      final novasVitorias = hive.cachedVitorias + 1;
      final novaPrecisao = (hive.cachedPrecisaoMedia + 100.0) / 2;
      await hive.salvarCachePerfil(
        uid: uid,
        nickname: hive.cachedNickname ?? 'JOGADOR',
        titulo: hive.cachedTitulo ?? 'ROOKIE',
        nivel: hive.cachedNivel ?? 1,
        trofeus: novosTrofeus,
        vitorias: novasVitorias,
        precisaoMedia: novaPrecisao,
      );

      await firestore.atualizarRanking(Usuario(
        uid: uid,
        nickname: hive.cachedNickname ?? 'JOGADOR',
        email: '',
        titulo: hive.cachedTitulo ?? 'ROOKIE',
        nivel: hive.cachedNivel ?? 1,
        trofeus: novosTrofeus,
        vitorias: novasVitorias,
        precisaoMedia: novaPrecisao,
      ));

      await firestore.salvarPartida(uid, partida);

      debugPrint('[ReflexDuel] Salvo via services OK: trofeus=$novosTrofeus, vitorias=$novasVitorias');
    } catch (e) {
      debugPrint('[ReflexDuel] ERRO services: $e');
    }
  }

  void _startNewMatch() {
    setState(() {
      _p1Score = 0;
      _p2Score = 0;
      _matchWinner = 0;
      _saved = false;
    });
    _startNextRound();
  }

  void _startNextRound() {
    _stateTimer?.cancel();
    _reactionStopwatch.stop();
    _reactionStopwatch.reset();

    setState(() {
      _gameState = DuelState.countdown;
      _statusText = "PREPAREM-SE";
      _subStatusText = "Olhos na tela...";
    });

    int count = 3;
    setState(() => _countdownText = "$count");

    _stateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      count--;
      if (count > 0) {
        setState(() => _countdownText = "$count");
      } else {
        timer.cancel();
        _enterWaitingState();
      }
    });
  }

  void _enterWaitingState() {
    setState(() {
      _gameState = DuelState.waiting;
      _countdownText = "";
      _statusText = "AGUARDEM...";
      _subStatusText = "";
    });

    int randomDelayMs = 1500 + _random.nextInt(3501);
    _stateTimer = Timer(Duration(milliseconds: randomDelayMs), () {
      _triggerFireSignal();
    });
  }

  void _triggerFireSignal() {
    setState(() {
      _gameState = DuelState.fire;
      _statusText = "FOGO!";
      _subStatusText = "";
    });
    _reactionStopwatch.start();
  }

  void _handleShoot(int player) {
    if (_gameState == DuelState.waiting) {
      _stateTimer?.cancel();
      int opponent = (player == 1) ? 2 : 1;
      _applyRoundWin(opponent, isPenalty: true);
    } else if (_gameState == DuelState.fire) {
      _reactionStopwatch.stop();
      _lastReactionTime = _reactionStopwatch.elapsedMilliseconds;
      _applyRoundWin(player, isPenalty: false);
    }
  }

  void _applyRoundWin(int winner, {required bool isPenalty}) {
    setState(() {
      if (winner == 1) _p1Score++;
      if (winner == 2) _p2Score++;

      if (isPenalty) {
        _statusText = "QUEIMOU A LARGADA!";
        _subStatusText =
            "Jogador $winner ganhou o ponto por penalidade do rival";
      } else {
        _statusText = "JOGADOR $winner ATIROU!";
        _subStatusText = "Tempo de reação: ${_lastReactionTime}ms";
      }

      if (_p1Score >= 3) {
        _gameState = DuelState.gameOver;
        _matchWinner = 1;
      } else if (_p2Score >= 3) {
        _gameState = DuelState.gameOver;
        _matchWinner = 2;
      } else {
        _gameState = DuelState.roundOver;
      }
    });

    if (_gameState == DuelState.gameOver) {
      _salvarPartida();
    }
  }

  void _resetScreen() {
    _stateTimer?.cancel();
    _reactionStopwatch.stop();
    setState(() {
      _gameState = DuelState.idle;
      _p1Score = 0;
      _p2Score = 0;
      _matchWinner = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color arenaBgColor = const Color(0xFF050505);
    if (_gameState == DuelState.waiting)
      arenaBgColor = const Color(0xFF0B0805);
    if (_gameState == DuelState.fire)
      arenaBgColor = const Color(0xFF003311);
    if (_gameState == DuelState.penalty)
      arenaBgColor = const Color(0xFF330000);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Conteúdo principal do jogo
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: _buildPlayerZone(
                      playerId: 2,
                      score: _p2Score,
                      isActive: _gameState == DuelState.waiting ||
                          _gameState == DuelState.fire,
                    ),
                  ),
                ),
                Container(
                  height: 180,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: arenaBgColor,
                    border: Border.all(color: const Color(0xFF18181B)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.02,
                          child: GridPaper(
                            color: _gameState == DuelState.fire
                                ? const Color(0xFF00FF66)
                                : const Color(0xFFFF0550),
                            interval: 25,
                            subdivisions: 1,
                          ),
                        ),
                      ),
                      if (_gameState != DuelState.idle &&
                          _gameState != DuelState.gameOver)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_gameState == DuelState.countdown)
                                Text(
                                  _countdownText,
                                  style: const TextStyle(
                                    color: Color(0xFFFFFF00),
                                    fontSize: 48,
                                    fontFamily: 'Orbitron',
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              else ...[
                                Text(
                                  _statusText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _gameState == DuelState.fire
                                        ? const Color(0xFF00FF66)
                                        : _gameState == DuelState.waiting
                                            ? const Color(0xFFFFCC00)
                                            : Colors.white,
                                    fontSize: 18,
                                    fontFamily: 'Orbitron',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                if (_subStatusText.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _subStatusText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFA1A1AA),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                              if (_gameState == DuelState.roundOver) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: _startNextRound,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF18181B),
                                      side: const BorderSide(
                                          color: Color(0xFF27272A)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                    ),
                                    child: const Text(
                                      'PRÓXIMO ROUND',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontFamily: 'Orbitron',
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildPlayerZone(
                    playerId: 1,
                    score: _p1Score,
                    isActive: _gameState == DuelState.waiting ||
                        _gameState == DuelState.fire,
                  ),
                ),
              ],
            ),
          ),

          // OVERLAY: idle / gameOver (por cima de tudo)
          if (_gameState == DuelState.idle ||
              _gameState == DuelState.gameOver)
            Container(
              color: Colors.black.withOpacity(0.95),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _resetScreen();
                            Navigator.pop(context);
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chevron_left,
                                  color: Color(0xFF71717A), size: 16),
                              Text('Sair',
                                  style: TextStyle(
                                      color: Color(0xFF71717A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Icon(
                          _gameState == DuelState.gameOver
                              ? Icons.emoji_events
                              : Icons.bolt,
                          color: const Color(0xFFFFCC00),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _gameState == DuelState.gameOver
                              ? "DUELO CONCLUÍDO!"
                              : "REFLEX DUEL",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_gameState == DuelState.gameOver) ...[
                          Text(
                            "JOGADOR $_matchWinner É O CAMPEÃO!",
                            style: const TextStyle(
                                color: Color(0xFFFFCC00),
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Placar: $_p1Score x $_p2Score",
                            style: const TextStyle(
                                color: Color(0xFFA1A1AA), fontSize: 13),
                          ),
                        ] else ...[
                          Text(
                            "Dispute localmente em tela dividida.\nO primeiro a reagir após o sinal ganha!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                                height: 1.5),
                          ),
                        ],
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _startNewMatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5500),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                          ),
                          child: Text(
                            _gameState == DuelState.gameOver
                                ? "JOGAR NOVAMENTE"
                                : "COMEÇAR DUELO",
                            style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerZone(
      {required int playerId, required int score, required bool isActive}) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (playerId == 1)
                GestureDetector(
                  onTap: () {
                    _resetScreen();
                    Navigator.pop(context);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.chevron_left,
                          color: Color(0xFF71717A), size: 16),
                      Text('Sair',
                          style: TextStyle(
                              color: Color(0xFF71717A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else
                const SizedBox(width: 40),
              Row(
                children: List.generate(3, (index) {
                  bool isFilled = score > index;
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? (playerId == 1
                              ? const Color(0xFFFF3366)
                              : const Color(0xFF3366FF))
                          : const Color(0xFF18181B),
                      border: Border.all(
                        color: isFilled
                            ? Colors.transparent
                            : const Color(0xFF27272A),
                      ),
                    ),
                  );
                }),
              ),
              Text(
                'JOGADOR 0$playerId',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => _handleShoot(playerId),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _gameState == DuelState.fire
                        ? (playerId == 1
                            ? const Color(0xFFFF3366)
                            : const Color(0xFF3366FF))
                        : const Color(0xFF18181B),
                    width: _gameState == DuelState.fire ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.ads_click,
                        size: 36,
                        color: _gameState == DuelState.fire
                            ? (playerId == 1
                                ? const Color(0xFFFF3366)
                                : const Color(0xFF3366FF))
                            : const Color(0xFF27272A),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _gameState == DuelState.fire
                            ? "ATIRE AGORA!"
                            : "ÁREA DE DISPARO",
                        style: TextStyle(
                          color: _gameState == DuelState.fire
                              ? Colors.white
                              : const Color(0xFF3F3F46),
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
