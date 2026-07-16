# SPIKE DASH - Roteiro de Apresentação

**Projeto:** Arena de Reflexos e Ritmo | **Framework:** Flutter + Dart
**Duração total:** 15 minutos | **3 apresentadores**
**Regra:** Não abrir código. Explicar tudo mostrando o app funcionando.

---

## Mapeamento por Barema

| Critério | Nota | Quem cobre |
|----------|------|------------|
| UI, navegação e funcionamento geral | 1,0 | Pessoa 1 |
| Gerenciamento de estado (Provider) | 0,75 | Pessoa 2 |
| Persistência de dados (local ou externa) | 0,75 | Pessoa 2 |
| Arquitetura (camadas/MVC/MVP/MVVM) + injeção de dependências | 1,0 | Pessoa 3 |
| Qualidade de código e versionamento (Git) | 0,5 | Pessoa 3 |
| Bônus: API REST externa | até +0,5 | Pessoa 3 |
| Demonstração funcional (demo ao vivo) | 1,0 | Pessoa 1 |
| Domínio técnico e defesa | 1,0 | Todos |
| Clareza e organização | 0,5 | Todos |
| Gestão do tempo e participação | 0,5 | Todos |

---

---

# PESSOA 1 — Interface, Navegação e Demo ao Vivo

**Tempo:** 0:00 a 5:00 (5 minutos)
**Foco:** Mostrar o app funcionando, explicar UI e navegação interagindo com o app

---

## Roteiro com Texto para Falar

### 0:00 — Abertura (15 segundos)

> "Fala galera, somos a equipe do SPIKE DASH — uma arena de reflexos e ritmo. O app foi feito em Flutter e roda em 6 plataformas. Vou mostrar a interface e a navegação do app."

---

### 0:15 — Tela de Login e Animação (1 minuto)

**Mostrar:** Tela de login do app.

> "Essa é a primeira tela que o usuário vê. Repare que o logo está pulsando — essa é uma animação contínua usando `AnimationController`. O fundo é escuro porque o app inteiro usa um tema dark que definimos globalmente."

**Interagir:** Digitar email com erro → mostrar erro inline.

> "Se eu digitar um email inválido, aparece o erro em vermelho aqui embaixo. Isso é validação de formulário com `validator`. Tudo em tempo real, sem precisar enviar."

**Interagir:** Digitar senha curta → mostrar outro erro.

> "Se a senha for curta, outro erro aparece. Quando eu corrijo e aperto Entrar, o botão mostra um loading circular — o estado de 'carregando' está ativo."

---

### 1:15 — Menu Principal e Navegação (1 minuto)

**Mostrar:** Tela do menu após login.

> "Depois do login, entramos no menu principal. Repare que tem uma barra de navegação na parte inferior com 3 ícones: Jogos, Menu e Perfil. Essa barra é customizada, não é o `BottomNavigationBar` padrão do Flutter."

**Interagir:** Clicar em cada aba da barra.

> "Clicando aqui no Perfil, vejo meu nível, avatar, título, XP. Clicando de volta no Menu, volto pra tela principal. Clicando em Jogos, vejo os 4 modos de jogo."

**Interagir:** Abrir o Tap Precision, jogar 5 segundos, voltar com a seta.

> "Quando eu clico num jogo, ele abre uma nova tela com `Navigator.push`. Quando aperto a seta de voltar, ele retorna com `Navigator.pop`. Simples e direto."

---

### 2:15 — Design System Visual (30 segundos)

**Mostrar:** O menu inteiro, apontar as cores.

> "Repare que o app inteiro tem a mesma paleta de cores: verde para oprimário, cyan para secundário, amarelo para destaque, fundo preto. Isso é o Design System — todas as 30+ cores estão centralizadas numa única classe. Em qualquer tela que a gente for, as cores são consistentes."

**Mostrar:** A fonte Rajdhani no menu e Orbitron nos jogos.

> "A fonte do menu é Rajdhani. Quando a gente entra num jogo, a fonte muda pra Orbitron — mais tech, mais cyberpunk."

---

### 2:45 — Animações nos Jogos (1 minuto)

**Interagir:** Jogar Tap Precision — acertar e errar alvos.

> "No Tap Precision, quando eu acerto um alvo, aparece aquele ping de acerto — é uma `ScaleTransition`. Quando eu erro, a tela treme. Cada alvo aparece com `AnimatedOpacity` — some gradualmente. O combo vai aumentando e o feedback visual muda."

