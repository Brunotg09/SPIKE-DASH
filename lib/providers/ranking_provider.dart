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
  List<String> _pedidosRecebidos = [];
  List<String> _pedidosEnviados = [];
  List<Map<String, dynamic>> _dadosPedidosRecebidos = [];

  Stream<QuerySnapshot>? get stream {
    if (_activeFilter == 2) return _streamAmigos;
    if (_activeFilter == 1) return _streamSemanal;
    return _streamGlobal;
  }

  int get activeFilter => _activeFilter;
  List<String> get uidsAmigos => _uidsAmigos;
  List<String> get pedidosRecebidos => _pedidosRecebidos;
  List<String> get pedidosEnviados => _pedidosEnviados;
  List<Map<String, dynamic>> get dadosPedidosRecebidos => _dadosPedidosRecebidos;
  int get totalPedidosPendentes => _pedidosRecebidos.length;

  /// Inicia o stream de dados do ranking global.
  void iniciarStreamRanking() {
    _streamGlobal = _firestore.streamRankingGlobal();
    _streamSemanal = _firestore.streamRankingSemanal();
    notifyListeners();
  }

  /// Carrega a lista de amigos e inicia o stream de amigos.
  Future<void> carregarAmigos(String uid) async {
    _uidsAmigos = await _firestore.buscarAmigos(uid);
    _streamAmigos = _firestore.streamRankingAmigos(_uidsAmigos);
    notifyListeners();
  }

  /// Carrega pedidos pendentes (recebidos e enviados).
  Future<void> carregarPedidos(String uid) async {
    _pedidosRecebidos = await _firestore.buscarPedidosRecebidos(uid);
    _pedidosEnviados = await _firestore.buscarPedidosEnviados(uid);
    if (_pedidosRecebidos.isNotEmpty) {
      _dadosPedidosRecebidos = await _firestore.buscarDadosUsuarios(_pedidosRecebidos);
    } else {
      _dadosPedidosRecebidos = [];
    }
    notifyListeners();
  }

  /// Aceita pedido de amizade.
  Future<bool> aceitarPedido(String meuUid, String uidRemetente) async {
    final success = await _firestore.aceitarPedido(meuUid, uidRemetente);
    if (success) {
      await carregarPedidos(meuUid);
      await carregarAmigos(meuUid);
      refreshStream();
    }
    return success;
  }

  /// Recusa pedido de amizade.
  Future<void> recusarPedido(String meuUid, String uidRemetente) async {
    await _firestore.recusarPedido(meuUid, uidRemetente);
    await carregarPedidos(meuUid);
  }

  /// Força refresh do stream (recarrega dados do Firestore).
  void refreshStream() {
    _streamGlobal = _firestore.streamRankingGlobal();
    _streamSemanal = _firestore.streamRankingSemanal();
    _streamAmigos = _firestore.streamRankingAmigos(_uidsAmigos);
    notifyListeners();
  }

  /// Muda o filtro ativo (0=Global, 1=Semanal, 2=Amigos).
  void setFilter(int filter) {
    _activeFilter = filter;
    notifyListeners();
  }
}
