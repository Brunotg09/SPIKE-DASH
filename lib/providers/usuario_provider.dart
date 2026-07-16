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
    if (_usuario != null) return;

    final nickname = _hive.cachedNickname;
    final uid = _hive.cachedUid;
    if (nickname != null && uid != null) {
      final xp = _hive.cachedXp;
      final nivelInfo = Usuario.calcularNivel(xp);
      _usuario = Usuario(
        uid: uid,
        nickname: nickname,
        email: '',
        titulo: _hive.cachedTitulo ?? nivelInfo.nome,
        nivel: nivelInfo.nivel,
        nivelNome: nivelInfo.nome,
        nivelProgresso: nivelInfo.progresso,
        trofeus: _hive.cachedTrofeus,
        vitorias: _hive.cachedVitorias,
        precisaoMedia: _hive.cachedPrecisaoMedia,
        xp: xp,
        avatarId: _hive.cachedAvatarId,
        avatarsDesbloqueados: _hive.cachedAvatarsDesbloqueados,
        titulosDesbloqueados: _hive.cachedTitulosDesbloqueados,
        conquistasDesbloqueadas: _hive.cachedConquistasDesbloqueadas,
      );
      notifyListeners();
    }
  }

  /// Força reload do Hive (ex: após login ou quando necessário).
  void recarregarDoCache() {
    final nickname = _hive.cachedNickname;
    final uid = _hive.cachedUid;
    if (nickname != null && uid != null) {
      final xp = _hive.cachedXp;
      final nivelInfo = Usuario.calcularNivel(xp);
      _usuario = Usuario(
        uid: uid,
        nickname: nickname,
        email: '',
        titulo: _hive.cachedTitulo ?? nivelInfo.nome,
        nivel: nivelInfo.nivel,
        nivelNome: nivelInfo.nome,
        nivelProgresso: nivelInfo.progresso,
        trofeus: _hive.cachedTrofeus,
        vitorias: _hive.cachedVitorias,
        precisaoMedia: _hive.cachedPrecisaoMedia,
        xp: xp,
        avatarId: _hive.cachedAvatarId,
        avatarsDesbloqueados: _hive.cachedAvatarsDesbloqueados,
        titulosDesbloqueados: _hive.cachedTitulosDesbloqueados,
        conquistasDesbloqueadas: _hive.cachedConquistasDesbloqueadas,
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
      xp: _usuario!.xp,
      avatarId: _usuario!.avatarId,
      avatarsDesbloqueados: _usuario!.avatarsDesbloqueados,
      titulosDesbloqueados: _usuario!.titulosDesbloqueados,
      conquistasDesbloqueadas: _usuario!.conquistasDesbloqueadas,
    );
  }

  /// Recalcula nível, título e avatar baseado no XP.
  void _recalcularNivel() {
    if (_usuario == null) return;

    final nivelInfo = Usuario.calcularNivel(_usuario!.xp);
    final nivelAnterior = _usuario!.nivel;

    _usuario!.nivel = nivelInfo.nivel;
    _usuario!.nivelNome = nivelInfo.nome;
    _usuario!.nivelProgresso = nivelInfo.progresso;

    // Desbloquear título do novo nível
    final tituloNovo = Usuario.tituloDoNivel(nivelInfo.nivel);
    if (!_usuario!.titulosDesbloqueados.contains(tituloNovo)) {
      _usuario!.titulosDesbloqueados = [
        ..._usuario!.titulosDesbloqueados,
        tituloNovo,
      ];
    }
    _usuario!.titulo = tituloNovo;

    // Desbloquear avatar do novo nível
    final avatarNovo = Usuario.avatarDesbloqueado(nivelInfo.nivel);
    if (!_usuario!.avatarsDesbloqueados.contains(avatarNovo)) {
      _usuario!.avatarsDesbloqueados = [
        ..._usuario!.avatarsDesbloqueados,
        avatarNovo,
      ];
      _usuario!.avatarId = avatarNovo;
    }

    if (nivelInfo.nivel != nivelAnterior) {
      debugPrint('[UsuarioProvider] Nível-up! $nivelAnterior → ${nivelInfo.nivel} (${nivelInfo.nome})');
    }
  }

  /// Adiciona troféus ao jogador e sincroniza com Firestore.
  Future<void> adicionarTrofeus(int quantidade) async {
    if (_usuario == null) {
      debugPrint('[UsuarioProvider] adicionarTrofeus: _usuario é NULL! abortando.');
      return;
    }
    debugPrint('[UsuarioProvider] adicionarTrofeus: +$quantidade → total=${_usuario!.trofeus + quantidade}');
    _usuario!.trofeus += quantidade;

    notifyListeners();

    await _salvarNoHive();
    debugPrint('[UsuarioProvider] Hive salvo. trofeus=${_usuario!.trofeus}');

    try {
      await _firestore.atualizarRanking(_usuario!);
      debugPrint('[UsuarioProvider] Firestore atualizado com sucesso.');
    } catch (e) {
      debugPrint('[UsuarioProvider] ERRO Firestore: $e');
    }
  }

  /// Adiciona XP ao jogador e sincroniza com Firestore.
  Future<void> adicionarXp(int quantidade) async {
    if (_usuario == null) return;
    debugPrint('[UsuarioProvider] adicionarXp: +$quantidade → total=${_usuario!.xp + quantidade}');
    _usuario!.xp += quantidade;

    _recalcularNivel();

    notifyListeners();

    await _salvarNoHive();

    try {
      await _firestore.atualizarRanking(_usuario!);
    } catch (e) {
      debugPrint('[UsuarioProvider] ERRO Firestore (xp): $e');
    }
  }

  /// Verifica e desbloqueia conquistas após uma partida.
  Future<List<String>> verificarConquistas({
    int? comboMaximo,
    double? precisaoPartida,
    int? totalPartidas,
  }) async {
    if (_usuario == null) return [];

    final novas = _usuario!.verificarConquistas(
      comboMaximo: comboMaximo,
      precisaoPartida: precisaoPartida,
      totalPartidas: totalPartidas,
    );

    if (novas.isNotEmpty) {
      debugPrint('[UsuarioProvider] Conquistas desbloqueadas: $novas');
      notifyListeners();
      await _salvarNoHive();

      try {
        await _firestore.salvarUsuario(_usuario!);
      } catch (e) {
        debugPrint('[UsuarioProvider] ERRO Firestore (conquistas): $e');
      }
    }

    return novas;
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

  /// Atualiza avatar do jogador.
  Future<void> setAvatar(int avatarId) async {
    if (_usuario == null) return;
    if (!_usuario!.avatarsDesbloqueados.contains(avatarId)) return;
    _usuario!.avatarId = avatarId;
    notifyListeners();
    await _salvarNoHive();
    try {
      await _firestore.atualizarRanking(_usuario!);
    } catch (e) {
      debugPrint('[UsuarioProvider] ERRO Firestore (avatar): $e');
    }
  }

  /// Atualiza título do jogador.
  Future<void> setTitulo(String titulo) async {
    if (_usuario == null) return;
    if (!_usuario!.titulosDesbloqueados.contains(titulo)) return;
    _usuario!.titulo = titulo;
    notifyListeners();
    await _salvarNoHive();
    try {
      await _firestore.atualizarRanking(_usuario!);
    } catch (e) {
      debugPrint('[UsuarioProvider] ERRO Firestore (titulo): $e');
    }
  }
}
