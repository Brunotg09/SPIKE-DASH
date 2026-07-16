# SPIKE DASH - Conceitos e Tecnologias Utilizados

Projeto: **SPIKE DASH** - Arena de Reflexos e Ritmo
Framework: **Flutter** (Dart >=3.2.6 <4.0.0)
Plataformas: Android, iOS, Web, Linux, macOS, Windows

---

## 1. Dependencias Principais

| Dependencia | Versao | Finalidade |
|------------|--------|------------|
| `flutter` | SDK | Framework principal |
| `provider` | ^6.1.1 | Gerenciamento de estado |
| `hive` / `hive_flutter` | ^2.2.3 | Banco NoSQL local (cache) |
| `sqflite` | ^2.3.0 | Banco SQLite local (historico) |
| `firebase_core` | ^3.12.1 | Inicializacao do Firebase |
| `firebase_auth` | ^5.5.1 | Autenticacao (email/senha) |
| `cloud_firestore` | ^5.6.5 | Banco de dados em nuvem |
| `flutter_dotenv` | ^5.2.1 | Variaveis de ambiente (.env) |
| `hive_generator` | ^2.0.1 | Geracao de codigo Hive TypeAdapter |
| `build_runner` | ^2.4.7 | Runner de geracao de codigo |

---

## 2. Gerenciamento de Estado

### Provider (ChangeNotifier + MultiProvider)

- **Arquivo:** `lib/main.dart:47-53`
- 4 providers registrados no `MultiProvider` raiz:
  - `AuthProvider` - gerencia autenticacao e sessao
  - `UsuarioProvider` - gerencia dados do jogador e progresso
  - `PartidaProvider` - gerencia historico de partidas
  - `RankingProvider` - gerencia rankings em tempo real

- **Consumer** para rebuilds reativos:
  - `Consumer<AuthProvider>`: `lib/main.dart:239`, `lib/auth_gate.dart:29,230`
  - `Consumer<UsuarioProvider>`: `lib/menu.dart:130,251`, `lib/profile.dart:112`
  - `Consumer2<RankingProvider, UsuarioProvider>`: `lib/rankings.dart:208,269`

- **context.read** para leituras unicas em todos os arquivos de tela e provider

---

## 3. Padroes de Arquitetura

### Singleton Pattern
Servicos com factory constructor para garantir unica instancia:
- `HiveService`: `lib/services/hive_service.dart:9-11`
- `FirestoreService`: `lib/services/firestore_service.dart:12-14`
- `DatabaseLocal`: `lib/services/database_local.dart:8-10`

### Service Layer Architecture
Separacao clara em 4 camadas:
- **Models** (`lib/models/`): `usuario.dart`, `partida.dart`
- **Services** (`lib/services/`): `hive_service.dart`, `firestore_service.dart`, `database_local.dart`
- **Providers** (`lib/providers/`): 4 providers com ChangeNotifier
- **Screens** (`lib/`): telas de cada jogo e menu

### Auth Gate Pattern (Navigation Guard)
- `lib/auth_gate.dart:9-63`: Verifica sessao e renderiza Menu ou tela de login
- Usado como `home:` no MaterialApp: `lib/main.dart:58`

### Code Generation
- `build_runner` + `hive_generator` para gerar TypeAdapter do Hive
- `lib/models/usuario.g.dart` gerado automaticamente

---

## 4. Banco de Dados e Persistencia

### Estrategia de Cache 3 Camadas

**Camada 1 - Hive (Cache Instantaneo Local)**
- `lib/services/hive_service.dart`
- Box `configuracoes`: darkMode, volumeMusic, volumeSfx
- Box `perfil_cache`: uid, nickname, titulo, nivel, trofeus, vitorias, precisaoMedia, xp, avatarId, avatarsDesbloqueados, titulosDesbloqueados
- Inicializado em `lib/main.dart:31-32`

**Camada 2 - SQLite (Relacional Local - somente mobile)**
- `lib/services/database_local.dart`
- Tabela `historico_partidas`: id, modo_jogo, pontuacao, precisao, combo_maximo, data_partida
- Operacoes: inserir, buscar historico, media por modo, melhor pontuacao, total de partidas
- Inicializado em `lib/main.dart:36` (condicional `!kIsWeb`)

