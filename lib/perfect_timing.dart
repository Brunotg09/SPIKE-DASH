import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
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

enum GamePhase { countdown, playing, ended }

enum ZoneSizeType { small, medium, large }

const Map<ZoneSizeType, double> zoneWidths = {
  ZoneSizeType.small: 6,
  ZoneSizeType.medium: 14,
  ZoneSizeType.large: 24,
};
const Map<ZoneSizeType, int> zonePoints = {
  ZoneSizeType.small: 300,
  ZoneSizeType.medium: 150,
  ZoneSizeType.large: 80,
};
const Map<ZoneSizeType, double> speedMultipliers = {
  ZoneSizeType.small: 1.6,
  ZoneSizeType.medium: 1.2,
  ZoneSizeType.large: 0.9,
};
const List<ZoneSizeType> zoneCycle = [
  ZoneSizeType.large,
  ZoneSizeType.large,
  ZoneSizeType.medium,
  ZoneSizeType.medium,
  ZoneSizeType.small,
];

class _PerfectTimingScreenState extends State<PerfectTimingScreen> {
  GamePhase _phase = GamePhase.countdown;
  int _countdown = 3;
  int _timeLeft = 30;
  int _score = 0;
  int _hits = 0;
  int _perfects = 0;
  double _position = 0;
  int _direction = 1;
  ZoneSizeType _zoneSize = ZoneSizeType.large;
  double _zonePos = 35;
  String _feedbackText = '';
  Color _feedbackColor = Colors.white;
  bool _showFeedback = false;
  int _zoneCycleIndex = 0;
  bool _saved = false;

  Timer? _countdownTimer;
  Timer? _gameTimer;
  Timer? _moveTimer;
  Timer? _zoneTimer;

