import 'package:hive/hive.dart';

part 'usuario.g.dart';

/// Modelo de dados do jogador.
/// Armazenado como cache no Hive e serializado como JSON para o Firestore.
@HiveType(typeId: 0)
class Usuario extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  String nickname;

  @HiveField(2)
  String email;

  @HiveField(3)
  String titulo;

  @HiveField(4)
  int nivel;

  @HiveField(5)
  String nivelNome;

  @HiveField(6)
  double nivelProgresso;

  @HiveField(7)
  int trofeus;

  @HiveField(8)
  int vitorias;

  @HiveField(9)
  double precisaoMedia;

  @HiveField(10)
  int xp;

  @HiveField(11)
  int avatarId;

  @HiveField(12)
  List<int> avatarsDesbloqueados;

  @HiveField(13)
  List<String> titulosDesbloqueados;

  Usuario({
    required this.uid,
    required this.nickname,
    required this.email,
    this.titulo = 'ROOKIE',
    this.nivel = 1,
    this.nivelNome = 'ROOKIE',
    this.nivelProgresso = 0.0,
    this.trofeus = 0,
    this.vitorias = 0,
    this.precisaoMedia = 0.0,
    this.xp = 0,
    this.avatarId = 0,
    this.avatarsDesbloqueados = const [0],
    this.titulosDesbloqueados = const ['ROOKIE'],
  });

  /// Tabela de níveis: XP necessário para cada nível.
  static int xpParaNivel(int nivel) {
    if (nivel <= 1) return 0;
    return (nivel - 1) * 150;
  }

  /// Nome do nível baseado no nível numérico.
  static String nomeDoNivel(int nivel) {
    if (nivel >= 16) return 'DIVINO';
    if (nivel >= 13) return 'LENDA';
    if (nivel >= 10) return 'MESTRE';
    if (nivel >= 7) return 'EXPERT';
    if (nivel >= 4) return 'VETERANO';
    return 'ROOKIE';
  }

  /// Título desbloqueável baseado no nível.
  static String tituloDoNivel(int nivel) {
    if (nivel >= 16) return 'DIVINO';
    if (nivel >= 13) return 'LENDA';
    if (nivel >= 10) return 'MESTRE';
    if (nivel >= 7) return 'EXPERT';
    if (nivel >= 4) return 'VETERANO';
    return 'ROOKIE';
  }

  /// ID do avatar desbloqueável baseado no nível.
  static int avatarDesbloqueado(int nivel) {
    if (nivel >= 16) return 6;
    if (nivel >= 13) return 5;
    if (nivel >= 10) return 4;
    if (nivel >= 7) return 3;
    if (nivel >= 5) return 2;
    if (nivel >= 3) return 1;
    return 0;
  }

  /// Calcula nível e progresso baseado no XP.
  static ({int nivel, String nome, double progresso}) calcularNivel(int xp) {
    int nivel = 1;
    while (nivel < 20 && xpParaNivel(nivel + 1) <= xp) {
      nivel++;
    }
    final xpAtual = xpParaNivel(nivel);
    final xpProximo = nivel < 20 ? xpParaNivel(nivel + 1) : xpAtual + 150;
    final progresso = ((xp - xpAtual) / (xpProximo - xpAtual)).clamp(0.0, 1.0);
    return (nivel: nivel, nome: nomeDoNivel(nivel), progresso: progresso);
  }

  /// Serialização para Firestore/JSON.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      uid: json['uid'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String,
      titulo: json['titulo'] as String? ?? 'ROOKIE',
      nivel: json['nivel'] as int? ?? 1,
      nivelNome: json['nivelNome'] as String? ?? 'ROOKIE',
      nivelProgresso: (json['nivelProgresso'] as num?)?.toDouble() ?? 0.0,
      trofeus: json['trofeus'] as int? ?? 0,
      vitorias: json['vitorias'] as int? ?? 0,
      precisaoMedia: (json['precisaoMedia'] as num?)?.toDouble() ?? 0.0,
      xp: json['xp'] as int? ?? 0,
      avatarId: json['avatarId'] as int? ?? 0,
      avatarsDesbloqueados: (json['avatarsDesbloqueados'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [0],
      titulosDesbloqueados: (json['titulosDesbloqueados'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['ROOKIE'],
    );
  }

  /// Deserialização para Firestore/JSON.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'email': email,
      'titulo': titulo,
      'nivel': nivel,
      'nivelNome': nivelNome,
      'nivelProgresso': nivelProgresso,
      'trofeus': trofeus,
      'vitorias': vitorias,
      'precisaoMedia': precisaoMedia,
      'xp': xp,
      'avatarId': avatarId,
      'avatarsDesbloqueados': avatarsDesbloqueados,
      'titulosDesbloqueados': titulosDesbloqueados,
    };
  }

  /// Cópia com alterações parciais.
  Usuario copyWith({
    String? uid,
    String? nickname,
    String? email,
    String? titulo,
    int? nivel,
    String? nivelNome,
    double? nivelProgresso,
    int? trofeus,
    int? vitorias,
    double? precisaoMedia,
    int? xp,
    int? avatarId,
    List<int>? avatarsDesbloqueados,
    List<String>? titulosDesbloqueados,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      titulo: titulo ?? this.titulo,
      nivel: nivel ?? this.nivel,
      nivelNome: nivelNome ?? this.nivelNome,
      nivelProgresso: nivelProgresso ?? this.nivelProgresso,
      trofeus: trofeus ?? this.trofeus,
      vitorias: vitorias ?? this.vitorias,
      precisaoMedia: precisaoMedia ?? this.precisaoMedia,
      xp: xp ?? this.xp,
      avatarId: avatarId ?? this.avatarId,
      avatarsDesbloqueados: avatarsDesbloqueados ?? this.avatarsDesbloqueados,
      titulosDesbloqueados:
          titulosDesbloqueados ?? this.titulosDesbloqueados,
    );
  }
}
