import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';

/// Provider que gerencia os dados do jogador logado.
/// Carrega do cache Hive na inicialização (instantâneo) e
/// sincroniza com o Firestore quando online.
class UsuarioProvider extends ChangeNotifier {
  final HiveService _hive = HiveService();
  final FirestoreService _firestore = FirestoreService();

  Usuario? _usuario;
  bool _carregando = false;

  Usuario? get usuario => _usuario;
  bool get carregando => _carregando;

  /// Carrega dados do cache Hive apenas se _usuario ainda não existe.
  /// Se já existe (logado), NÃO sobrescreve — preserva dados em memória.
  void carregarDoCache() {
    if (_usuario != null) return; // Já tem dados em memória, não sobrescreve

    final nickname = _hive.cachedNickname;
    final uid = _hive.cachedUid;
    if (nickname != null && uid != null) {
      _usuario = Usuario(
        uid: uid,
        nickname: nickname,
        email: '',
        titulo: _hive.cachedTitulo ?? 'ROOKIE',
        nivel: _hive.cachedNivel ?? 1,
        trofeus: _hive.cachedTrofeus,
        vitorias: _hive.cachedVitorias,
        precisaoMedia: _hive.cachedPrecisaoMedia,
      );
      notifyListeners();
    }
  }

  /// Força reload do Hive (ex: após login ou quando necessário).
  void recarregarDoCache() {
    final nickname = _hive.cachedNickname;
    final uid = _hive.cachedUid;
    if (nickname != null && uid != null) {
      _usuario = Usuario(
        uid: uid,
        nickname: nickname,
        email: '',
        titulo: _hive.cachedTitulo ?? 'ROOKIE',
        nivel: _hive.cachedNivel ?? 1,
        trofeus: _hive.cachedTrofeus,
        vitorias: _hive.cachedVitorias,
        precisaoMedia: _hive.cachedPrecisaoMedia,
      );
      notifyListeners();
    }
  }

  /// Define o usuário (vem do AuthProvider após login).
  void setUsuario(Usuario usuario) {
    debugPrint('[UsuarioProvider] setUsuario: uid=${usuario.uid}, nick=${usuario.nickname}, trofeus=${usuario.trofeus}, vitorias=${usuario.vitorias}');
    _usuario = usuario;
    notifyListeners();
  }

  /// Salva os dados atuais do usuário no Hive (síncrono).
  Future<void> _salvarNoHive() async {
    if (_usuario == null) return;
    await _hive.salvarCachePerfil(
      uid: _usuario!.uid,
      nickname: _usuario!.nickname,
      titulo: _usuario!.titulo,
      nivel: _usuario!.nivel,
      trofeus: _usuario!.trofeus,
      vitorias: _usuario!.vitorias,
      precisaoMedia: _usuario!.precisaoMedia,
    );
  }

  /// Adiciona troféus ao jogador e sincroniza com Firestore.
  Future<void> adicionarTrofeus(int quantidade) async {
    if (_usuario == null) {
      debugPrint('[UsuarioProvider] adicionarTrofeus: _usuario é NULL! abortando.');
      return;
    }
    debugPrint('[UsuarioProvider] adicionarTrofeus: +$quantidade → total=${_usuario!.trofeus + quantidade}');
    _usuario!.trofeus += quantidade;

    // Notifica UI IMEDIATAMENTE (antes de qualquer await)
    notifyListeners();

    // Salva no Hive (rápido, local)
    await _salvarNoHive();
    debugPrint('[UsuarioProvider] Hive salvo. trofeus=${_usuario!.trofeus}');

    // Firestore em background (pode falhar)
    try {
      await _firestore.atualizarRanking(_usuario!);
      debugPrint('[UsuarioProvider] Firestore atualizado com sucesso.');
    } catch (e) {
      debugPrint('[UsuarioProvider] ERRO Firestore: $e');
    }
  }

  /// Incrementa vitórias do jogador e sincroniza.
  Future<void> adicionarVitoria() async {
    if (_usuario == null) return;
    _usuario!.vitorias++;
    debugPrint('[UsuarioProvider] adicionarVitoria: total=${_usuario!.vitorias}');
    notifyListeners();
    await _salvarNoHive();

    try {
      await _firestore.atualizarRanking(_usuario!);
    } catch (e) {
      debugPrint('[UsuarioProvider] ERRO Firestore (vitoria): $e');
    }
  }

  /// Atualiza precisão média (média ponderada) e sincroniza.
  Future<void> atualizarPrecisao(double novaPrecisao) async {
    if (_usuario == null) return;
    _usuario!.precisaoMedia =
        (_usuario!.precisaoMedia + novaPrecisao) / 2;
    debugPrint('[UsuarioProvider] atualizarPrecisao: nova=${_usuario!.precisaoMedia}');
    notifyListeners();
    await _salvarNoHive();

    try {
      await _firestore.atualizarRanking(_usuario!);
    } catch (e) {
      debugPrint('[UsuarioProvider] ERRO Firestore (precisao): $e');
    }
  }
}
