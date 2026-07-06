import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/partida.dart';
import '../services/database_local.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';

/// Provider que gerencia o histórico de partidas do jogador.
/// Utiliza SQLite (banco relacional) para persistência local.
/// No web, utiliza Firestore para persistência.
class PartidaProvider extends ChangeNotifier {
  final DatabaseLocal _db = DatabaseLocal();
  final FirestoreService _firestore = FirestoreService();
  final HiveService _hive = HiveService();

  List<Partida> _historico = [];
  bool _carregando = false;

  List<Partida> get historico => _historico;
  bool get carregando => _carregando;

  /// Carrega o histórico completo.
  Future<void> carregarHistorico() async {
    _carregando = true;
    notifyListeners();

    if (kIsWeb) {
      final uid = _hive.cachedUid;
      if (uid != null) {
        _historico = await _firestore.buscarHistorico(uid);
      }
    } else {
      _historico = await _db.buscarHistorico();
    }

    _carregando = false;
    notifyListeners();
  }

  /// Registra uma nova partida e atualiza a lista em memória.
  Future<void> registrarPartida(Partida partida) async {
    if (kIsWeb) {
      final uid = _hive.cachedUid;
      if (uid != null) {
        await _firestore.salvarPartida(uid, partida);
      }
      _historico.insert(0, partida);
    } else {
      final id = await _db.inserirPartida(partida);
      final partidaComId = partida.copyWith(id: id);
      _historico.insert(0, partidaComId);
    }
    notifyListeners();
  }

  /// Retorna a média de pontos por modo de jogo (para gráficos).
  Future<double> mediaPontosPorModo(String modo) async {
    if (kIsWeb) return 0.0;
    return await _db.buscarMediaDePontosPorModo(modo);
  }

  /// Retorna o total de partidas jogadas.
  Future<int> totalPartidas() async {
    if (kIsWeb) return _historico.length;
    return await _db.totalPartidas();
  }

  /// Filtra histórico por modo de jogo.
  List<Partida> historicoPorModo(String modo) {
    return _historico.where((p) => p.modoJogo == modo).toList();
  }

  /// Retorna a melhor pontuação de um modo específico.
  Future<int> melhorPontuacao(String modo) async {
    if (kIsWeb) {
      final partidas = historicoPorModo(modo);
      if (partidas.isEmpty) return 0;
      return partidas.map((p) => p.pontuacao).reduce((a, b) => a > b ? a : b);
    }
    return await _db.melhorPontuacao(modo);
  }
}
