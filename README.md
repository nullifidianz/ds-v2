# Sistema de Mensagens Distribuído - BBS/IRC

Projeto de sistemas distribuídos implementando um sistema de troca de mensagens instantâneas baseado em BBS/IRC usando ZeroMQ e MessagePack.

## Arquitetura do Sistema

O sistema é composto por diversos componentes distribuídos que se comunicam através de ZeroMQ:

### Componentes Principais

1. **Broker** (Request-Reply Router)
   - Implementa o padrão ROUTER/DEALER
   - Balanceia carga entre servidores usando round-robin
   - Portas: 5555 (ROUTER para clientes), 5556 (DEALER para servidores)

2. **Proxy** (Publisher-Subscriber)
   - Implementa o padrão XPUB/XSUB
   - Gerencia publicações em canais e mensagens privadas
   - Portas: 5557 (XSUB para publishers), 5558 (XPUB para subscribers)

3. **Servidor de Referência**
   - Gerencia registro e rank de servidores
   - Mantém lista de servidores ativos via heartbeat
   - Fornece serviços: rank, list, heartbeat
   - Porta: 5559

4. **Servidores** (3 réplicas em 3 linguagens)
   - Python: Servidor principal com todas as funcionalidades
   - JavaScript/Node.js: Servidor equivalente
   - Go: Servidor equivalente
   - Processam requisições de login, canais, mensagens e publicações
   - Sincronizam relógios lógicos e físicos
   - Replicam dados entre si

5. **Clientes**
   - Python: Cliente interativo com menu
   - JavaScript: Cliente automatizado
   - Go: Cliente automatizado
   - Implementam relógio lógico
   - Recebem mensagens via SUB

6. **Bots** (2 réplicas em 3 linguagens)
   - Python: 2 réplicas
   - JavaScript: Bot automatizado
   - Go: Bot automatizado
   - Publicam mensagens automaticamente em canais
   - Implementam relógio lógico

## Funcionalidades Implementadas

### Parte 1: Request-Reply
- ✅ Login de usuários (sem senha)
- ✅ Listagem de usuários cadastrados
- ✅ Criação de canais
- ✅ Listagem de canais disponíveis
- ✅ Persistência em JSON

### Parte 2: Publisher-Subscriber
- ✅ Publicações em canais públicos
- ✅ Mensagens privadas entre usuários
- ✅ Bots automatizados
- ✅ Inscrição em tópicos
- ✅ Persistência de mensagens e publicações

### Parte 3: MessagePack
- ✅ Serialização binária usando MessagePack
- ✅ Substituição completa de JSON por MessagePack nas mensagens
- ✅ Comunicação entre diferentes linguagens

### Parte 4: Relógios
- ✅ Relógio lógico em todos os processos (cliente, bot, servidor)
- ✅ Servidor de referência com gerenciamento de ranks
- ✅ Heartbeat para detecção de servidores ativos
- ✅ Sincronização de relógio físico (algoritmo de Berkeley - simplificado)
- ✅ Eleição de coordenador (via publicação no tópico 'servers')
- ✅ Inscrição em tópico 'servers' para notificações de eleição

### Parte 5: Replicação de Dados
- ✅ Replicação entre servidores via tópico 'replication'
- ✅ Merge de dados (usuários e canais)
- ✅ Sincronização periódica (a cada 30 segundos)
- ✅ Todos os servidores mantêm cópia completa dos dados

## Método de Replicação Implementado

### Estratégia: Replicação Eventual via Publish-Subscribe

O sistema implementa **replicação eventual** usando o padrão Publisher-Subscriber:

#### Funcionamento:

1. **Publicação de Estado**: Cada servidor publica periodicamente (a cada 30 segundos) seu estado completo (usuários e canais) no tópico `replication`.

2. **Recepção e Merge**: Todos os servidores estão inscritos no tópico `replication` e recebem as publicações dos outros servidores.

3. **Merge de Dados**: 
   - Quando um servidor recebe dados de outro servidor, ele faz o merge:
     - Adiciona usuários que não existem localmente
     - Adiciona canais que não existem localmente
   - Não há conflitos pois usamos apenas operações de adição (append-only)

4. **Consistência Eventual**:
   - O sistema garante que, eventualmente, todos os servidores terão os mesmos usuários e canais
   - Novas inscrições são propagadas em até 30 segundos
   - Não há remoção de dados, apenas adição

#### Vantagens:
- Simples de implementar
- Tolerante a falhas (servidores podem sair e entrar)
- Sem necessidade de coordenação central para replicação
- Funciona bem para dados append-only

#### Limitações:
- Latência de até 30 segundos para propagação
- Não garante consistência forte
- Adequado apenas para operações de adição
- Consumo de banda com publicações completas

#### Formato das Mensagens de Replicação:

```json
{
  "service": "replication",
  "data": {
    "server": "nome_do_servidor",
    "users": ["usuario1", "usuario2", ...],
    "channels": ["canal1", "canal2", ...],
    "timestamp": 1234567890.123,
    "clock": 42
  }
}
```

## Estrutura de Diretórios

