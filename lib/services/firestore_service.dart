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
      'codigo': usuario.uid.substring(0, 5).toUpperCase(),
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
      'avatarId': usuario.avatarId,
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

  /// Envia pedido de amizade (adiciona UID em 'pedidosRecebidos' do destinatário).
  Future<bool> enviarPedidoAmizade(String meuUid, String codigoAmigo) async {
    debugPrint('[FirestoreService] enviarPedidoAmizade: $meuUid → $codigoAmigo');

    final uidAmigo = await buscarUidPorCodigo(codigoAmigo);
    if (uidAmigo == null) return false;
    if (meuUid == uidAmigo) return false;

    final userDoc = await _db.collection('usuarios').doc(uidAmigo).get();
    if (!userDoc.exists) return false;

    final myDoc = await _db.collection('usuarios').doc(meuUid).get();
    final myFriends = (myDoc.data()?['amigos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
    if (myFriends.contains(uidAmigo)) return false;

    final mySent = (myDoc.data()?['pedidosEnviados'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
    if (mySent.contains(uidAmigo)) return false;

    final otherReceived = (userDoc.data()?['pedidosRecebidos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
    if (otherReceived.contains(meuUid)) return false;

    otherReceived.add(meuUid);
    await _db.collection('usuarios').doc(uidAmigo).set({
      'pedidosRecebidos': otherReceived,
    }, SetOptions(merge: true));

    mySent.add(uidAmigo);
    await _db.collection('usuarios').doc(meuUid).set({
      'pedidosEnviados': mySent,
    }, SetOptions(merge: true));

    debugPrint('[FirestoreService] enviarPedidoAmizade OK');
    return true;
  }

  /// Aceita pedido de amizade: adiciona em 'amigos' de ambos e remove de 'pedidosRecebidos'.
  Future<bool> aceitarPedido(String meuUid, String uidRemetente) async {
    debugPrint('[FirestoreService] aceitarPedido: $meuUid ← $uidRemetente');

    final myDoc = await _db.collection('usuarios').doc(meuUid).get();
    final myFriends = (myDoc.data()?['amigos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
    final myReceived = (myDoc.data()?['pedidosRecebidos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];

    if (!myReceived.contains(uidRemetente)) return false;

    myFriends.add(uidRemetente);
    myReceived.remove(uidRemetente);
    await _db.collection('usuarios').doc(meuUid).set({
      'amigos': myFriends,
      'pedidosRecebidos': myReceived,
    }, SetOptions(merge: true));

    final otherDoc = await _db.collection('usuarios').doc(uidRemetente).get();
    final otherFriends = (otherDoc.data()?['amigos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
    final otherSent = (otherDoc.data()?['pedidosEnviados'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];

    otherFriends.add(meuUid);
    otherSent.remove(meuUid);
    await _db.collection('usuarios').doc(uidRemetente).set({
      'amigos': otherFriends,
      'pedidosEnviados': otherSent,
    }, SetOptions(merge: true));

    // Garante que ambos têm documento em 'rankings/' para o stream de amigos funcionar
    await _garantirRankingDocument(meuUid, myDoc);
    await _garantirRankingDocument(uidRemetente, otherDoc);

    debugPrint('[FirestoreService] aceitarPedido OK');
    return true;
  }

  /// Garante que o usuário tem documento em 'rankings/'.
  Future<void> _garantirRankingDocument(String uid, DocumentSnapshot? userDoc) async {
    final rankDoc = await _db.collection('rankings').doc(uid).get();
    if (!rankDoc.exists) {
      final data = userDoc?.data() as Map<String, dynamic>?;
      final nickname = data?['nickname'] ?? 'JOGADOR';
      final avatarId = data?['avatarId'] ?? 0;
      await _db.collection('rankings').doc(uid).set({
        'uid': uid,
        'nickname': nickname,
        'titulo': 'ROOKIE',
        'avatarId': avatarId,
        'trofeus': 0,
        'vitorias': 0,
        'precisaoMedia': 0.0,
        'periodoSemana': _semanaAtual(),
      });
    }
  }

  /// Recusa pedido de amizade: remove de 'pedidosRecebidos' e 'pedidosEnviados'.
  Future<void> recusarPedido(String meuUid, String uidRemetente) async {
    debugPrint('[FirestoreService] recusarPedido: $meuUid ← $uidRemetente');

    final myDoc = await _db.collection('usuarios').doc(meuUid).get();
    final myReceived = (myDoc.data()?['pedidosRecebidos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
    myReceived.remove(uidRemetente);
    await _db.collection('usuarios').doc(meuUid).set({
      'pedidosRecebidos': myReceived,
    }, SetOptions(merge: true));

    final otherDoc = await _db.collection('usuarios').doc(uidRemetente).get();
    final otherSent = (otherDoc.data()?['pedidosEnviados'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
    otherSent.remove(meuUid);
    await _db.collection('usuarios').doc(uidRemetente).set({
      'pedidosEnviados': otherSent,
    }, SetOptions(merge: true));
  }

  /// Retorna lista de UIDs de pedidos recebidos pendentes.
  Future<List<String>> buscarPedidosRecebidos(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    return (doc.data()?['pedidosRecebidos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
  }

  /// Retorna lista de UIDs de pedidos enviados pendentes.
  Future<List<String>> buscarPedidosEnviados(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    return (doc.data()?['pedidosEnviados'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
  }

  /// Retorna dados de múltiplos usuários (para exibir pedidos pendentes).
  Future<List<Map<String, dynamic>>> buscarDadosUsuarios(List<String> uids) async {
    if (uids.isEmpty) return [];
    final resultados = <Map<String, dynamic>>[];
    for (final uid in uids) {
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        resultados.add({
          'uid': uid,
          'nickname': doc.data()!['nickname'] ?? 'JOGADOR',
          'titulo': doc.data()!['titulo'] ?? 'ROOKIE',
        });
      }
    }
    return resultados;
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

  /// Busca usuário pelo código curto (5 primeiros caracteres do UID).
  /// Retorna o UID completo do usuário encontrado ou null.
  Future<String?> buscarUidPorCodigo(String codigo) async {
    final snapshot = await _db
        .collection('usuarios')
        .where('codigo', isEqualTo: codigo.toUpperCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }

  /// Stream em tempo real do ranking dos amigos.
  Stream<QuerySnapshot> streamRankingAmigos(List<String> uidsAmigos, {int limit = 100}) {
    if (uidsAmigos.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('rankings')
        .where('uid', whereIn: uidsAmigos)
        .snapshots();
  }

  /// Migração: adiciona campos faltantes em documentos existentes.
  Future<int> migrarCodigos() async {
    final snapshot = await _db.collection('usuarios').get();
    int atualizados = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};
      if (data['codigo'] == null || (data['codigo'] as String).isEmpty) {
        updates['codigo'] = doc.id.substring(0, 5).toUpperCase();
      }
      if (updates.isNotEmpty) {
        await _db.collection('usuarios').doc(doc.id).update(updates);
        atualizados++;
      }
    }

    // Migra rankings: adiciona avatarId se não existe
    final rankSnapshot = await _db.collection('rankings').get();
    for (final doc in rankSnapshot.docs) {
      final data = doc.data();
      if (data['avatarId'] == null) {
        final userDoc = await _db.collection('usuarios').doc(doc.id).get();
        final avatarId = (userDoc.data()?['avatarId'] ?? 0) as int;
        await _db.collection('rankings').doc(doc.id).update({'avatarId': avatarId});
      }
    }

    return atualizados;
  }
}
