# Exemplo de Saída Esperada - Sistema de Mensagens

## 🎬 O que você verá ao executar `docker-compose up --build`

### Fase 1: Build das Imagens (~2 minutos na primeira vez)

```
[+] Building 120.5s (15/15) FINISHED
 => [broker internal] load build definition from Dockerfile
 => => transferring dockerfile: 94B
 => [broker internal] load .dockerignore
 => => transferring context: 2B
 => [broker 1/3] FROM docker.io/library/python:3.13.7-alpine3.21
 => CACHED [broker 2/3] WORKDIR /app
 => [broker 3/3] RUN pip install pyzmq msgpack
 ...
```

### Fase 2: Inicialização dos Containers

```
[+] Running 8/8
 ✔ Network src_default    Created
 ✔ Volume "src_server_data"  Created
 ✔ Container broker       Started
 ✔ Container proxy        Started
 ✔ Container reference    Started
 ✔ Container src-server-1 Started
 ✔ Container src-server-2 Started
 ✔ Container src-server-3 Started
 ✔ Container src-client-1 Started
 ✔ Container src-bot-1    Started
 ✔ Container src-bot-2    Started
```

### Fase 3: Logs dos Servidores

**Broker:**

```
broker    | Broker iniciado
broker    | Porta 5555: ROUTER (clientes)
broker    | Porta 5556: DEALER (servidores)
```

**Proxy:**

```
proxy     | Proxy iniciado
proxy     | Porta 5557: XSUB (publishers)
proxy     | Porta 5558: XPUB (subscribers)
```

**Reference:**

```
reference | Servidor de referência iniciado na porta 5559
reference | Novo servidor registrado: server_abc123 com rank 1
reference | Novo servidor registrado: server_def456 com rank 2
reference | Novo servidor registrado: server_ghi789 com rank 3
reference | Heartbeat recebido de server_abc123
reference | Heartbeat recebido de server_def456
```

**Servidores:**

```
server-1  | Servidor iniciado e conectado ao broker, proxy e referência
server-1  | Servidor server_abc123 registrado com rank 1
server-1  | Heartbeat enviado, status: OK
server-1  | Dados de replicação publicados

server-2  | Servidor iniciado e conectado ao broker, proxy e referência
server-2  | Servidor server_def456 registrado com rank 2
server-2  | Usuário replicado de server_abc123: bot_1234
server-2  | Canal replicado de server_abc123: geral

server-3  | Servidor iniciado e conectado ao broker, proxy e referência
server-3  | Servidor server_ghi789 registrado com rank 3
server-3  | Canal replicado de server_def456: geral
```

**Bots:**

```
bot-1     | Bot iniciado e conectado ao broker e proxy
bot-1     | Tentando login como: bot_1234
bot-1     | Resposta do login: {'service': 'login', 'data': {'status': 'sucesso', 'timestamp': 1699999999.0, 'clock': 5}}
bot-1     | Login bem-sucedido como bot_1234
bot-1     | Nenhum canal disponível, esperando 5 segundos...

bot-2     | Bot iniciado e conectado ao broker e proxy
bot-2     | Tentando login como: bot_5678
bot-2     | Login bem-sucedido como bot_5678
bot-2     | Nenhum canal disponível, esperando 5 segundos...
```

### Fase 4: Cliente Interativo (Você!)

```
client-1  | Cliente iniciado e conectado ao broker e proxy
client-1  | Tentando login como: cliente1
client-1  | Resposta do login: {'service': 'login', 'data': {'status': 'sucesso', 'timestamp': 1699999999.0, 'clock': 8}}
client-1  | Login bem-sucedido como cliente1
client-1  |
client-1  | === Menu ===
client-1  | 1. Listar usuários
client-1  | 2. Criar canal
client-1  | 3. Listar canais
client-1  | 4. Inscrever em canal
client-1  | 5. Enviar mensagem privada
client-1  | 6. Publicar em canal
client-1  | 7. Sair
client-1  |
client-1  | Escolha uma opção (1-7):
```

---

## 🎭 Exemplo de Interação Completa

### Você digita: `2` (Criar canal)

```
client-1  | Escolha uma opção (1-7): 2
client-1  | Nome do canal: geral
```

### Sistema responde:

```
server-2  | Mensagem recebida: {'service': 'channel', 'data': {'channel': 'geral', 'timestamp': 1699999999.0, 'clock': 12}}
server-2  | Resposta enviada: {'service': 'channel', 'data': {'status': 'sucesso', 'timestamp': 1699999999.1, 'clock': 13}}

client-1  | Canal 'geral' criado com sucesso
```

### Você digita: `4` (Inscrever em canal)

```
client-1  | Escolha uma opção (1-7): 4
client-1  | Nome do canal: geral
client-1  | Inscrito no canal 'geral'
```