**Interagir:** Jogar Stroop Shot — mostrar a barra de progresso.

> "No Stroop Shot, tem uma barra de progresso animada. Ela usa `TweenAnimationBuilder` — a cor muda de verde pra amarelo pra vermelho conforme o tempo vai acabando. As cores das opções aparecem com `AnimatedSwitcher` — transição suave entre uma rodada e outra."

**Interagir:** Jogar Perfect Timing — mostrar a barra se movendo.

> "No Perfect Timing, a barra se move continuamente. Isso é um `Timer.periodic` a cada 16 milissegundos — 60 frames por segundo. A precisão é calculada com delta-time."

---

### 3:45 — Formulários e SnackBar (15 segundos)

**Interagir:** Sair e voltar pro login, digitar dados errados.

> "Erros de autenticação aparecem num SnackBar flutuante aqui em cima. Repare que ele aparece com animação, fica por 3 segundos e some. Não é uma tela de erro — é um feedback rápido."

---

### 4:00 — DEMO AO VIVO (1 minuto)

> "Agora vou fazer uma partida completa pra mostrar tudo funcionando junto."

**Passos da demo:**
1. **Login** → "Fazendo login com email e senha..."
2. **Menu** → "Entrou no menu, nível ROOKIE, 0 troféus."
3. **Jogar Tap Precision** → "Vou jogar o Tap Precision. Cada acerto dá pontos..."
4. **Terminar** → "Acabou o tempo. Olha: salvou os dados automaticamente — troféus, XP, histórico."
5. **Perfil** → "No perfil: nível subiu, barra de XP preencheu, troféus apareceram."
6. **Ranking** → "No ranking global, meu nome já aparece lá. Atualizou em tempo real."
7. **Voltar pro menu** → "E voltando pro menu, tudo consistente."

> "Tudo isso: login, jogo, persistência, ranking, perfil. Em seguida, a [nome] vai explicar como o Provider e a persistência funcionam por baixo dos panos — mostrando no app como os dados mudam em tempo real."

---

---

# PESSOA 2 — Gerenciamento de Estado e Persistência

**Tempo:** 5:00 a 10:00 (5 minutos)
**Foco:** Mostrar Provider funcionando interagindo com o app

---

## Roteiro com Texto para Falar

### 5:00 — Provider: Mostrar que a UI reage ao estado (1:30)

**Interabrir:** Abrir o perfil → jogar uma partida → voltar pro perfil.

> "Vou mostrar o Provider em ação. Olhem o perfil: nível ROOKIE, 0 troféus. Agora vou jogar uma partida rápida."

*(jogar Tap Precision)*

> "Terminou. Agora voltando pro perfil..."

**Mostrar:** Perfil atualizado — troféus, XP, nível.

> "Repare: os troféus mudaram, o XP mudou, a barra de progresso preencheu. Isso é o Provider. O `UsuarioProvider` notificou a UI que os dados mudaram e o `Consumer` reconstruiu o widget automaticamente. Não recarregamos a tela — o estado mudou e a UI reagiu."

**Interagir:** Jogar de novo e mostrar que atualiza de novo.

> "Jogando mais uma vez..."

*(jogar)*

> "Voltando pro perfil: atualizou de novo. Cada jogada, o Provider notifica, o Consumer reconstrói. É reatividade pura."

---

### 6:30 — Consumer vs context.read (1 minuto)

**Mostrar:** O ranking — mostrar que atualiza sozinho.

> "Olhem o ranking. Ele está mostrando os jogadores em tempo real. Isso é um `Consumer` escutando um stream do Firestore. Quando alguém faz uma jogada em qualquer lugar do mundo, esse ranking atualiza sozinho."

**Interagir:** Abrir dois devices (ou browser + emulador) e jogar num → ranking atualiza no outro.

> "Se eu jogar nesse dispositivo aqui, o ranking nesse outro atualiza automaticamente. Isso é stream em tempo real via `Consumer<RankingProvider>`."

**Mostrar:** O menu — clicar num botão de ação.

> "Quando eu clico no botão de 'Jogar', isso é `context.read` — executa uma ação uma vez, sem ficar observando. O `Consumer` observa continuamente, o `context.read` executa no clique."

