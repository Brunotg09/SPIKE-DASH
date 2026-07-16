import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Provider que gerencia o ranking global (leaderboard).
/// Conecta ao Cloud Firestore para dados em tempo real.
class RankingProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  Stream<QuerySnapshot>? _streamGlobal;
  Stream<QuerySnapshot>? _streamSemanal;
  int _activeFilter = 0;

  Stream<QuerySnapshot>? get stream {
    if (_activeFilter == 1) return _streamSemanal;
    return _streamGlobal;
  }

  int get activeFilter => _activeFilter;

  /// Inicia o stream de dados do ranking global.
  void iniciarStreamRanking() {
    _streamGlobal = _firestore.streamRankingGlobal();
    _streamSemanal = _firestore.streamRankingSemanal();
    notifyListeners();
  }

  /// Força refresh do stream (recarrega dados do Firestore).
  void refreshStream() {
    _streamGlobal = _firestore.streamRankingGlobal();
    _streamSemanal = _firestore.streamRankingSemanal();
    notifyListeners();
  }

  /// Muda o filtro ativo (0=Global, 1=Semanal).
  void setFilter(int filter) {
    _activeFilter = filter;
    notifyListeners();
  }
}
