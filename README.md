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

## Arquitetura

Estrutura em camadas (Provider/MVVM):

```
spike_dash_app/                    # Aplicação Flutter principal
  ├── android/                       # Configurações Android
  ├── ios/                           # Configurações iOS
  ├── web/                           # Configurações Web
  ├── linux/                         # Configurações Linux
  ├── macos/                         # Configurações macOS
  ├── windows/                       # Configurações Windows
  ├── lib/                           # Código-fonte Dart
  │   ├── main.dart                  # Ponto de entrada + MultiProvider
  │   ├── firebase_options.dart      # Credenciais Firebase
  │   ├── menu.dart                  # Menu principal
  │   ├── profile.dart               # Perfil do jogador
  │   ├── rankings.dart              # Rankings globais
  │   ├── tap_precision.dart         # Mini-jogo: Tap Precision
  │   ├── reflex_duel.dart           # Mini-jogo: Reflex Duel
  │   ├── perfect_timing.dart        # Mini-jogo: Perfect Timing Evo
  │   ├── stroop_shot.dart           # Mini-jogo: Stroop Shot
  │   ├── config/
  │   │   └── theme.dart             # Constantes de cores do tema
  │   ├── models/
  │   │   ├── usuario.dart           # Modelo do usuário
  │   │   ├── usuario.g.dart         # Adaptador Hive (build_runner)
  │   │   └── partida.dart           # Modelo da partida
  │   ├── providers/
  │   │   ├── auth_provider.dart     # Autenticação Firebase
  │   │   ├── usuario_provider.dart  # Dados do jogador
  │   │   ├── partida_provider.dart  # Histórico de partidas
  │   │   └── ranking_provider.dart  # Rankings globais
  │   └── services/
  │       ├── database_local.dart    # SQLite singleton
  │       ├── hive_service.dart      # Hive singleton (cache)
  │       └── firestore_service.dart # Firestore (nuvem)
  ├── test/                          # Testes
  ├── pubspec.yaml                   # Dependências Flutter
  ├── pubspec.lock                   # Lock de dependências
  ├── analysis_options.yaml          # Configurações de análise
  └── README.md                      # Readme do projeto Flutter

## Tecnologias

- **Flutter** — SDK multiplataforma
- **Firebase Auth** — Autenticação por e-mail
- **Cloud Firestore** — Banco de dados em nuvem (rankings e partidas)
- **Hive** — Cache local NoSQL (perfil do jogador)
- **SQLite** — Banco relacional local (histórico de partidas)
- **Provider** — Gerenciamento de estado

## Integrantes

- Bruno Antonio
- Matheus Santiago
- Wallace Barreto
