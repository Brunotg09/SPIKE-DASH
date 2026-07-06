import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/partida.dart';

/// Serviço de persistência local usando SQLite (banco relacional).
/// Padrão Singleton para garantir uma única instância do banco.
class DatabaseLocal {
  static final DatabaseLocal _instance = DatabaseLocal._internal();
  factory DatabaseLocal() => _instance;
  DatabaseLocal._internal();

  static Database? _database;

  /// Retorna a instância do banco, criando se necessário.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa o banco (chamado no main.dart).
  Future<void> init() async {
    await database;
  }

  /// Cria e configura o banco de dados SQLite.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'spike_dash.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Script de criação das tabelas.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE historico_partidas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        modo_jogo TEXT NOT NULL,
        pontuacao INTEGER NOT NULL,
        precisao REAL NOT NULL,
        combo_maximo INTEGER DEFAULT 0,
        data_partida TEXT NOT NULL
      )
    ''');
  }

  /// Insere uma partida no banco de dados relacional.
  Future<int> inserirPartida(Partida partida) async {
    final db = await database;
    final map = partida.toMap()..remove('id');
    return await db.insert(
      'historico_partidas',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Busca a média de pontos por modo de jogo.
  /// Usado para relatórios e gráficos de desempenho.
  Future<double> buscarMediaDePontosPorModo(String modo) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(pontuacao) as media FROM historico_partidas WHERE modo_jogo = ?',
      [modo],
    );
    return (result.first['media'] as num?)?.toDouble() ?? 0.0;
  }

  /// Busca o histórico completo de partidas, ordenado por data decrescente.
  Future<List<Partida>> buscarHistorico() async {
    final db = await database;
    final maps = await db.query(
      'historico_partidas',
      orderBy: 'data_partida DESC',
    );
    return maps.map((map) => Partida.fromMap(map)).toList();
  }

  /// Retorna o total de partidas jogadas.
  Future<int> totalPartidas() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM historico_partidas',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Busca partidas filtradas por modo de jogo.
  Future<List<Partida>> buscarPorModo(String modo) async {
    final db = await database;
    final maps = await db.query(
      'historico_partidas',
      where: 'modo_jogo = ?',
      whereArgs: [modo],
      orderBy: 'data_partida DESC',
    );
    return maps.map((map) => Partida.fromMap(map)).toList();
  }

  /// Busca a maior pontuação de um modo específico.
  Future<int> melhorPontuacao(String modo) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(pontuacao) as maximo FROM historico_partidas WHERE modo_jogo = ?',
      [modo],
    );
    return (result.first['maximo'] as int?) ?? 0;
  }
}