### Após ~30 segundos - Replicação acontece:

```
server-1  | Dados de replicação publicados
server-3  | Canal replicado de server_def456: geral
server-1  | Canal replicado de server_def456: geral
```

### Bots detectam o canal e começam a publicar:

```
bot-1     | Enviando mensagens para o canal: geral
bot-1     | Mensagem 1/10 publicada: Olá a todos!
server-1  | Mensagem recebida: {'service': 'publish', 'data': {'user': 'bot_1234', 'channel': 'geral', 'message': 'Olá a todos! (msg 1/10)', 'timestamp': 1699999999.5, 'clock': 20}}

bot-2     | Enviando mensagens para o canal: geral
bot-2     | Mensagem 1/10 publicada: Como estão?

client-1  | [CANAL geral - bot_1234]: Olá a todos! (msg 1/10)
client-1  | [CANAL geral - bot_5678]: Como estão? (msg 1/10)
client-1  | [CANAL geral - bot_1234]: Que dia lindo! (msg 2/10)
client-1  | [CANAL geral - bot_5678]: Alguém aí? (msg 2/10)
```

### Você digita: `6` (Publicar mensagem)

```
client-1  | Escolha uma opção (1-7): 6
client-1  | Canal: geral
client-1  | Mensagem: Olá bots! Sou humano!
client-1  | Publicação realizada com sucesso

client-1  | [CANAL geral - cliente1]: Olá bots! Sou humano!
```

### Você digita: `5` (Enviar mensagem privada)

```
client-1  | Escolha uma opção (1-7): 5
client-1  | Destinatário: bot_1234
client-1  | Mensagem: Oi bot!
client-1  | Mensagem enviada com sucesso

# Bot 1 NÃO verá porque não está inscrito no próprio tópico (design)
# Mas o servidor registra a mensagem:
server-3  | Mensagem recebida: {'service': 'message', 'data': {'src': 'cliente1', 'dst': 'bot_1234', 'message': 'Oi bot!', 'timestamp': 1699999999.9, 'clock': 45}}
```

---

## 📊 Logs de Replicação (a cada 30s)

```
server-1  | Dados de replicação publicados
server-2  | Usuário replicado de server_abc123: cliente1
server-2  | Canal replicado de server_abc123: geral
server-3  | Usuário replicado de server_abc123: cliente1
server-3  | Usuário replicado de server_abc123: bot_1234
server-3  | Usuário replicado de server_abc123: bot_5678
server-3  | Canal replicado de server_abc123: geral
```

---

## 🔍 Logs de Heartbeat (a cada 10s)

```
server-1  | Heartbeat enviado, status: OK
reference | Heartbeat recebido de server_abc123

server-2  | Heartbeat enviado, status: OK
reference | Heartbeat recebido de server_def456

server-3  | Heartbeat enviado, status: OK
reference | Heartbeat recebido de server_ghi789
```

---

## ⚠️ Exemplos de Erros (se algo der errado)

### Usuário já existe:

```
client-1  | Escolha uma opção (1-7): (outro cliente tentando login)
server-1  | Mensagem recebida: {'service': 'login', 'data': {'user': 'cliente1', ...}}
server-1  | Resposta enviada: {'service': 'login', 'data': {'status': 'erro', 'description': 'Usuário já existe'}}
client-2  | Erro no login: Usuário já existe
```

### Canal não existe:

```
client-1  | Escolha uma opção (1-7): 6
client-1  | Canal: inexistente
client-1  | Mensagem: teste
server-2  | Mensagem recebida: {'service': 'publish', 'data': {'channel': 'inexistente', ...}}
server-2  | Resposta enviada: {'service': 'publish', 'data': {'status': 'erro', 'message': 'Canal não existe'}}
client-1  | Erro: Canal não existe
```

---

## 🎯 Resumo Visual

```
T=0s    → Containers sobem
T=5s    → Servidores se registram (ranks 1, 2, 3)
T=10s   → Primeiro heartbeat
T=30s   → Primeira replicação de dados
T=40s   → Você cria canal "geral"
T=45s   → Você se inscreve em "geral"
T=70s   → Replicação propaga o canal para todos
T=75s   → Bots detectam canal e começam a publicar
T=80s+  → Você vê mensagens dos bots aparecendo!
```

---

## ✅ Sinais de que está funcionando corretamente:

1. ✅ Todos os containers iniciam sem erros
2. ✅ Servidores recebem ranks (1, 2, 3)
3. ✅ Heartbeats aparecem a cada 10 segundos
4. ✅ Replicação acontece a cada 30 segundos
5. ✅ Cliente mostra menu interativo
6. ✅ Bots publicam mensagens automaticamente
7. ✅ Você vê mensagens dos bots em tempo real
8. ✅ Relógio lógico incrementa em cada mensagem