```
src/
├── broker/                 # Broker Request-Reply
│   └── main.py
├── proxy/                  # Proxy Publisher-Subscriber
│   └── main.py
├── reference/              # Servidor de Referência
│   └── main.py
├── server/                 # Servidor Python
│   └── main.py
├── server-js/              # Servidor JavaScript
│   ├── main.js
│   ├── package.json
│   └── Dockerfile
├── server-go/              # Servidor Go
│   ├── main.go
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── client/                 # Cliente Python
│   └── main.py
├── client-js/              # Cliente JavaScript
│   ├── main.js
│   ├── package.json
│   └── Dockerfile
├── client-go/              # Cliente Go
│   ├── main.go
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── bot/                    # Bot Python
│   └── main.py
├── bot-js/                 # Bot JavaScript
│   ├── main.js
│   ├── package.json
│   └── Dockerfile
├── Dockerfile             # Dockerfile base Python
└── docker-compose.yml     # Orquestração de todos os containers
```

## Tecnologias Utilizadas

- **ZeroMQ**: Biblioteca de mensagens assíncronas
- **MessagePack**: Serialização binária eficiente
- **Python 3.13**: Linguagem principal
- **Node.js 20**: Segunda linguagem
- **Go 1.21**: Terceira linguagem
- **Docker**: Containerização
- **Docker Compose**: Orquestração

## Como Executar

### Pré-requisitos

- Docker
- Docker Compose

### Executar o Sistema

```bash
cd src
docker-compose up --build
```

Isso irá iniciar:
- 1 Broker
- 1 Proxy
- 1 Servidor de Referência
- 3 Servidores (Python com 3 réplicas)
- 1 Cliente Python
- 2 Bots Python

### Executar com Servidores JavaScript e Go

Para adicionar servidores em outras linguagens ao `docker-compose.yml`:

```yaml
  server-js:
    build:
      context: ./server-js
      dockerfile: Dockerfile
    depends_on:
      - broker
      - proxy
      - reference
    volumes:
      - server_js_data:/data
    environment:
      - SERVER_NAME=server_js

  server-go:
    build:
      context: ./server-go
      dockerfile: Dockerfile
    depends_on:
      - broker
      - proxy
      - reference
    volumes:
      - server_go_data:/data
    environment:
      - SERVER_NAME=server_go
```

E adicionar os volumes:

```yaml
volumes:
  server_data:
  server_js_data:
  server_go_data:
```

### Testar o Sistema

1. O cliente Python fornece um menu interativo
2. Use a opção 2 para criar um canal
3. Use a opção 4 para se inscrever no canal
4. Use a opção 6 para publicar mensagens
5. Os bots automaticamente publicarão mensagens nos canais disponíveis

## Formato de Mensagens

Todas as mensagens seguem o formato:

```json
{
  "service": "nome_do_servico",
  "data": {
    "timestamp": 1234567890.123,
    "clock": 42,
    ... outros campos específicos do serviço
  }
}
```

### Serviços Disponíveis

- `login`: Registrar usuário
- `users`: Listar usuários
- `channel`: Criar canal
- `channels`: Listar canais
- `publish`: Publicar em canal
- `message`: Enviar mensagem privada
- `rank`: Obter rank do servidor (referência)
- `list`: Listar servidores (referência)
- `heartbeat`: Enviar heartbeat (referência)
- `election`: Notificação de eleição
- `replication`: Sincronização de dados

## Persistência de Dados

Cada servidor mantém os seguintes arquivos JSON em `/data`:

- `users.json` / `users_js.json` / `users_go.json`: Lista de usuários
- `channels.json` / `channels_js.json` / `channels_go.json`: Lista de canais
- `logins.json` / `logins_js.json` / `logins_go.json`: Histórico de logins
- `messages.json` / `messages_js.json` / `messages_go.json`: Mensagens privadas
- `publications.json` / `publications_js.json` / `publications_go.json`: Publicações em canais

## Relógio Lógico

Implementado conforme algoritmo de Lamport:

1. Cada processo mantém um contador `logical_clock`
2. Antes de enviar mensagem: `clock++`
3. Ao receber mensagem: `clock = max(local_clock, received_clock) + 1`
4. Todas as mensagens incluem o campo `clock`

## Sincronização de Relógio Físico

Implementação simplificada do algoritmo de Berkeley:

1. Servidores mantêm referência ao coordenador eleito
2. A cada 10 mensagens processadas, sincronizam com o coordenador
3. Em produção, seria implementada a coleta de tempos e cálculo de offset

## Eleição de Coordenador

Processo simplificado:

1. Servidores se registram no servidor de referência e recebem rank
2. Servidor com menor rank é eleito coordenador
3. Coordenador publica no tópico `servers` ao ser eleito
4. Todos os servidores atualizam variável `coordinator` ao receber publicação

## Observações de Implementação

- Sistema otimizado para simplicidade e clareza
- Implementação básica de eleição e sincronização (conforme solicitado)
- Replicação focada em dados append-only (usuários e canais)
- Mensagens e publicações persistidas localmente sem replicação completa
- Adequado para demonstração de conceitos de sistemas distribuídos

## Autor

Desenvolvido como projeto da disciplina de Sistemas Distribuídos.

## Licença

Projeto acadêmico sem licença específica.