---

### 7:30 — Persistência: Hive (cache instantâneo) (1 minuto)

**Interagir:** Fechar o app completamente → abrir de novo.

> "Vou fechar o app inteiro. Agora abrindo de novo..."

**Mostrar:** App abre direto no menu, com nickname, nível, troféus já carregados.

> "Repare: não pediu login de novo. Os dados já estão aqui. Isso é o **Hive** — banco de dados local NoSQL. Quando eu fiz login antes, os dados foram salvos no Hive. Agora que abri de novo, o app leu do Hive primeiro — instantâneo, sem internet."

**Interagir:** Jogar uma partida, fechar, abrir de novo.

> "Jogando mais uma partida... agora fechando e abrindo de novo..."

**Mostrar:** Troféus e XP persistidos.

> "Os troféus e XP continuam lá. Isso é persistência local via Hive."

---

### 8:30 — Persistência: SQLite (histórico) (30 segundos)

**Mostrar:** O histórico de partidas (se tiver tela) ou explicar.

> "Além do Hive, tem o **SQLite** — banco relacional local. Ele salva o histórico detalhado de cada partida: modo de jogo, pontuação, precisão, combo máximo, data. O SQLite faz queries SQL como `SELECT AVG(pontuacao) FROM historico_partidas WHERE modo_jogo = 'tap_precision'`. Isso permite calcular estatísticas como média de pontos por modo."

---

### 9:00 — Persistência: Firestore (nuvem) (30 segundos)

**Interagir:** Mostrar o ranking global.

> "A terceira camada é o **Cloud Firestore** — banco em nuvem. O ranking que vocês estão vendo aqui é um stream em tempo real do Firestore. Quando alguém faz uma jogada em qualquer dispositivo, o Firestore notifica todos os conectados. Não é polling, não é WebSocket manual — o Firestore cuida disso automaticamente."

**Interagir:** Mostrar que o ranking tem jogadores de diferentes contas.

> "Aqui tem o [nome do amigo] jogando ao mesmo tempo. O ranking mostra os dois. Isso é Firestore + streams."

---

### 9:30 — Singleton e Cache-First (30 segundos)

> "Todos os serviços — Hive, SQLite, Firestore — usam o padrão **Singleton**: só existe uma instância de cada um no app inteiro. Isso evita bugs de múltiplas conexões. E o padrão é **cache-first**: primeiro lê do Hive (local), depois sincroniza com o Firestore (nuvem). Se não tiver internet, o app continua funcionando com os dados locais."

---

---

# PESSOA 3 — Arquitetura, Git e Fechamento

**Tempo:** 10:00 a 15:00 (5 minutos)
**Foco:** Explicar arquitetura pelo comportamento do app, Git, fechamento

---

## Roteiro com Texto para Falar

### 10:00 — Arquitetura em Camadas (2 minutos)

> "Agora vou explicar a arquitetura do projeto. O SPIKE DASH segue o padrão **Service Layer** — separação em 4 camadas. Eu vou explicar cada uma mostrando o que ela faz no app."

**Mostrar:** O menu — o que o usuário vê.

> "A primeira camada são as **Telas** — é o que o usuário vê e interage. Cada tela é um widget Flutter. Essa tela do menu, a tela de login, as telas dos jogos — tudo são telas."

**Interagir:** Jogar Tap Precision → mostrar que ao terminar, os dados mudam no perfil.

> "Quando eu termino uma partida, a tela chama o **Provider**. O Provider é a segunda camada — ele orquestra a lógica de negócio. Ele pega os dados da partida, calcula troféus e XP, e manda salvar."

**Interagir:** Fechar e abrir o app → dados continuam lá.

> "O Provider chama o **Service**. O Service é a terceira camada — ele fala com o banco de dados. O HiveService salva no Hive, o DatabaseLocal salva no SQLite, o FirestoreService salva no Firestore. Cada service cuida de uma fonte de dados."

**Interagir:** Mostrar que o modelo de dados (níveis, títulos) muda no perfil.

> "A quarta camada são os **Models** — os dados em si. O modelo `Usuario` tem 14 campos: uid, nickname, nível, XP, troféus, avatar, título, conquistas. O modelo também tem lógica: o método `calcularNivel()` calcula o nível baseado no XP. Se eu tenho 300 XP, sou nível 3. Se tenho 1500, sou nível 11 MESTRE."

