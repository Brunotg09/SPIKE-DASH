import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../models/usuario.dart';

/// Provider responsável pela autenticação do usuário.
/// Conecta Firebase Auth com cache Hive e Firestore.
class AuthProvider extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();
  final HiveService _hive = HiveService();

  fb.User? _user;
  Usuario? _usuario;
  bool _carregando = false;
  String? _erro;

  fb.User? get user => _user;
  Usuario? get usuario => _usuario;
  bool get carregando => _carregando;
  bool get isLoggedIn => _user != null;
  String? get erro => _erro;

  /// Login com e-mail e senha via Firebase Auth.
  Future<bool> login(String email, String senha) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      debugPrint('[AuthProvider] login: $email');
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      _user = result.user;
      debugPrint('[AuthProvider] login OK: uid=${_user!.uid}');
      await _carregarDadosUsuario();
      debugPrint('[AuthProvider] _carregarDadosUsuario OK: trofeus=${_usuario?.trofeus}, vitorias=${_usuario?.vitorias}');
      _carregando = false;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthProvider] login ERRO: ${e.message}');
      _erro = e.message ?? 'Erro ao fazer login';
      _carregando = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] login ERRO inesperado: $e');
      _erro = 'Erro inesperado ao fazer login';
      _carregando = false;
      notifyListeners();
      return false;
    }
  }

  /// Registro de nova conta via Firebase Auth.
  Future<bool> registrar(String email, String senha, String nickname) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      debugPrint('[AuthProvider] registrar: $email / $nickname');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      _user = result.user;
      debugPrint('[AuthProvider] Auth OK: uid=${_user!.uid}');

      final novoUsuario = Usuario(
        uid: _user!.uid,
        nickname: nickname,
        email: email,
      );
      await _firestore.salvarUsuario(novoUsuario);
      debugPrint('[AuthProvider] Firestore salvarUsuario OK');
      _usuario = novoUsuario;

      await _hive.salvarCachePerfil(
        uid: _user!.uid,
        nickname: nickname,
        titulo: novoUsuario.titulo,
        nivel: novoUsuario.nivel,
        trofeus: novoUsuario.trofeus,
        vitorias: novoUsuario.vitorias,
        precisaoMedia: novoUsuario.precisaoMedia,
      );
      debugPrint('[AuthProvider] Hive cache salvo OK');

      _carregando = false;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthProvider] registrar ERRO: ${e.message}');
      _erro = e.message ?? 'Erro ao criar conta';
      _carregando = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] registrar ERRO inesperado: $e');
      _erro = 'Erro inesperado ao criar conta';
      _carregando = false;
      notifyListeners();
      return false;
    }
  }

  /// Carrega dados do Firestore; se não existir, usa cache Hive.
  Future<void> _carregarDadosUsuario() async {
    if (_user == null) return;

    _usuario = await _firestore.buscarUsuario(_user!.uid);

    if (_usuario != null) {
      await _hive.salvarCachePerfil(
        uid: _usuario!.uid,
        nickname: _usuario!.nickname,
        titulo: _usuario!.titulo,
        nivel: _usuario!.nivel,
        trofeus: _usuario!.trofeus,
        vitorias: _usuario!.vitorias,
        precisaoMedia: _usuario!.precisaoMedia,
      );
    } else {
      // Usuário existe no Auth mas não no Firestore — cria localmente
      final nickname = _hive.cachedNickname ?? 'JOGADOR';
      _usuario = Usuario(
        uid: _user!.uid,
        nickname: nickname,
        email: _user!.email ?? '',
      );
      // Salva no Firestore
      try {
        await _firestore.salvarUsuario(_usuario!);
        await _firestore.atualizarRanking(_usuario!);
      } catch (_) {
        // Firestore indisponível
      }
      // Salva cache local
      await _hive.salvarCachePerfil(
        uid: _usuario!.uid,
        nickname: _usuario!.nickname,
      );
    }

    notifyListeners();
  }

  /// Logout: limpa Firebase Auth, cache Hive e estado.
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _usuario = null;
    await _hive.limparCachePerfil();
    notifyListeners();
  }
}