**Camada 3 - Firestore (Nuvem)**
- `lib/services/firestore_service.dart`
- Collections: `usuarios/`, `rankings/`, `partidas/{uid}/historico/`
- Streams em tempo real para rankings global e semanal
- Merge writes com `SetOptions(merge: true)`

### Padrao de Salvamento nos Jogos
Cada jogo tenta salvar via Provider primeiro, depois fallback via services diretas:
- `lib/tap_precision.dart:69-81` -> `lib/tap_precision.dart:84-130`
- `lib/stroop_shot.dart:96-108` -> `lib/stroop_shot.dart:111-157`
- `lib/reflex_duel.dart:68-80` -> `lib/reflex_duel.dart:83-129`
- `lib/perfect_timing.dart:104-116` -> `lib/perfect_timing.dart:119-165`

---

## 5. Firebase

### Firebase Core
- Inicializacao: `lib/main.dart:26-28`
- Configuracao por plataforma: `lib/firebase_options.dart`

### Firebase Authentication
- Email/senha: `lib/providers/auth_provider.dart:48-78` (login), `lib/providers/auth_provider.dart:82-132` (registro)
- Sessao persistente via `_auth.currentUser`
- Tratamento de erros por codigo: `lib/providers/auth_provider.dart:175-191`

### Cloud Firestore
- Leitura de usuario: `lib/providers/auth_provider.dart:135-173`
- Atualizacao de ranking: `lib/services/firestore_service.dart:95-112`
- Streams de ranking: `lib/services/firestore_service.dart:75-92`

---

## 6. Variaveis de Ambiente

### flutter_dotenv
- Carregamento: `await dotenv.load()` em `lib/main.dart:23`
- Declaracao como asset: `pubspec.yaml:45`
- Uso nas configuracoes Firebase: `lib/firebase_options.dart:24-47`
- 18 variaveis de ambiente (Android, iOS, Web)
- Template `.env.example` fornecido
- `.env` no `.gitignore`

---

## 7. UI/UX

