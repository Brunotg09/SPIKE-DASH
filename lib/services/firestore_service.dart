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

  /// Salva dados do perfil do usuário em 'usuarios/'.
  Future<void> salvarUsuario(Usuario usuario) async {
    debugPrint('[FirestoreService] salvarUsuario: uid=${usuario.uid}, nickname=${usuario.nickname}');
    await _db.collection('usuarios').doc(usuario.uid).set({
      'uid': usuario.uid,
      'nickname': usuario.nickname,
      'email': usuario.email,
      'xp': usuario.xp,
      'nivel': usuario.nivel,
      'nivelNome': usuario.nivelNome,
      'nivelProgresso': usuario.nivelProgresso,
      'avatarId': usuario.avatarId,
      'avatarsDesbloqueados': usuario.avatarsDesbloqueados,
      'titulo': usuario.titulo,
      'titulosDesbloqueados': usuario.titulosDesbloqueados,
      'conquistasDesbloqueadas': usuario.conquistasDesbloqueadas,
    });
    debugPrint('[FirestoreService] salvarUsuario OK');
  }

  /// Busca os dados do usuário pelo UID.
  /// 'usuarios/' = perfil (nickname, email, xp, nivel, avatar)
  /// 'rankings/' = dados de jogo (trofeus, vitorias, precisão, título)
  Future<Usuario?> buscarUsuario(String uid) async {
    debugPrint('[FirestoreService] buscarUsuario: uid=$uid');

    final userDoc = await _db.collection('usuarios').doc(uid).get();
    debugPrint('[FirestoreService] buscarUsuario usuarios exists=${userDoc.exists}');

    final rankDoc = await _db.collection('rankings').doc(uid).get();
    debugPrint('[FirestoreService] buscarUsuario rankings exists=${rankDoc.exists}');

    if (!userDoc.exists && !rankDoc.exists) {
      return null;
    }

    // Dados do perfil (usuarios/)
    final nickname = userDoc.exists
        ? (userDoc.data()!['nickname'] ?? 'JOGADOR')
        : (rankDoc.exists ? (rankDoc.data()!['nickname'] ?? 'JOGADOR') : 'JOGADOR');
    final email = userDoc.exists ? (userDoc.data()!['email'] ?? '') : '';
    final xp = userDoc.exists ? (userDoc.data()!['xp'] ?? 0) : 0;
    final avatarId = userDoc.exists ? (userDoc.data()!['avatarId'] ?? 0) : 0;
    final avatarsDesbloqueados = userDoc.exists
        ? (userDoc.data()!['avatarsDesbloqueados'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [0]
        : [0];
    final List<String> conquistasDesbloqueadas = userDoc.exists
        ? (userDoc.data()!['conquistasDesbloqueadas'] as List<dynamic>?)?.map((e) => e as String).toList() ?? []
        : [];

    final nivelInfo = Usuario.calcularNivel(xp);

    // Dados de jogo (rankings/)
    if (rankDoc.exists && rankDoc.data() != null) {
      final r = rankDoc.data()!;
      return Usuario(
        uid: uid,
        nickname: nickname,
        email: email,
        titulo: userDoc.exists ? (userDoc.data()!['titulo'] ?? nivelInfo.nome) : nivelInfo.nome,
        nivel: nivelInfo.nivel,
        nivelNome: nivelInfo.nome,
        nivelProgresso: nivelInfo.progresso,
        trofeus: r['trofeus'] ?? 0,
        vitorias: r['vitorias'] ?? 0,
        precisaoMedia: (r['precisaoMedia'] as num?)?.toDouble() ?? 0.0,
        xp: xp,
        avatarId: avatarId,
        avatarsDesbloqueados: avatarsDesbloqueados,
        titulosDesbloqueados: userDoc.exists
            ? (userDoc.data()!['titulosDesbloqueados'] as List<dynamic>?)?.map((e) => e as String).toList() ?? ['ROOKIE']
            : ['ROOKIE'],
        conquistasDesbloqueadas: conquistasDesbloqueadas,
      );
    }

    // Fallback: perfil sem dados de jogo
    return Usuario(
      uid: uid,
      nickname: nickname,
      email: email,
      titulo: userDoc.exists ? (userDoc.data()!['titulo'] ?? nivelInfo.nome) : nivelInfo.nome,
      nivel: nivelInfo.nivel,
      nivelNome: nivelInfo.nome,
      nivelProgresso: nivelInfo.progresso,
      trofeus: 0,
      vitorias: 0,
      precisaoMedia: 0.0,
      xp: xp,
      avatarId: avatarId,
      avatarsDesbloqueados: avatarsDesbloqueados,
      titulosDesbloqueados: userDoc.exists
          ? (userDoc.data()!['titulosDesbloqueados'] as List<dynamic>?)?.map((e) => e as String).toList() ?? ['ROOKIE']
          : ['ROOKIE'],
      conquistasDesbloqueadas: conquistasDesbloqueadas,
    );
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

  /// Stream em tempo real do ranking semanal.
  Stream<QuerySnapshot> streamRankingSemanal({int limit = 100}) {
    final semana = _semanaAtual();
    return _db
        .collection('rankings')
        .where('periodoSemana', isEqualTo: semana)
        .orderBy('trofeus', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Atualiza dados de jogo em 'rankings/' e perfil em 'usuarios/'.
  Future<void> atualizarRanking(Usuario usuario) async {
    // Dados de jogo → rankings/
    await _db.collection('rankings').doc(usuario.uid).set({
      'uid': usuario.uid,
      'nickname': usuario.nickname,
      'titulo': usuario.titulo,
      'trofeus': usuario.trofeus,
      'vitorias': usuario.vitorias,
      'precisaoMedia': usuario.precisaoMedia,
      'periodoSemana': _semanaAtual(),
    });

    // Perfil (xp, nivel, avatar, titulo) → usuarios/
    await _db.collection('usuarios').doc(usuario.uid).set({
      'xp': usuario.xp,
      'nivel': usuario.nivel,
      'nivelNome': usuario.nivelNome,
      'nivelProgresso': usuario.nivelProgresso,
      'avatarId': usuario.avatarId,
      'avatarsDesbloqueados': usuario.avatarsDesbloqueados,
      'titulo': usuario.titulo,
      'titulosDesbloqueados': usuario.titulosDesbloqueados,
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

  // ==================== AMIGOS ====================

  /// Envia pedido de amizade (adiciona UID na lista de amigos de ambos).
  Future<bool> enviarPedidoAmizade(String meuUid, String codigoAmigo) async {
    debugPrint('[FirestoreService] enviarPedidoAmizade: $meuUid → $codigoAmigo');

    if (meuUid == codigoAmigo) return false;

    final userDoc = await _db.collection('usuarios').doc(codigoAmigo).get();
    if (!userDoc.exists) return false;

    final myDoc = await _db.collection('usuarios').doc(meuUid).get();
    final myFriends = (myDoc.data()?['amigos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];

    if (myFriends.contains(codigoAmigo)) return false;

    myFriends.add(codigoAmigo);
    await _db.collection('usuarios').doc(meuUid).set({
      'amigos': myFriends,
    }, SetOptions(merge: true));

    final otherFriends = (userDoc.data()?['amigos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
    if (!otherFriends.contains(meuUid)) {
      otherFriends.add(meuUid);
      await _db.collection('usuarios').doc(codigoAmigo).set({
        'amigos': otherFriends,
      }, SetOptions(merge: true));
    }

    debugPrint('[FirestoreService] enviarPedidoAmizade OK');
    return true;
  }

  /// Remove um amigo.
  Future<void> removerAmigo(String meuUid, String uidAmigo) async {
    final myDoc = await _db.collection('usuarios').doc(meuUid).get();
    final myFriends = (myDoc.data()?['amigos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];

    myFriends.remove(uidAmigo);
    await _db.collection('usuarios').doc(meuUid).set({
      'amigos': myFriends,
    }, SetOptions(merge: true));

    final otherDoc = await _db.collection('usuarios').doc(uidAmigo).get();
    final otherFriends = (otherDoc.data()?['amigos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];

    otherFriends.remove(meuUid);
    await _db.collection('usuarios').doc(uidAmigo).set({
      'amigos': otherFriends,
    }, SetOptions(merge: true));
  }

  /// Retorna lista de UIDs de amigos do usuário.
  Future<List<String>> buscarAmigos(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    return (doc.data()?['amigos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
  }

  /// Stream em tempo real do ranking dos amigos.
  Stream<QuerySnapshot> streamRankingAmigos(List<String> uidsAmigos, {int limit = 100}) {
    if (uidsAmigos.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('rankings')
        .where('uid', whereIn: uidsAmigos)
        .orderBy('trofeus', descending: true)
        .limit(limit)
        .snapshots();
  }
}
