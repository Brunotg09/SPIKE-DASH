// lib/stroop_shot_screen.dart
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

class StroopShotScreen extends StatefulWidget {
  const StroopShotScreen({super.key});

  @override
  State<StroopShotScreen> createState() => _StroopShotScreenState();
}

enum GameState { idle, showingWord, pickingColor, feedback, gameOver }

class _StroopShotScreenState extends State<StroopShotScreen>
    with TickerProviderStateMixin {
  GameState _gameState = GameState.idle;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'VERDE', 'color': const Color(0xFF00FF66)},
    {'name': 'AZUL', 'color': const Color(0xFF00BFFF)},
    {'name': 'VERMELHO', 'color': const Color(0xFFFF0055)},
    {'name': 'AMARELO', 'color': const Color(0xFFFFE600)},
    {'name': 'ROXO', 'color': const Color(0xFFBB66FF)},
  ];

  int _textIndex = 0;
  int _colorIndex = 0;

  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _totalRounds = 0;
  int _correctAnswers = 0;
  int _round = 0;
  int _maxRounds = 15;

  int _timeLeft = 30;
  int _pickTimeLeft = 0;
  int _pickTimeMax = 8;
  Timer? _gameTimer;
  Timer? _pickTimer;
  Timer? _wordTimer;

  String _feedbackText = '';
  Color _feedbackColor = Colors.white;

  int _difficultyLevel = 1;
  final Random _rng = Random();
  bool _saved = false;

  @override
  void dispose() {
    _gameTimer?.cancel();
    _pickTimer?.cancel();
    _wordTimer?.cancel();
    _salvarPartida();
    super.dispose();
  }

  void _salvarPartida() {
    if (_score <= 0 || _saved) return;
    _saved = true;
    final accuracy =
        _totalRounds > 0 ? (_correctAnswers / _totalRounds) * 100 : 0.0;
    final partida = Partida(
      modoJogo: 'stroop_shot',
      pontuacao: _score,
      precisao: accuracy,
      comboMaximo: _maxCombo,
    );

    try {
      context.read<PartidaProvider>().registrarPartida(partida);
      context.read<UsuarioProvider>().adicionarTrofeus(_score);
      context.read<UsuarioProvider>().adicionarVitoria();
      context.read<UsuarioProvider>().atualizarPrecisao(accuracy);
      debugPrint('[StroopShot] Salvo via Provider OK');
      return;
    } catch (e) {
      debugPrint('[StroopShot] Provider falhou ($e), salvando via services...');
    }

    _salvarViaServices(partida, _score, accuracy);
  }

  void _salvarViaServices(Partida partida, int trofeus, double accuracy) async {
    try {
      final hive = HiveService();
      final firestore = FirestoreService();
      final uid = hive.cachedUid;
      if (uid == null) return;

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

      debugPrint('[StroopShot] Salvo via services OK: trofeus=$novosTrofeus, vitorias=$novasVitorias');
    } catch (e) {
      debugPrint('[StroopShot] ERRO services: $e');
    }
  }

  // ==================== GAME LOGIC ====================

  void _startGame() {
    _gameTimer?.cancel();
    _pickTimer?.cancel();
    _wordTimer?.cancel();

    setState(() {
      _gameState = GameState.idle;
      _score = 0;
      _saved = false;
      _combo = 0;
      _maxCombo = 0;
      _totalRounds = 0;
      _correctAnswers = 0;
      _round = 0;
      _timeLeft = 30;
      _difficultyLevel = 1;
      _pickTimeMax = 8;
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _endGame();
    });

    _nextRound();
  }

  void _nextRound() {
    if (_round >= _maxRounds || _timeLeft <= 0) {
      _endGame();
      return;
    }

    _round++;
    _textIndex = _rng.nextInt(_colors.length);
    do {
      _colorIndex = _rng.nextInt(_colors.length);
    } while (_colorIndex == _textIndex && _rng.nextDouble() > 0.3);

    // Fase 1: Mostrar a palavra por 1.2s
    setState(() {
      _gameState = GameState.showingWord;
    });

    _wordTimer = Timer(const Duration(milliseconds: 1200), () {
      if (_gameState != GameState.showingWord) return;

      // Fase 2: Esconder palavra, mostrar botões com timer
      setState(() {
        _gameState = GameState.pickingColor;
        _pickTimeLeft = _pickTimeMax;
      });

      _pickTimer?.cancel();
      _pickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_gameState != GameState.pickingColor) {
          t.cancel();
          return;
        }
        setState(() => _pickTimeLeft--);
        if (_pickTimeLeft <= 0) {
          t.cancel();
          _wrongAnswer();
        }
      });
    });
  }

  void _verifyAnswer(int selectedIndex) {
    if (_gameState != GameState.pickingColor) return;

    _pickTimer?.cancel();

    if (selectedIndex == _colorIndex) {
      _correctAnswer();
    } else {
      _wrongAnswer();
    }
  }

  void _correctAnswer() {
    _totalRounds++;
    _correctAnswers++;
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;

    int points = 100 + (_combo * 25);
    _score += points;

    setState(() {
      _gameState = GameState.feedback;
      _feedbackText = 'CERTO! +$points';
      _feedbackColor = const Color(0xFF00FF66);
    });

    _updateDifficulty();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _gameState == GameState.feedback) _nextRound();
    });
  }

  void _wrongAnswer() {
    _totalRounds++;
    _combo = 0;

    setState(() {
      _gameState = GameState.feedback;
      _feedbackText = 'ERRADO! Era ${_colors[_colorIndex]['name']}';
      _feedbackColor = const Color(0xFFFF0055);
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _gameState == GameState.feedback) _nextRound();
    });
  }

  void _updateDifficulty() {
    int newLevel = (_correctAnswers ~/ 3) + 1;
    if (newLevel > 6) newLevel = 6;
    if (newLevel != _difficultyLevel) {
      _difficultyLevel = newLevel;
      _pickTimeMax = max(4, 8 - (_difficultyLevel - 1));
    }
  }

  void _endGame() {
    _gameTimer?.cancel();
    _pickTimer?.cancel();
    _wordTimer?.cancel();
    _salvarPartida();
    setState(() => _gameState = GameState.gameOver);
  }

  void _backToIdle() {
    _gameTimer?.cancel();
    _pickTimer?.cancel();
    _wordTimer?.cancel();
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
        const Icon(Icons.lens_blur, color: Color(0xFFFF0055), size: 64),
        const SizedBox(height: 16),
        const Text('STROOP SHOT',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          'Memorize a cor da palavra e depois\nclique no botão correto!',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 32),
        _infoTile('FASE 1', 'A palavra aparece por 1.2s', const Color(0xFF00FFFF)),
        _infoTile('FASE 2', 'Escolha a cor VISUAL em até ${_pickTimeMax}s', const Color(0xFFFFE600)),
        _infoTile('DIFICULDADE', 'Tempo de escolha diminui', const Color(0xFFFF0055)),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF0055),
            foregroundColor: Colors.white,
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
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              Text(desc,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== PLAYING ====================

  Widget _buildPlaying() {
    Color speedColor;
    if (_difficultyLevel <= 2) {
      speedColor = const Color(0xFF00FF66);
    } else if (_difficultyLevel <= 4) {
      speedColor = const Color(0xFFFFCC00);
    } else {
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
                _pickTimer?.cancel();
                _wordTimer?.cancel();
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
            // Timer geral
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
                        : const Color(0xFFFF0055),
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
            // Round
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: speedColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: speedColor.withOpacity(0.4)),
              ),
              child: Text('$_round/$_maxRounds',
                  style: TextStyle(
                      color: speedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Score + Combo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _scoreBlock('PONTOS', '$_score', Colors.white),
            const SizedBox(width: 32),
            _scoreBlock(
                'COMBO',
                _combo > 0 ? 'x$_combo' : '-',
                _combo >= 5
                    ? const Color(0xFFFF0055)
                    : _combo >= 3
                        ? const Color(0xFFFFCC00)
                        : const Color(0xFF00FF66)),
          ],
        ),
        const SizedBox(height: 12),

        // ==================== PAINEL PRINCIPAL ====================
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF09090B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF18181B)),
            ),
            child: _gameState == GameState.showingWord
                ? _buildShowWordPhase()
                : _gameState == GameState.pickingColor
                    ? _buildPickPhase()
                    : _buildFeedbackPhase(),
          ),
        ),
      ],
    );
  }

  // FASE 1: Mostrar a palavra em cor diferente
  Widget _buildShowWordPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'MEMORIZE A COR!',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        // Indicador visual: barra que diminui
        Container(
          width: 120,
          height: 4,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(2),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 0.0),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ),
        // PALAVRA GRANDE em cor diferente
        Text(
          _colors[_textIndex]['name'],
          style: TextStyle(
            color: _colors[_colorIndex]['color'],
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: _colors[_colorIndex]['color'].withOpacity(0.6),
                blurRadius: 30,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '← esta é a cor que você vê',
          style: TextStyle(
              color: _colors[_colorIndex]['color'].withOpacity(0.5),
              fontSize: 11),
        ),
      ],
    );
  }

  // FASE 2: Botões de cor com timer
  Widget _buildPickPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'QUAL ERA A COR?',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Timer de escolha
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _pickTimeLeft / _pickTimeMax,
                strokeWidth: 3,
                backgroundColor: const Color(0xFF18181B),
                color: _pickTimeLeft <= 3
                    ? const Color(0xFFFF0055)
                    : const Color(0xFFFFCC00),
              ),
              Text('$_pickTimeLeft',
                  style: TextStyle(
                      color: _pickTimeLeft <= 3
                          ? const Color(0xFFFF0055)
                          : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Botões de cor
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: _colors.length,
            itemBuilder: (context, index) {
              final item = _colors[index];
              return GestureDetector(
                onTap: () => _verifyAnswer(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF050505),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item['color'].withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item['color'].withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      item['name'],
                      style: TextStyle(
                          color: item['color'],
                          fontSize: 14,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // FEEDBACK: Acerto ou erro
  Widget _buildFeedbackPhase() {
    bool isCorrect = _feedbackColor == const Color(0xFF00FF66);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: _feedbackColor,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          _feedbackText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _feedbackColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (!isCorrect) ...[
          const SizedBox(height: 8),
          Text(
            'A resposta era:',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            _colors[_colorIndex]['name'],
            style: TextStyle(
              color: _colors[_colorIndex]['color'],
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
                color: c, fontSize: 28, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // ==================== GAME OVER ====================

  Widget _buildGameOver() {
    final accuracy = _totalRounds > 0
        ? ((_correctAnswers / _totalRounds) * 100).toStringAsFixed(0)
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
        Text(
          _timeLeft <= 0 ? 'TEMPO ESGOTADO!' : 'RODADAS ESGOTADAS!',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text('Nível máximo: $_difficultyLevel',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const SizedBox(height: 32),
        _stat('PONTUAÇÃO', '$_score', Colors.white),
        _stat('MAIOR COMBO', 'x$_maxCombo', const Color(0xFFFF3366)),
        _stat('ACERTOS', '$_correctAnswers / $_totalRounds', const Color(0xFF00FF66)),
        _stat('PRECISÃO', '$accuracy%', const Color(0xFFFFCC00)),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF0055),
            foregroundColor: Colors.white,
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
              style: TextStyle(
                  color: c, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