### Design System
- Tema dark: `AppTheme.darkTheme` em `lib/config/theme.dart:60-73`
- Fonte padrao: Rajdhani, fontes nos jogos: Orbitron
- Classe `AppColors`: 30+ constantes de cores nomeadas
- Paleta: verde primario (#00FF66), cyan, amarelo, vermelho, laranja, fundo preto

### Layout Responsivo
- Constraints `maxWidth: 420/400` em todas as telas para design mobile-first
- `SafeArea` em todas as telas
- `SingleChildScrollView`, `ListView.builder`, `GridView.builder`

### Animacoes
- `AnimationController` + `Tween` + `CurvedAnimation` (pulse na tela de auth)
- `FadeTransition`, `AnimatedSwitcher`, `AnimatedContainer`
- `AnimatedScale`, `AnimatedOpacity` (feedback nos jogos)
- `TweenAnimationBuilder` (barra de progresso no Stroop Shot)
- `ScaleTransition` (animação de ping no Tap Precision)

### Navegacao
- `Navigator.push` imperativo para todas as transicoes
- `Navigator.popUntil` no logout para limpar stack
- Barra de navegacao customizada com 3 itens

### Formularios
- `GlobalKey<FormState>` para validacao de login/registro
- `TextFormField` com `validator` callbacks
- SnackBar flutuante para erros

### Outros Padroes UI
- `MouseRegion` para efeitos hover (desktop/web)
- `showModalBottomSheet` para seletores de avatar e titulo
- `RotatedBox` para tela espelhada no Reflex Duel (modo 2 jogadores)

---

## 8. Logica dos Jogos

### Maquina de Estados (FSM)
- **Stroop Shot:** `GameState { idle, showingWord, pickingColor, feedback, gameOver }`
- **Reflex Duel:** `DuelState { idle, countdown, waiting, fire, penalty, roundOver, gameOver }`
- **Perfect Timing:** `GamePhase { countdown, playing, ended }`

### Game Loop baseado em Timer
- Countdown: `Timer.periodic(Duration(seconds: 1))` em todos os jogos
- Movimento: `Timer.periodic(Duration(milliseconds: 16))` (~60fps) no Perfect Timing
- Delta-time: `dt = (now - _lastTime) / 1000000.0`

### Mecnicas por Jogo

| Modo | Tipo | Mecanica Principal |
|------|------|--------------------|
| Tap Precision | Solo | Alvos que somem (800-1500ms), sistema de combo |
| Reflex Duel | 2 Jogadores | Tela dividida, reacao, melhor de 5 rondas |
| Perfect Timing Evo | Solo | Barra movel com zonas (pequena/media/grande) |
| Stroop Shot | Solo | Efeito Stroop: nome da cor em outra cor |

### Sistemas de Pontuacao
- **Tap Precision:** Score = acertos, trofeus = score * 2
- **Stroop Shot:** Score = soma de (100 + combo*25), trofeus = (corretas*2) + maxCombo
- **Perfect Timing:** Baseado no tamanho da zona e precisao
- **Reflex Duel:** 20 trofeus fixos para o vencedor

### Combo System
- Contador de combo que reseta em erro ou timeout
- Multiplicador de pontos no Stroop Shot

### Escalabilidade de Dificuldade
- Nivel aumenta a cada 3 acertos no Stroop Shot
- Temporizador diminui de 8s para 4s minimo
- Quantidade de botoes varia 4-8 por rodada

### Efeito Stroop (Desafio Cognitivo)
- Palavra da cor exibida em cor diferente
- 15 cores com nomes e valores Color
- Duas fases: mostrar palavra -> escolher cor

### Sistema de Reacao
- `Stopwatch` para medir tempo de reacao no Reflex Duel
- Penalti por partida falsa (toque antes do sinal)

---

## 9. Sistema de Progressao

### XP e Niveis
- XP ganho = trofeus por partida
- Formula: `(nivel - 1) * 150` XP por nivel
- Calculo com porcentagem de progresso

### Nomes dos Niveis (6 faixas)

| Nivel | Nome |
|-------|------|
| 1-3 | ROOKIE |
| 4-6 | VETERANO |
| 7-9 | EXPERT |
| 10-12 | MESTRE |
| 13-15 | LENDA |
| 16+ | DIVINO |

### Titulos Desbloqueaveis
- Desbloqueados ao alcancar o nivel correspondente
- Selecionavel no perfil: `lib/profile.dart:456-555`

### Avatares Desbloqueaveis (7 total)
- Desbloqueados nos niveis: 3, 5, 7, 10, 13, 16
- Selecionavel no perfil: `lib/profile.dart:359-453`

---

## 10. Configuracao por Plataforma

### Android
- Package: `com.example.spike_dash_app`
- Kotlin 2.2.20, Java 17
- Google Services plugin
- MainActivity em Kotlin: `android/app/src/main/kotlin/.../MainActivity.kt`
- Hardware acceleration habilitado

### Web
- PWA com manifest.json (standalone, portrait)
- Service Worker para cache
- Icones maskable

### Multi-Plataforma
- `kIsWeb` para desabilitar SQLite no web
- `PartidaProvider` usa Firestore no web, SQLite no mobile

---

## 11. Arquitetura do Fluxo de Autenticacao

1. App inicia -> Firebase, Hive, SQLite inicializados
2. `AuthGate` verifica sessao via `_auth.currentUser`
3. Se logado -> renderiza `MenuScreen`
4. Se nao logado -> renderiza tela de login/registro
5. Login -> Firebase Auth -> carrega dados Firestore -> salva cache Hive
6. Registro -> Firebase Auth create -> salva Firestore + Hive
7. Logout -> Firebase sign out + limpa cache Hive + reseta stack de navegacao

---

## 12. Resumo por Categoria

| Categoria | Quantidade |
|-----------|------------|
| Dependencias | 14 (11 runtime + 3 dev) |
| Providers | 4 (Auth, Usuario, Partida, Ranking) |
| Bancos de Dados | 3 (Hive + SQLite + Firestore) |
| Servicos Firebase | 3 (Core + Auth + Firestore) |
| Padroes de Design | 6 (Singleton, Auth Gate, Service Layer, Code Gen, Cache-First, FSM) |
| Modos de Jogo | 4 (Tap Precision, Reflex Duel, Perfect Timing, Stroop Shot) |
| Padroes UI/UX | 15+ (animacoes, forms, hover, navegacao, modais, responsivo) |
| Niveis de Progressao | 6 faixas (ROOKIE a DIVINO) |
| Avatares | 7 desbloqueaveis |
| Plataformas | 6 (Android, iOS, Web, Linux, macOS, Windows) |
| Camadas de Cache | 3 (Hive -> SQLite -> Firestore) |
