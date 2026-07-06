import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Provider que gerencia o ranking global (leaderboard).
/// Conecta ao Cloud Firestore para dados em tempo real.
class RankingProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  Stream<QuerySnapshot>? _stream;

  Stream<QuerySnapshot>? get stream => _stream;

  /// Inicia o stream de dados do ranking global.
  void iniciarStreamRanking() {
    _stream = _firestore.streamRankingGlobal();
    notifyListeners();
  }

  /// Força refresh do stream (recarrega dados do Firestore).
  void refreshStream() {
    _stream = _firestore.streamRankingGlobal();
    notifyListeners();
  }
}
