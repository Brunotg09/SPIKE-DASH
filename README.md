# SPIKE DASH

**Arena de Reflexos e Ritmo**

Aplicativo Flutter de competição e treino de reflexos com múltiplos modos de jogo, autenticação via Firebase e Rankings globais em tempo real.

## Funcionalidades

- **Tap Precision** — Treino solo de velocidade: toque nos alvos verdes o mais rápido possível
- **Reflex Duel** — Multijogador local: competição 1v1 de reflexos
- **Perfect Timing Evo** — Desafio de ritmo: acerte a zona central que se transforma e muda de cor
- **Stroop Shot** — Pressão cognitiva: decifre enigmas de cores em modo solo ou 1v1
- **Rankings Globais** — Classificação em tempo real via Cloud Firestore
- **Perfil do Jogador** — Troféus, vitórias, precisão média e títulos
- **Sistema de Progressão** — Níveis de ROOKIE a DIVINO com XP e troféus
- **7 Avatares Desbloqueáveis** — Conquistas e personalização

## Arquitetura

Service Layer com 4 camadas:

```
lib/
  ├── main.dart                  # Ponto de entrada + MultiProvider
  ├── auth_gate.dart             # Controle de autenticação
  ├── firebase_options.dart      # Credenciais Firebase
  ├── menu.dart                  # Menu principal
  ├── profile.dart               # Perfil do jogador
  ├── rankings.dart              # Rankings globais
  ├── tap_precision.dart         # Mini-jogo: Tap Precision
  ├── reflex_duel.dart           # Mini-jogo: Reflex Duel
  ├── perfect_timing.dart        # Mini-jogo: Perfect Timing Evo
  ├── stroop_shot.dart           # Mini-jogo: Stroop Shot
  ├── config/
  │   └── theme.dart             # Constantes de cores do tema
  ├── models/
  │   ├── usuario.dart           # Modelo do usuário
  │   ├── usuario.g.dart         # Adaptador Hive (build_runner)
  │   └── partida.dart           # Modelo da partida
  ├── providers/
  │   ├── auth_provider.dart     # Autenticação Firebase
  │   ├── usuario_provider.dart  # Dados do jogador
  │   ├── partida_provider.dart  # Histórico de partidas
  │   └── ranking_provider.dart  # Rankings globais
  └── services/
      ├── database_local.dart    # SQLite singleton
      ├── hive_service.dart      # Hive singleton (cache)
      └── firestore_service.dart # Firestore (nuvem)
```

## Pré-requisitos

- Flutter SDK `>=3.2.6 <4.0.0`
- Dart SDK `>=3.2.6 <4.0.0`
- Conta Firebase configurada
- Arquivo `.env` com credenciais (ver `.env.example`)

## Instalação

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/spike_dash_app.git
cd spike_dash_app

# Instale dependências
flutter pub get

# Gere adaptadores Hive (se necessário)
dart run build_runner build

# Configure o arquivo .env
cp .env.example .env
# Edite .env com suas credenciais Firebase

# Execute o app
flutter run
```

## Variáveis de Ambiente

O projeto utiliza `flutter_dotenv` para gerenciar credenciais. Crie um arquivo `.env` na raiz;
```

## Tecnologias

| Tecnologia | Versão | Finalidade |
|------------|--------|------------|
| Flutter | SDK | Framework multiplataforma |
| Provider | ^6.1.1 | Gerenciamento de estado |
| Hive | ^2.2.3 | Cache local NoSQL |
| SQLite | ^2.3.0 | Banco relacional local |
| Firebase Core | ^3.12.1 | Inicialização Firebase |
| Firebase Auth | ^5.5.1 | Autenticação email/senha |
| Cloud Firestore | ^5.6.5 | Banco de dados nuvem |
| flutter_dotenv | ^5.2.1 | Variáveis de ambiente |
| build_runner | ^2.4.7 | Geração de código Hive |

## Estratégia de Cache

```
Hive (instantâneo) → SQLite (histórico) → Firestore (nuvem)
```

- **Hive**: Perfil do jogador, configurações
- **SQLite**: Histórico detalhado de partidas (apenas mobile)
- **Firestore**: Rankings globais, dados do usuário

## Plataformas

- Android
- iOS
- Web
- Linux
- macOS
- Windows

```

## Integrantes

- Bruno Antonio
- Matheus Santiago
- Wallace Barreto
