// lib/perfect_timing_screen.dart
import 'dart:async';
import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/partida.dart';
import 'models/usuario.dart';
import 'providers/partida_provider.dart';
import 'providers/usuario_provider.dart';
import 'services/hive_service.dart';
import 'services/firestore_service.dart';

class PerfectTimingScreen extends StatefulWidget {
  const PerfectTimingScreen({super.key});

  @override
  State<PerfectTimingScreen> createState() => _PerfectTimingScreenState();
}

enum GameState { idle, playing, gameOver }

class _PerfectTimingScreenState extends State<PerfectTimingScreen>
    with SingleTickerProviderStateMixin {
  GameState _gameState = GameState.idle;

  // Pointer
  double _pointerPos = 0.5;
  bool _movingRight = true;
  double _pointerSpeed = 0.008;

  // Zones — percentuais da largura total (0.0 a 1.0)
  double _perfectZoneHalf = 0.06; // metade da zona perfeita
  double _goodZoneHalf = 0.14;
  double _okZoneHalf = 0.24;

  // Pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Game
  Timer? _gameTimer;
  Timer? _moveTimer;
  int _timeLeft = 30;
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _totalHits = 0;
  int _perfectHits = 0;
  int _level = 1;

  // Feedback
  String _feedbackText = '';
  Color _feedbackColor = Colors.white;
  bool _showFeedback = false;
  double _feedbackScale = 1.0;

  // Flash effect
  Color _barFlashColor = Colors.transparent;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _pulseController.dispose();
    _salvarPartida();
    super.dispose();
  }

  void _salvarPartida() {
    if (_score <= 0 || _saved) return;
    _saved = true;
    final accuracy =
        _totalHits > 0 ? (_perfectHits / _totalHits) * 100 : 0.0;
    final partida = Partida(
      modoJogo: 'perfect_timing',
      pontuacao: _score,
      precisao: accuracy,
      comboMaximo: _maxCombo,
    );

    // Tentar via Provider (atualiza UI + persiste)
    try {
      context.read<PartidaProvider>().registrarPartida(partida);
      context.read<UsuarioProvider>().adicionarTrofeus(_score);
      context.read<UsuarioProvider>().adicionarVitoria();
      context.read<UsuarioProvider>().atualizarPrecisao(accuracy);
      debugPrint('[PerfectTiming] Salvo via Provider OK');
      return;
    } catch (e) {
      debugPrint('[PerfectTiming] Provider falhou ($e), salvando via services...');
    }

    // Fallback: salvar diretamente via services (funciona mesmo no dispose)
    _salvarViaServices(partida, _score, accuracy);
  }

  void _salvarViaServices(Partida partida, int trofeus, double accuracy) async {
    try {
      final hive = HiveService();
      final firestore = FirestoreService();
      final uid = hive.cachedUid;
      if (uid == null) {
        debugPrint('[PerfectTiming] uid não encontrado no Hive');
        return;
      }

      // Atualizar Hive cache
      final novosTrofeus = hive.cachedTrofeus + trofeus;
      final novasVitorias = hive.cachedVitorias + 1;
      final novaPrecisao = (hive.cachedPrecisaoMedia + accuracy) / 2;
      await hive.salvarCachePerfil(
        uid: uid,
        nickname: hive.cachedNickname ?? 'JOGADOR',
        titulo: hive.cachedTitulo ?? 'ROOKIE',
        nivel: hive.cachedNivel ?? 1,
        trofeus: novosTrofeus,
        vitorias: novasVitorias,
        precisaoMedia: novaPrecisao,
      );

      // Atualizar Firestore ranking
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

      // Salvar partida no Firestore
      await firestore.salvarPartida(uid, partida);

      debugPrint('[PerfectTiming] Salvo via services OK: trofeus=$novosTrofeus, vitorias=$novasVitorias');
    } catch (e) {
      debugPrint('[PerfectTiming] ERRO services: $e');
    }
  }

  // ==================== GAME LOGIC ====================

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _score = 0;
      _saved = false;
      _combo = 0;
      _maxCombo = 0;
      _totalHits = 0;
      _perfectHits = 0;
      _timeLeft = 30;
      _pointerPos = 0.0;
      _movingRight = true;
      _pointerSpeed = 0.008;
      _level = 1;
      _perfectZoneHalf = 0.06;
      _goodZoneHalf = 0.14;
      _okZoneHalf = 0.24;
      _showFeedback = false;
      _barFlashColor = Colors.transparent;
    });

    _startMoveLoop();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _endGame();
    });
  }

  void _startMoveLoop() {
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (_gameState != GameState.playing) {
        t.cancel();
        return;
      }
      setState(() {
        if (_movingRight) {
          _pointerPos += _pointerSpeed;
          if (_pointerPos >= 1.0) {
            _pointerPos = 1.0;
            _movingRight = false;
          }
        } else {
          _pointerPos -= _pointerSpeed;
          if (_pointerPos <= 0.0) {
            _pointerPos = 0.0;
            _movingRight = true;
          }
        }
      });
    });
  }

  void _updateDifficulty() {
    // A cada 200 pontos, sobe de nível
    int newLevel = (_score ~/ 200) + 1;
    if (newLevel > 10) newLevel = 10;
    if (newLevel != _level) {
      _level = newLevel;
      // Zonas encolhem
      _perfectZoneHalf = max(0.02, 0.06 - (_level - 1) * 0.004);
      _goodZoneHalf = max(0.06, 0.14 - (_level - 1) * 0.008);
      _okZoneHalf = max(0.12, 0.24 - (_level - 1) * 0.012);
      // Ponteiro acelera
      _pointerSpeed = min(0.025, 0.008 + (_level - 1) * 0.002);
    }
  }

  void _checkTiming() {
    if (_gameState != GameState.playing) return;
    _totalHits++;

    final double center = 0.5;
    final double dist = (_pointerPos - center).abs();

    if (dist <= _perfectZoneHalf) {
      // PERFEITO
      _combo++;
      _perfectHits++;
      int pts = 100 + _combo * 15;
      setState(() {
        _score += pts;
        _feedbackText = 'PERFEITO! +$pts';
        _feedbackColor = const Color(0xFF00FFFF);
        _feedbackScale = 1.4;
        _showFeedback = true;
        _barFlashColor = const Color(0xFF00FFFF);
      });
    } else if (dist <= _goodZoneHalf) {
      // BOM
      _combo++;
      int pts = 40 + _combo * 8;
      setState(() {
        _score += pts;
        _feedbackText = 'BOM! +$pts';
        _feedbackColor = const Color(0xFFFFE600);
        _feedbackScale = 1.2;
        _showFeedback = true;
        _barFlashColor = const Color(0xFFFFE600);
      });
    } else if (dist <= _okZoneHalf) {
      // OK
      _combo = 0;
      setState(() {
        _score += 10;
        _feedbackText = 'OK +10';
        _feedbackColor = const Color(0xFFFF8800);
        _feedbackScale = 1.0;
        _showFeedback = true;
        _barFlashColor = const Color(0xFFFF8800);
      });
    } else {
      // FALHOU
      _combo = 0;
      setState(() {
        _feedbackText = 'FALHOU!';
        _feedbackColor = const Color(0xFFFF0055);
        _feedbackScale = 1.0;
        _showFeedback = true;
        _barFlashColor = const Color(0xFFFF0055);
      });
    }

    if (_combo > _maxCombo) _maxCombo = _combo;
    _updateDifficulty();

    // Flash da barra
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _barFlashColor = Colors.transparent);
    });

    // Esconde feedback
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _salvarPartida();
    setState(() => _gameState = GameState.gameOver);
  }

  void _backToIdle() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    setState(() {
      _gameState = GameState.idle;
      _score = 0;
      _combo = 0;
    });
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(16),
            child: _gameState == GameState.idle
                ? _buildIdle()
                : _gameState == GameState.gameOver
                    ? _buildGameOver()
                    : _buildPlaying(),
          ),
        ),
      ),
    );
  }

  // ==================== IDLE ====================

  Widget _buildIdle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: Color(0xFF71717A), size: 16),
              Text('Sair',
                  style: TextStyle(
                      color: Color(0xFF71717A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 48),
        const Icon(Icons.timer_outlined, color: Color(0xFF00FFFF), size: 64),
        const SizedBox(height: 16),
        const Text('PERFECT TIMING',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          'Clique quando o ponteiro estiver\nno centro da zona alvo!',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 32),
        _infoTile('ZONA ALVO', 'Pulsa e encolhe com o nível', const Color(0xFF00FFFF)),
        _infoTile('VELOCIDADE', 'Aumenta a cada 200 pts', const Color(0xFF00FF66)),
        _infoTile('COMBO', 'Acertos seguidos = bônus', const Color(0xFFFF3366)),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FFFF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('COMEÇAR',
              style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String desc, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 24),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(desc,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== PLAYING ====================

  Widget _buildPlaying() {
    String speedLabel;
    Color speedColor;
    if (_level <= 2) {
      speedLabel = 'LENTA';
      speedColor = const Color(0xFF00FF66);
    } else if (_level <= 4) {
      speedLabel = 'MÉDIA';
      speedColor = const Color(0xFFFFCC00);
    } else if (_level <= 7) {
      speedLabel = 'RÁPIDA';
      speedColor = const Color(0xFFFF8800);
    } else {
      speedLabel = 'INSANA';
      speedColor = const Color(0xFFFF0055);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                _gameTimer?.cancel();
                _moveTimer?.cancel();
                Navigator.pop(context);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, color: Color(0xFF71717A), size: 16),
                  Text('Sair',
                      style: TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            // Timer
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _timeLeft / 30,
                    strokeWidth: 3,
                    backgroundColor: const Color(0xFF18181B),
                    color: _timeLeft <= 5
                        ? const Color(0xFFFF0055)
                        : const Color(0xFF00FFFF),
                  ),
                  Text('$_timeLeft',
                      style: TextStyle(
                          color: _timeLeft <= 5
                              ? const Color(0xFFFF0055)
                              : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            // Nível
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: speedColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: speedColor.withOpacity(0.4)),
              ),
              child: Text('Nv.$_level',
                  style: TextStyle(
                      color: speedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Score + Combo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _scoreBlock('PONTOS', '$_score', Colors.white),
            const SizedBox(width: 40),
            _scoreBlock('COMBO', _combo > 0 ? 'x$_combo' : '-',
                _combo >= 5 ? const Color(0xFFFF0055) : const Color(0xFF00FF66)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('VELOCIDADE: ',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            Text(speedLabel,
                style: TextStyle(
                    color: speedColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 16),

        // Feedback
        AnimatedScale(
          scale: _showFeedback ? _feedbackScale : 0.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedOpacity(
            opacity: _showFeedback ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 100),
            child: Text(_feedbackText,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _feedbackColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 16),

        // ==================== BARRA PRINCIPAL ====================
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, _) {
            return Container(
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF09090B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _barFlashColor.withOpacity(0.6), width: 2),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final center = w / 2;

                  // Tamanhos dinâmicos baseados nos halves
                  final okW = _okZoneHalf * 2 * w;
                  final goodW = _goodZoneHalf * 2 * w;
                  final perfectW = _perfectZoneHalf * 2 * w;

                  // Pulse do alvo
                  final pulse = _pulseAnim.value;
                  final perfectPulse = perfectW * pulse;
                  final goodPulse = goodW * pulse;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Zona OK
                      Container(
                        width: okW,
                        height: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8800).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFFF8800).withOpacity(0.15)),
                        ),
                      ),
                      // Zona BOA
                      Container(
                        width: goodPulse,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE600).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFFFE600).withOpacity(0.2)),
                        ),
                      ),
                      // Zona PERFEITA
                      Container(
                        width: perfectPulse,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00FFFF).withOpacity(0.15),
                              const Color(0xFF00FFFF).withOpacity(0.35),
                              const Color(0xFF00FFFF).withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF00FFFF).withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFFF)
                                  .withOpacity(0.15 * pulse),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Linha central
                      Container(
                        width: 2,
                        height: double.infinity,
                        color: const Color(0xFF00FFFF).withOpacity(0.6),
                      ),
                      // Labels
                      Positioned(
                        left: 8,
                        child: Text('OK',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ),
                      Positioned(
                        left: center - goodPulse / 2 - 20,
                        width: goodPulse + 40,
                        child: Center(
                          child: Text('BOM',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.25),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Positioned(
                        left: center - perfectPulse / 2 - 30,
                        width: perfectPulse + 60,
                        child: Center(
                          child: Text('★',
                              style: TextStyle(
                                  color: const Color(0xFF00FFFF).withOpacity(0.5),
                                  fontSize: 10)),
                        ),
                      ),

                      // ==================== PONTEIRO ====================
                      Positioned(
                        left: _pointerPos * (w - 24),
                        child: Container(
                          width: 24,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white,
                                Color(0xFF00FFFF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: const Color(0xFF00FFFF).withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // ==================== BOTÃO DE CLIQUE ====================
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => _checkTiming(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _barFlashColor.withOpacity(0.3),
                    const Color(0xFF050505),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _barFlashColor != Colors.transparent
                      ? _barFlashColor.withOpacity(0.5)
                      : const Color(0xFF00FFFF).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gavel_rounded,
                        color: _barFlashColor != Colors.transparent
                            ? Colors.white
                            : const Color(0xFF00FFFF),
                        size: 48),
                    const SizedBox(height: 12),
                    Text(
                        _barFlashColor != Colors.transparent
                            ? _feedbackText
                            : 'CLIQUE NO ALVO',
                        style: TextStyle(
                            color: _barFlashColor != Colors.transparent
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreBlock(String label, String value, Color c) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        Text(value,
            style: TextStyle(
                color: c, fontSize: 32, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // ==================== GAME OVER ====================

  Widget _buildGameOver() {
    final acc = _totalHits > 0
        ? ((_perfectHits / _totalHits) * 100).toStringAsFixed(0)
        : '0';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _backToIdle,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: Color(0xFF71717A), size: 16),
              Text('Voltar',
                  style: TextStyle(
                      color: Color(0xFF71717A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Icon(Icons.emoji_events, color: Color(0xFFFFCC00), size: 64),
        const SizedBox(height: 16),
        const Text('TEMPO ESGOTADO!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Nível máximo: $_level',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const SizedBox(height: 32),
        _stat('PONTUAÇÃO', '$_score', Colors.white),
        _stat('MAIOR COMBO', 'x$_maxCombo', const Color(0xFFFF3366)),
        _stat('PERFEITOS', '$_perfectHits', const Color(0xFF00FFFF)),
        _stat('PRECISÃO', '$acc%', const Color(0xFFFFCC00)),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FFFF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('JOGAR NOVAMENTE',
              style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Color(0xFF27272A)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('VOLTAR AO MENU',
              style: TextStyle(
                  color: Color(0xFF71717A),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          Text(value,
              style:
                  TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
