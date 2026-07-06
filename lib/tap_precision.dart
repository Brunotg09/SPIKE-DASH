// lib/tap_precision_screen.dart
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

class TapPrecisionScreen extends StatefulWidget {
  const TapPrecisionScreen({super.key});

  @override
  State<TapPrecisionScreen> createState() => _TapPrecisionScreenState();
}

class _TapPrecisionScreenState extends State<TapPrecisionScreen>
    with SingleTickerProviderStateMixin {
  bool _gameActive = false;
  bool _saved = false;
  int _score = 0;
  int _combo = 0;
  int _secondsLeft = 30;
  Timer? _countdownTimer;
  Timer? _targetExpirationTimer;

  // Removido o Duration fixo antigo daqui

  double _targetX = 0.5;
  double _targetY = 0.5;

  late AnimationController _pingController;
  final Random _random = Random(); // Instância única do Random

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _targetExpirationTimer?.cancel();
    _pingController.dispose();
    _salvarPartida();
    super.dispose();
  }

  void _salvarPartida() {
    if (_score <= 0 || _saved) return;
    _saved = true;
    final accuracy = _score > 0 ? (_score / (_score + 1)) * 100 : 0.0;
    final partida = Partida(
      modoJogo: 'tap_precision',
      pontuacao: _score,
      precisao: accuracy,
      comboMaximo: _combo,
    );

    try {
      context.read<PartidaProvider>().registrarPartida(partida);
      context.read<UsuarioProvider>().adicionarTrofeus(_score);
      context.read<UsuarioProvider>().adicionarVitoria();
      context.read<UsuarioProvider>().atualizarPrecisao(accuracy);
      debugPrint('[TapPrecision] Salvo via Provider OK');
      return;
    } catch (e) {
      debugPrint('[TapPrecision] Provider falhou ($e), salvando via services...');
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

      debugPrint('[TapPrecision] Salvo via services OK: trofeus=$novosTrofeus, vitorias=$novasVitorias');
    } catch (e) {
      debugPrint('[TapPrecision] ERRO services: $e');
    }
  }

  void _startTapGame() {
    setState(() {
      _gameActive = true;
      _score = 0;
      _saved = false;
      _combo = 0;
      _secondsLeft = 30;
    });
    _spawnNewTarget();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    _countdownTimer?.cancel();
    _targetExpirationTimer?.cancel();
    _salvarPartida();
    setState(() {
      _gameActive = false;
    });
  }

  void _resetTapGame() {
    _countdownTimer?.cancel();
    _targetExpirationTimer?.cancel();
    setState(() {
      _gameActive = false;
      _score = 0;
      _combo = 0;
      _secondsLeft = 30;
    });
  }

  // Gera uma nova bolinha com tempo de expiração randômico entre 0.8s e 1.5s
  void _spawnNewTarget() {
    if (!_gameActive) return;

    setState(() {
      _targetX = 0.08 + _random.nextDouble() * 0.84;
      _targetY = 0.08 + _random.nextDouble() * 0.84;
    });

    _targetExpirationTimer?.cancel();

    // Lógica da variação: 800ms fixos + (0 a 700ms aleatórios) = de 800ms a 1500ms
    int dynamicLifetimeMs = 800 + _random.nextInt(701);
    Duration targetLifetime = Duration(milliseconds: dynamicLifetimeMs);

    _targetExpirationTimer = Timer(targetLifetime, () {
      if (_gameActive) {
        setState(() {
          _combo = 0;
        });
        _spawnNewTarget();
      }
    });
  }

  void _registerHit() {
    if (!_gameActive) return;
    setState(() {
      _score++;
      _combo++;
    });
    _spawnNewTarget();
  }

  void _registerMiss() {
    if (!_gameActive) return;
    setState(() {
      _combo = 0;
    });
  }

  String _formatTimer(int seconds) {
    return "00:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _resetTapGame();
                        Navigator.pop(context);
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.chevron_left,
                              color: Color(0xFFF4F4F5), size: 16),
                          Text(
                            'voltar',
                            style: TextStyle(
                              color: Color(0xFFF4F4F5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const Text(
                          'TEMPO',
                          style: TextStyle(
                            color: Color(0xFFFFFF00),
                            fontSize: 10,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTimer(_secondsLeft),
                          style: const TextStyle(
                            color: Color(0xFFFFFF00),
                            fontSize: 20,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Color(0xFFFF0550), blurRadius: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'PONTOS',
                          style: TextStyle(
                            color: Color(0xFFF4F4F5),
                            fontSize: 10,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$_score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFF18181B), height: 1),
                ),
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) => _registerMiss(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF050505),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF18181B)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.02,
                                    child: GridPaper(
                                      color: const Color(0xFF00FF66),
                                      interval: 30,
                                      subdivisions: 1,
                                    ),
                                  ),
                                ),
                                if (_gameActive && _combo > 0)
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00FF66)
                                            .withOpacity(0.1),
                                        border: Border.all(
                                            color: const Color(0xFF00FF66)
                                                .withOpacity(0.3)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'COMBO x$_combo',
                                        style: const TextStyle(
                                          color: Color(0xFF00FF66),
                                          fontSize: 12,
                                          fontFamily: 'Orbitron',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_gameActive)
                                  Positioned(
                                    left:
                                        _targetX * (constraints.maxWidth - 48),
                                    top:
                                        _targetY * (constraints.maxHeight - 48),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapDown: (details) {
                                        _registerHit();
                                      },
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            ScaleTransition(
                                              scale: Tween<double>(
                                                      begin: 1.0, end: 2.0)
                                                  .animate(_pingController),
                                              child: FadeTransition(
                                                opacity: Tween<double>(
                                                        begin: 0.75, end: 0.0)
                                                    .animate(_pingController),
                                                child: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xFF00FF66)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00FF66)
                                                    .withOpacity(0.2),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFF00FF66),
                                                    width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF00FF66)
                                                            .withOpacity(0.6),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFF00FF66),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!_gameActive)
                                  Container(
                                    color: Colors.black.withOpacity(0.9),
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: const Color(0xFF00FF66),
                                                width: 2),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.touch_app,
                                              color: Color(0xFF00FF66),
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'TAP PRECISION',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontFamily: 'Orbitron',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Clica rapidamente nos alvos verdes que surgem na tela. Não falhes e não demores para manteres o teu combo ativo!',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFD4D4D8),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton(
                                          onPressed: _startTapGame,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF00FF66),
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 8,
                                            shadowColor: const Color(0xFF00FF66)
                                                .withOpacity(0.4),
                                          ),
                                          child: const Text(
                                            'COMEÇAR TREINO',
                                            style: TextStyle(
                                              fontFamily: 'Orbitron',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09090B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF18181B)),
                  ),
                  child: const Text(
                    'Média de Reação ideal: < 200ms',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF00FF66),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
}
