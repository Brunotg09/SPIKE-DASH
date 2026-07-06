import 'package:hive_flutter/hive_flutter.dart';

/// Serviço de persistência local usando Hive (NoSQL).
/// Padrão Singleton para garantir uma única instância.
/// Responsável por:
/// - Preferências do usuário (Dark Mode, volumes de som)
/// - Cache do perfil do jogador (inicialização instantânea da UI)
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String _boxConfiguracoes = 'configuracoes';
  static const String _boxPerfilCache = 'perfil_cache';

  /// Inicializa as boxes do Hive (chamado no main.dart).
  Future<void> init() async {
    await Hive.openBox(_boxConfiguracoes);
    await Hive.openBox(_boxPerfilCache);
  }

  // ==================== CONFIGURACOES ====================

  bool get darkMode {
    final box = Hive.box(_boxConfiguracoes);
    return box.get('darkMode', defaultValue: true);
  }

  set darkMode(bool value) {
    Hive.box(_boxConfiguracoes).put('darkMode', value);
  }

  double get volumeMusic {
    final box = Hive.box(_boxConfiguracoes);
    return box.get('volumeMusic', defaultValue: 0.7);
  }

  set volumeMusic(double value) {
    Hive.box(_boxConfiguracoes).put('volumeMusic', value);
  }

  double get volumeSfx {
    final box = Hive.box(_boxConfiguracoes);
    return box.get('volumeSfx', defaultValue: 1.0);
  }

  set volumeSfx(double value) {
    Hive.box(_boxConfiguracoes).put('volumeSfx', value);
  }

  // ==================== PERFIL CACHE ====================

  String? get cachedNickname {
    return Hive.box(_boxPerfilCache).get('nickname');
  }

  String? get cachedUid {
    return Hive.box(_boxPerfilCache).get('uid');
  }

  String? get cachedTitulo {
    return Hive.box(_boxPerfilCache).get('titulo');
  }

  int? get cachedNivel {
    return Hive.box(_boxPerfilCache).get('nivel');
  }

  int get cachedTrofeus {
    return Hive.box(_boxPerfilCache).get('trofeus', defaultValue: 0);
  }

  int get cachedVitorias {
    return Hive.box(_boxPerfilCache).get('vitorias', defaultValue: 0);
  }

  double get cachedPrecisaoMedia {
    return Hive.box(_boxPerfilCache).get('precisaoMedia', defaultValue: 0.0);
  }

  /// Salva o cache do perfil do usuário logado.
  Future<void> salvarCachePerfil({
    required String uid,
    required String nickname,
    String titulo = 'ROOKIE',
    int nivel = 1,
    int trofeus = 0,
    int vitorias = 0,
    double precisaoMedia = 0.0,
  }) async {
    final box = Hive.box(_boxPerfilCache);
    await box.put('uid', uid);
    await box.put('nickname', nickname);
    await box.put('titulo', titulo);
    await box.put('nivel', nivel);
    await box.put('trofeus', trofeus);
    await box.put('vitorias', vitorias);
    await box.put('precisaoMedia', precisaoMedia);
  }

  /// Limpa o cache do perfil (logout).
  Future<void> limparCachePerfil() async {
    await Hive.box(_boxPerfilCache).clear();
  }
}
