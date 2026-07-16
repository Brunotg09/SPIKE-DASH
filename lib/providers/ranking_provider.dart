import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Provider que gerencia o ranking (global, semanal, amigos).
/// Conecta ao Cloud Firestore para dados em tempo real.
class RankingProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  Stream<QuerySnapshot>? _streamGlobal;
  Stream<QuerySnapshot>? _streamSemanal;
  Stream<QuerySnapshot>? _streamAmigos;
  int _activeFilter = 0;
  List<String> _uidsAmigos = [];

  Stream<QuerySnapshot>? get stream {
    if (_activeFilter == 2) return _streamAmigos;
    if (_activeFilter == 1) return _streamSemanal;
    return _streamGlobal;
  }

  int get activeFilter => _activeFilter;
  List<String> get uidsAmigos => _uidsAmigos;

  /// Inicia o stream de dados do ranking global.
  void iniciarStreamRanking() {
    _streamGlobal = _firestore.streamRankingGlobal();
    _streamSemanal = _firestore.streamRankingSemanal();
    notifyListeners();
  }

  /// Carrega a lista de amigos e inicia o stream de amigos.
  Future<void> carregarAmigos(String uid) async {
    _uidsAmigos = await _firestore.buscarAmigos(uid);
    if (_uidsAmigos.isNotEmpty) {
      _streamAmigos = _firestore.streamRankingAmigos(_uidsAmigos);
    }
    notifyListeners();
  }

  /// Força refresh do stream (recarrega dados do Firestore).
  void refreshStream() {
    _streamGlobal = _firestore.streamRankingGlobal();
    _streamSemanal = _firestore.streamRankingSemanal();
    if (_uidsAmigos.isNotEmpty) {
      _streamAmigos = _firestore.streamRankingAmigos(_uidsAmigos);
    }
    notifyListeners();
  }

  /// Muda o filtro ativo (0=Global, 1=Semanal, 2=Amigos).
  void setFilter(int filter) {
    _activeFilter = filter;
    notifyListeners();
  }
}