**Interagir:** Mostrar o perfil subindo de nível após jogar.

> "Repare: quanto mais eu jogo, mais XP ganho, mais o nível sobe. Isso é o Model calculando. E o Provider manda pro Hive e pro Firestore salvarem."

---

### 12:00 — Firebase e API Externa (1 minuto)

**Interagir:** Fazer logout → login de novo.

> "Fazendo logout... e login de novo. Repare: o app reconheceu o usuário, carregou os dados. Isso é o **Firebase Auth** — autenticação em nuvem. Ele mantém a sessão automaticamente."

**Mostrar:** Ranking em tempo real.

> "O ranking é uma **API externa** — o Cloud Firestore. Ele é um banco NoSQL em nuvem da Google. O app se comunica com ele via SDK oficial do Firebase. Quando alguém faz uma jogada, o Firestore notifica todos os conectados via streams. Não precisamos de servidor próprio, não precisamos de REST manual — o Firebase cuida de tudo."

**Interagir:** Mostrar que o ranking tem dados de outros jogadores.

> "Aqui tem jogadores de diferentes contas. Os dados vêm do Firestore, atualizam em tempo real. Isso é o diferencial extra do projeto — consumo de API externa."

---

### 13:00 — Git e Versionamento (1 minuto)

> "O projeto está no GitHub com versionamento ativo."

**Dica:** Se possível, mostrar o `git log --oneline` rapidamente na tela.

> "Cada funcionalidade foi feita em commits separados seguindo o padrão **Conventional Commits**: `feat:` para funcionalidades novas, `fix:` para correções, `refactor:` para melhorias de código. Exemplos: `feat: add Provider`, `feat: add Hive cache`, `feat: add Firestore ranking`, `fix: ranking loading infinite`."

> "O repositório tem README com instruções de build, o `.gitignore` protege as chaves do Firebase, e o código está documentado com comentários nas classes principais."

---

### 14:00 — Fechamento e Resumo (1 minuto)

> "Pra fechar, vamos resumir o que o SPIKE DASH tem:"

**Mostrar:** O app inteiro — menu, jogos, ranking, perfil.

> "**UI e Navegação:** Tema dark com 30+ cores nomeadas, 2 fontes, animações em todas as telas, formulários validados, navegação com push/pop, SnackBar flutuante."

> "**Gerenciamento de Estado:** 4 providers com Provider — Auth, Usuario, Partida, Ranking. Consumer reativo que atualiza a UI em tempo real."

> "**Persistência:** 3 camadas — Hive para cache instantâneo, SQLite para histórico relacional, Firestore para nuvem em tempo real. Padrão cache-first."

> "**Arquitetura:** Service Layer com 4 camadas — Models, Services, Providers, Telas. Singleton Pattern em todos os services. Code Generation com build_runner."

> "**Funcionalidades:** 4 jogos com máquinas de estados, sistema de progressão de ROOKIE a DIVINO, 7 avatares desbloqueáveis, ranking global e de amigos, conquistas."

> "**Plataformas:** Android, iOS, Web, Linux, macOS, Windows — tudo em um único código Flutter."

> "O app resolve entretenimento rápido com jogos de reflexos, progressão que mantém o jogador engajado, e competitividade entre amigos via ranking. Obrigado!"

---

---

# Checklist dos Artefatos

Obrigatório entregar no GitHub:

| Artefato | Onde colocar |
|----------|-------------|
| Wireframes (baixa fidelidade) | Pasta `/wireframes` ou `/docs/wireframes/` |
| Protótipo alta fidelidade (Figma) | Link no README.md |
| Modelagem de dados | Pasta `/docs/modelagem.md` ou diagrama ER |
| Código-fonte | Root do repositório |
| Este roteiro | `APRESENTACAO.md` na root |

---

# Dicas para o Vídeo

1. **Gravem a tela do app** enquanto um fala — nunca tela parada
2. **Cada um fala sua parte** — ninguém fica em silêncio
3. **Interajam com o app** durante a explicação — joguem, cliquem, mostrem
4. **Não abram código** — expliquem pelo comportamento do app
5. **A demo ao vivo** é o momento mais importante — ensaiem antes
6. **Fechem em 15 minutos** — cronometrem cada parte
7. **Publiquem no YouTube** como "unlisted" e coloquem o link no repositório
