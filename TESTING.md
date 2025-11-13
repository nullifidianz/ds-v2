## Guia de Testes - DS-v2

Este documento descreve exatamente como testar cada parte do sistema.

Pré-requisitos:

- Docker 20+ e Docker Compose 2+
- Estar no diretório `src/` para rodar os comandos de compose

### 1) Subir o ambiente

```bash
cd src
docker-compose up --build -d
docker-compose ps
```

Ver logs gerais e específicos:

```bash
docker-compose logs -f
docker-compose logs -f server
docker-compose logs -f broker
docker-compose logs -f proxy
docker-compose logs -f reference
docker-compose logs -f bot
```

### 2) Testar o Broker (REQ/REP 5555 ⇄ 5556)

O broker faz proxy entre clientes (ROUTER 5555) e servidores (DEALER 5556).

Passo-a-passo (usa o cliente interativo para gerar tráfego REQ/REP):

```bash
cd src
docker-compose exec client npm start
# No cliente: faça "login", crie canal, liste canais. Observe no terminal:
# - Em server: "Recebido" e "Enviando" para cada requisição
# - Em broker: container ativo e sem erros
```

Verifique que requisições chegam ao `server` nos logs:

- Mensagens "Recebido (...)" e "Enviando (...)" a cada operação.

### 3) Testar o Proxy (PUB/SUB 5557 ⇄ 5558)

O proxy conecta publicadores e assinantes (XPUB/XSUB).

Como observar:

- Ao publicar em um canal no cliente, o `server` deve logar:
  - `Publicado no tópico '<canal>'` e/ou `Publicado no tópico 'replication'`.
- O `bot` deve receber mensagens privadas no seu tópico (o próprio nome):
  - `Bot <nome> recebeu no tópico ...` nos logs do `bot`.

Passo-a-passo rápido:

```bash
cd src
docker-compose logs -f server &
docker-compose logs -f bot &
docker-compose exec client npm start
# Publique em um canal e envie mensagem privada ao bot (nome aparece nos logs do bot).
```

### 4) Testar o Reference (coordenação e ranks, porta 5559)

O `reference` coordena ranks e responde a heartbeats/list.

Validação:

- Nos logs do `server`: "Servidor <id> registrado com rank X" e
  "Lista de servidores atualizada. Coordenador: <id>".

```bash
cd src
docker-compose logs -f reference
docker-compose logs -f server
```

### 5) Testar o Server (serviços login/users/channel/channels/publish/message)

Use o cliente interativo:

```bash
cd src
docker-compose exec client npm start
```

No cliente, valide nesta ordem:

1. Login com um usuário (deve retornar sucesso).
2. Criar um canal (ex.: `canal-teste`).
3. Listar canais (o canal criado deve aparecer).
4. Publicar no canal criado (ver log do `server` com "Publicado no tópico").
5. Enviar mensagem privada para um nome de usuário válido (ver log do `server` e `bot` se aplicável).

Persistência (no `server`):

```bash
cd src
docker-compose exec server cat /data/users.json
docker-compose exec server cat /data/channels.json
docker-compose exec server ls -la /data/messages/
```

### 6) Testar o Client (interativo)

O client roda dentro do container `client`:

```bash
cd src
docker-compose exec client ./start.sh
# ou
docker-compose exec client npm start
```

Se houver erro de script, reconstrua o client:

```bash
cd src
docker-compose build client
docker-compose up -d client
docker-compose exec client ./start.sh
```

### 7) Testar o Bot (automático)

O `bot` faz login, busca canais, cria se necessário e publica mensagens.

```bash
cd src
docker-compose logs -f bot
```

Confirme nos logs:

- "Bot <nome> fazendo login..." seguido de "logado com sucesso".
- "Bot <nome> encontrou X canais" e publicações "publicou no canal ...".

### 8) Testar Replicação e Escala (múltiplos servers)

Subir 3 servidores e verificar ausência de erros "Usuário não encontrado":

```bash
cd src
docker-compose up -d --scale server=3
docker-compose logs -f server
```

Passos:

1. Com o cliente, faça login/crie canal/publique.
2. Observe que não aparecem erros "Usuário '<user>' não encontrado" após as publicações.
3. Veja nos logs "Publicado no tópico 'replication': {type: 'user_login' ...}" e "Usuário replicado: <user>" em servidores não-origem.

Teste de eleição/coordenador:

```bash
cd src
docker-compose logs -f server
# Identifique o coordenador atual nos logs.
# Pare um dos servers (idealmente o coordenador):
docker ps --format "table {{.Names}}\t{{.Image}}" | grep server
docker stop <nome-do-container-server>
# Observe a mensagem de novo coordenador eleito nos outros servers.
```

### 9) Testar Relógios (Lamport e Berkeley)

Lamport:

- Toda requisição/resposta avança o clock. Observe `clock` nos logs do `server` e `bot`.

Berkeley (ajuste periódico após N mensagens):

```bash
cd src
# Gere várias publicações rapidamente (cliente ou bot).
docker-compose logs -f server
# Procure por: "Sincronização Berkeley: ajuste de <valor> segundos"
```

### 10) Testar SERDE (JSON vs MessagePack)

Padrão: MSGPACK. Para testar JSON:

```bash
cd src
SERDE=JSON docker-compose down -v
SERDE=JSON docker-compose up --build -d
docker-compose logs -f server
```

Valide que o `server` imprime: `Servidor iniciado (SERDE=JSON)`.

Para voltar a MSGPACK:

```bash
cd src
docker-compose down -v
docker-compose up --build -d
```

### 11) Verificar dados persistidos

```bash
cd src
docker-compose exec server cat /data/users.json
docker-compose exec server cat /data/channels.json
docker-compose exec server sh -lc 'tail -n +1 /data/messages/*.jsonl 2>/dev/null || true'
```

### 12) Troubleshooting rápido

- Client não inicia com `./start.sh`:
  - Rode `docker-compose build client` e tente novamente.
  - Alternativa: `docker-compose exec client npm start`.
- Erros “Usuário não encontrado” com múltiplos servers:
  - Garanta que todos os containers `server` estão rodando (escala=3).
  - Refaça login e publique novamente (replicação agora aplica eventos idempotentes).
- Portas em uso:
  - Pare tudo: `docker-compose down -v` e suba novamente.