  int _lastTime = 0;
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _zoneTimer?.cancel();
    _salvarPartida();
    super.dispose();
  }

  // ==================== SAVE ====================

  void _salvarPartida() {
    if (_score <= 0 || _saved) return;
    final accuracy = _score > 0 ? (_perfects / _score) * 100 : 0.0;
    final trofeus = _hits + (_perfects * 3);
    final partida = Partida(
      modoJogo: 'perfect_timing',
      pontuacao: trofeus,
      precisao: _perfects.toDouble(),
      comboMaximo: _perfects,
    );

    try {
      context.read<PartidaProvider>().registrarPartida(partida);
      context.read<UsuarioProvider>().adicionarTrofeus(trofeus);
      context.read<UsuarioProvider>().adicionarVitoria();
      context.read<UsuarioProvider>().atualizarPrecisao(accuracy);
      _saved = true;
      debugPrint('[PerfectTiming] Salvo via Provider OK: trofeus=$trofeus');
      return;
    } catch (e) {
      debugPrint('[PerfectTiming] Provider falhou ($e)');
    }

    _salvarViaServices(partida);
  }

  void _salvarViaServices(Partida partida) async {
    try {
      final hive = HiveService();
      final firestore = FirestoreService();
      final uid = hive.cachedUid;
      if (uid == null) return;

      final trofeus = _hits + (_perfects * 3);
      final novosTrofeus = hive.cachedTrofeus + trofeus;
      final novasVitorias = hive.cachedVitorias + 1;
      final accuracy = _score > 0 ? (_perfects / _score) * 100 : 0.0;
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
    } catch (e) {
      debugPrint('[PerfectTiming] ERRO services: $e');
    }
  }

  // ==================== COUNTDOWN ====================

  void _startCountdown() {
    _countdown = 3;
    _phase = GamePhase.countdown;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() {
          _countdown = 0;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _startPlaying();
        });
        return;
      }
      setState(() => _countdown--);
    });
  }

  // ==================== PLAYING ====================

  void _startPlaying() {
    setState(() {
      _phase = GamePhase.playing;
      _score = 0;
      _saved = false;
      _hits = 0;
      _perfects = 0;
      _timeLeft = 30;
      _position = 0;
      _direction = 1;
      _zoneSize = ZoneSizeType.large;
      _zonePos = 35;
      _zoneCycleIndex = 0;
      _showFeedback = false;
    });

    _lastTime = DateTime.now().microsecondsSinceEpoch;

    // Game timer (1s countdown)
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_phase != GamePhase.playing) {
        t.cancel();
        return;
      }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _endGame();
    });

    // Zone cycling (4s)
    _zoneTimer?.cancel();
    _zoneTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (_phase != GamePhase.playing) {
        t.cancel();
        return;
      }
      setState(() {
        _zoneCycleIndex = (_zoneCycleIndex + 1) % zoneCycle.length;
        _zoneSize = zoneCycle[_zoneCycleIndex];
        _zonePos = _rng.nextDouble() * 60 + 20; // 20-80
      });
    });

    // Movement loop (~60fps with delta time)
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (_phase != GamePhase.playing) {
        t.cancel();
        return;
      }
      final now = DateTime.now().microsecondsSinceEpoch;
      final dt = (now - _lastTime) / 1000000.0;
      _lastTime = now;

      setState(() {
        final speed = speedMultipliers[_zoneSize]!;
        _position += _direction * speed * 50 * dt;
        if (_position >= 100) {
          _position = 100;
          _direction = -1;
        } else if (_position <= 0) {
          _position = 0;
          _direction = 1;
        }
      });
    });
  }

  // ==================== TAP ====================

  void _onTap() {
    if (_phase != GamePhase.playing) return;

    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < 300) return;
    _lastTapTime = now;

    final zw = zoneWidths[_zoneSize]!;
    final half = zw / 2;
    final dist = (_position - _zonePos).abs();

    if (dist <= half) {
      final accuracy = 1 - dist / half;
      final pts = (zonePoints[_zoneSize]! * (0.5 + accuracy * 0.5)).round();
      setState(() {
        _score += pts;
        _hits++;
        if (dist <= half * 0.3) {
          _perfects++;
          _feedbackText = 'PERFEITO! +$pts';
          _feedbackColor = AppColors.primary;
        } else {
          _feedbackText = 'BOM! +$pts';
          _feedbackColor = AppColors.accent;
        }
        _showFeedback = true;
      });
    } else {
      setState(() {
        _feedbackText = 'ERROU!';
        _feedbackColor = AppColors.danger;
        _showFeedback = true;
      });
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }

  // ==================== END ====================

  void _endGame() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _zoneTimer?.cancel();
    _salvarPartida();
    setState(() => _phase = GamePhase.ended);
  }

  void _restart() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _zoneTimer?.cancel();
    setState(() {
      _saved = false;
    });
    _startCountdown();
  }

  void _back() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _zoneTimer?.cancel();
    Navigator.pop(context);
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildScoreBar(),
                _buildTimeProgress(),
                Expanded(child: _buildMainArea()),
              ],
            ),
            if (_phase == GamePhase.countdown) _buildCountdownOverlay(),
            if (_phase == GamePhase.ended) _buildEndOverlay(),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _back,
            child: const Icon(Icons.arrow_left,
                color: AppColors.textMuted, size: 24),
          ),
          const Spacer(),
          const Text(
            'PERFECT TIMING',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.adjust, color: AppColors.accent, size: 16),
              const SizedBox(width: 4),
              Text(
                '$_perfects',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SCORE BAR ====================

  Widget _buildScoreBar() {
    final zw = _zoneSize;
    final zoneLabel = zw == ZoneSizeType.large
        ? 'LARGE'
        : zw == ZoneSizeType.medium
            ? 'MEDIUM'
            : 'SMALL';
    final zoneColor = zw == ZoneSizeType.large
        ? AppColors.primary
        : zw == ZoneSizeType.medium
            ? AppColors.accent
            : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                'SCORE',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 10,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '$_score',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            '${_timeLeft}s',
            style: TextStyle(
              color: _timeLeft <= 10 ? AppColors.danger : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          Column(
            children: [
              Text(
                'ZONA',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 10,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                zoneLabel,
                style: TextStyle(
                  color: zoneColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TIME PROGRESS ====================

  Widget _buildTimeProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 4,
          child: LinearProgressIndicator(
            value: _timeLeft / 30,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }

  // ==================== MAIN AREA ====================

  Widget _buildMainArea() {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'TOQUE NA ZONA VERDE',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
              fontFamily: 'Orbitron',
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final zw = zoneWidths[_zoneSize]! / 100 * w;
                      final zLeft =
                          (_zonePos / 100 * w - zw / 2).clamp(0.0, w - zw);
                      final pLeft =
                          (_position / 100 * w - 6).clamp(0.0, w - 12);

                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              // Green zone
                              Positioned(
                                left: zLeft,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: zw,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.primary,
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.5),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Indicator
                              Positioned(
                                left: pLeft,
                                top: 4,
                                bottom: 4,
                                child: Container(
                                  width: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0',
                        style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 10,
                            fontFamily: 'Orbitron')),
                    Text('50',
                        style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 10,
                            fontFamily: 'Orbitron')),
                    Text('100',
                        style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 10,
                            fontFamily: 'Orbitron')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Feedback
          SizedBox(
            height: 56,
            child: AnimatedScale(
              scale: _showFeedback ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 150),
              child: AnimatedOpacity(
                opacity: _showFeedback ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 100),
                child: Text(
                  _feedbackText,
                  style: TextStyle(
                    color: _feedbackColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: _feedbackColor.withValues(alpha: 0.6),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // TAP button
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'TAP',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ==================== END OVERLAY ====================

  Widget _buildEndOverlay() {
    return Container(
      color: AppColors.background.withValues(alpha: 1),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TEMPO ESGOTADO!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'SCORE',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 12,
                  fontFamily: 'Orbitron',
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_score',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 56,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        '$_perfects',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PERFEITOS',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 10,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _restart,
                child: Container(
                  width: 200,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      'JOGAR NOVAMENTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _back,
                child: Container(
                  width: 200,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'VOLTAR',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== COUNTDOWN OVERLAY ====================

  Widget _buildCountdownOverlay() {
    return AnimatedOpacity(
      opacity: _phase == GamePhase.countdown ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: AppColors.background.withValues(alpha: 0.9),
        child: Center(
          child: Text(
            _countdown == 0 ? 'GO!' : '$_countdown',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 80,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  blurRadius: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}