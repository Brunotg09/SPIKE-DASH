import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/partida.dart';

/// Serviço de comunicação com o Cloud Firestore (banco NoSQL em nuvem).
/// Padrão Singleton. Responsável por:
/// - Dados dos usuários na coleção 'usuarios/'
/// - Rankings globais na coleção 'rankings/'
/// - Histórico de partidas na coleção 'partidas/'
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== USUARIO ====================

  /// Salva ou atualiza os dados do usuário no Firestore.
  Future<void> salvarUsuario(Usuario usuario) async {
    debugPrint('[FirestoreService] salvarUsuario: uid=${usuario.uid}, trofeus=${usuario.trofeus}');
    await _db.collection('usuarios').doc(usuario.uid).set(usuario.toJson());
    debugPrint('[FirestoreService] salvarUsuario OK');
  }

  /// Busca os dados do usuário pelo UID.
  /// Lê de 'usuarios/' e cruza com 'rankings/' para pegar troféus atualizados.
  Future<Usuario?> buscarUsuario(String uid) async {
    debugPrint('[FirestoreService] buscarUsuario: uid=$uid');

    // Buscar dados base do usuario
    final userDoc = await _db.collection('usuarios').doc(uid).get();
    debugPrint('[FirestoreService] buscarUsuario usuarios exists=${userDoc.exists}');

    // Buscar dados atualizados do ranking
    final rankDoc = await _db.collection('rankings').doc(uid).get();
    debugPrint('[FirestoreService] buscarUsuario rankings exists=${rankDoc.exists}, data=${rankDoc.data()}');

    if (!userDoc.exists || userDoc.data() == null) {
      // Se nem usuario existe, tenta criar do ranking
      if (rankDoc.exists && rankDoc.data() != null) {
        final r = rankDoc.data()!;
        return Usuario(
          uid: uid,
          nickname: r['nickname'] ?? 'JOGADOR',
          email: '',
          titulo: r['titulo'] ?? 'ROOKIE',
          trofeus: r['trofeus'] ?? 0,
        );
      }
      return null;
    }

    // Começa com dados do usuario
    final usuario = Usuario.fromJson(userDoc.data()!);

    // Se ranking tem dados, usa os troféus do ranking (fonte da verdade)
    if (rankDoc.exists && rankDoc.data() != null) {
      final r = rankDoc.data()!;
      final rankTrofeus = r['trofeus'] ?? 0;
      debugPrint('[FirestoreService] buscarUsuario: usuario trofeus=${usuario.trofeus}, ranking trofeus=$rankTrofeus');
      if (rankTrofeus > usuario.trofeus) {
        usuario.trofeus = rankTrofeus;
      }
    }

    debugPrint('[FirestoreService] buscarUsuario FINAL: trofeus=${usuario.trofeus}, vitorias=${usuario.vitorias}');
    return usuario;
  }

  // ==================== RANKINGS ====================

  /// Stream em tempo real do ranking global (top N jogadores).
  Stream<QuerySnapshot> streamRankingGlobal({int limit = 100}) {
    return _db
        .collection('rankings')
        .orderBy('trofeus', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Atualiza o documento de ranking de um jogador.
  Future<void> atualizarRanking(Usuario usuario) async {
    await _db.collection('rankings').doc(usuario.uid).set({
      'uid': usuario.uid,
      'nickname': usuario.nickname,
      'titulo': usuario.titulo,
      'trofeus': usuario.trofeus,
      'vitorias': usuario.vitorias,
      'precisaoMedia': usuario.precisaoMedia,
      'periodoSemana': _semanaAtual(),
    });

    // Também atualiza os dados do usuário (merge para não sobrescrever)
    await _db.collection('usuarios').doc(usuario.uid).set({
      'trofeus': usuario.trofeus,
      'vitorias': usuario.vitorias,
      'precisaoMedia': usuario.precisaoMedia,
    }, SetOptions(merge: true));
  }

  // ==================== HISTÓRICO DE PARTIDAS ====================

  /// Salva uma partida no Firestore (subcoleção do usuário).
  Future<void> salvarPartida(String uid, Partida partida) async {
    debugPrint('[FirestoreService] salvarPartida: modo=${partida.modoJogo}, pontos=${partida.pontuacao}');
    await _db.collection('partidas').doc(uid).collection('historico').add({
      'modoJogo': partida.modoJogo,
      'pontuacao': partida.pontuacao,
      'precisao': partida.precisao,
      'comboMaximo': partida.comboMaximo,
      'dataPartida': partida.dataPartida.toIso8601String(),
    });
    debugPrint('[FirestoreService] salvarPartida OK');
  }

  /// Busca o histórico de partidas do usuário.
  Future<List<Partida>> buscarHistorico(String uid) async {
    debugPrint('[FirestoreService] buscarHistorico: uid=$uid');
    final snapshot = await _db
        .collection('partidas')
        .doc(uid)
        .collection('historico')
        .orderBy('dataPartida', descending: true)
        .limit(50)
        .get();

    final partidas = snapshot.docs.map((doc) {
      final data = doc.data();
      return Partida(
        modoJogo: data['modoJogo'] ?? '',
        pontuacao: data['pontuacao'] ?? 0,
        precisao: (data['precisao'] as num?)?.toDouble() ?? 0.0,
        comboMaximo: data['comboMaximo'] ?? 0,
        dataPartida: DateTime.parse(data['dataPartida']),
      );
    }).toList();

    debugPrint('[FirestoreService] buscarHistorico: ${partidas.length} partidas encontradas');
    return partidas;
  }

  /// Calcula o identificador da semana atual (ex: "2026-S25").
  String _semanaAtual() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays;
    final weekNumber = (dayOfYear / 7).ceil();
    return '${now.year}-S${weekNumber.toString().padLeft(2, '0')}';
  }
}
