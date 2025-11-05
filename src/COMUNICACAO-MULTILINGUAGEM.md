# 🌐 Comunicação Multi-Linguagem

## ✅ Sistema Configurado

Seu sistema está configurado com:
- **Servidor Python** (recebe requisições)
- **Cliente JavaScript** (interface)
- **Bot Go** (publicações automáticas)

Todos se comunicam via **ZeroMQ + MessagePack**!

---

## 🚀 Como Executar

### Opção 1: Comando Direto
```powershell
cd src
docker-compose -f docker-compose.multilang.yml up --build
```

### Opção 2: Usando Script
```powershell
cd src
.\teste-multilang.ps1
```

---

## 📊 O Que Você Verá

```
broker        | Broker iniciado (Python)
proxy         | Proxy iniciado (Python)
reference     | Servidor de referência iniciado (Python)

server-python | Servidor Python iniciado
server-python | Servidor server_python_abc123 registrado com rank 1

client-js     | Cliente JS iniciado e conectado
client-js     | Tentando login como: cliente_js
server-python | Mensagem recebida de cliente JS: {'service': 'login', ...}
client-js     | Login bem-sucedido como cliente_js

bot-go        | Bot Go iniciado e conectado
bot-go        | Tentando login como: bot_go_1234
server-python | Mensagem recebida de bot Go: {'service': 'login', ...}
bot-go        | Login bem-sucedido como bot_go_1234
```

---

## 🎯 Fluxo de Comunicação

```
Bot Go (Golang)
    ↓ MessagePack
Broker (Python)
    ↓ Round-robin
Servidor Python
    ↓ MessagePack via Proxy
Cliente JS (Node.js)
```

**Exemplo real:**
1. **Bot Go** publica "Olá do bot Go!" no canal "geral"
2. Mensagem vai para **Servidor Python** via MessagePack
3. **Servidor Python** processa e publica no Proxy
4. **Cliente JS** recebe a mensagem e exibe

---

## 🧪 Teste de Comunicação

Para testar que as linguagens estão se comunicando:

```powershell
# 1. Subir o sistema
docker-compose -f docker-compose.multilang.yml up -d

# 2. Ver logs do servidor Python
docker-compose -f docker-compose.multilang.yml logs -f server-python

# 3. Em outro terminal, ver logs do cliente JS
docker-compose -f docker-compose.multilang.yml logs -f client-js

# 4. Em outro terminal, ver logs do bot Go
docker-compose -f docker-compose.multilang.yml logs -f bot-go
```

---

## 📋 Verificar Comunicação

### Ver mensagem do Bot Go chegando no Servidor Python:
```powershell
docker-compose -f docker-compose.multilang.yml logs server-python | Select-String "bot_go"
```

Você verá:
```
server-python | Mensagem recebida: {'service': 'login', 'data': {'user': 'bot_go_1234', ...}}
server-python | Mensagem recebida: {'service': 'publish', 'data': {'user': 'bot_go_1234', ...}}
```

### Ver Cliente JS recebendo do Servidor Python:
```powershell
docker-compose -f docker-compose.multilang.yml logs client-js
```

Você verá:
```
client-js | Resposta do login: { service: 'login', data: { status: 'sucesso', ... } }
client-js | Criando canal de teste...
client-js | Canal criado
```

---

## 🔄 Outras Configurações Disponíveis

### Configuração 1: Server Python + Client Python + Bot Go
```yaml
# Edite docker-compose.multilang.yml
services:
  server-python: ...
  
  client-python:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./client:/app
    environment:
      - USERNAME=cliente_python
  
  bot-go: ...
```

### Configuração 2: Server JS + Client Go + Bot Python
```yaml
services:
  server-js:
    build:
      context: ./server-js
      dockerfile: Dockerfile
    ...
  
  client-go:
    build:
      context: ./client-go
      dockerfile: Dockerfile
    ...
  
  bot-python:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./bot:/app
    ...
```

### Configuração 3: Todos Misturados (1 de cada)
```yaml
services:
  server-python: ...
  server-js: ...
  server-go: ...
  
  client-python: ...
  client-js: ...
  client-go: ...
  
  bot-python: ...
  bot-js: ...
  bot-go: ...
```

---

## ✅ Confirmação de Funcionamento

Você saberá que está funcionando quando ver:

1. ✅ Bot Go faz login com sucesso
2. ✅ Cliente JS faz login com sucesso
3. ✅ Servidor Python recebe mensagens de ambos
4. ✅ Bot Go publica mensagens
5. ✅ Cliente JS cria canal automaticamente
6. ✅ Bot Go detecta canal e publica nele

---

## 🎓 Demonstrar na Apresentação

Para mostrar comunicação entre linguagens:

```powershell
# Terminal 1: Logs do servidor Python
docker-compose -f docker-compose.multilang.yml logs -f server-python

# Terminal 2: Logs do bot Go
docker-compose -f docker-compose.multilang.yml logs -f bot-go

# Terminal 3: Logs do cliente JS
docker-compose -f docker-compose.multilang.yml logs -f client-js
```

Organize os terminais lado a lado e mostre:
- **Bot Go** enviando mensagem
- **Servidor Python** recebendo
- **Cliente JS** exibindo

**Prova visual da comunicação multi-linguagem!** 🎉

---

## 🛑 Parar Sistema

```powershell
# Parar containers
Ctrl+C

# Remover containers
docker-compose -f docker-compose.multilang.yml down

# Limpar tudo (incluindo dados)
docker-compose -f docker-compose.multilang.yml down -v
```

---

## 💡 Arquivos Criados

- `src/bot-go/main.go` - Bot em Go
- `src/bot-go/go.mod` - Dependências Go
- `src/bot-go/go.sum` - Checksums Go
- `src/bot-go/Dockerfile` - Build do Go
- `src/docker-compose.multilang.yml` - Orquestração multi-linguagem

---

## 🎯 Próximos Passos

1. ✅ Testar configuração atual (Python + JS + Go)
2. 🔄 Experimentar outras combinações
3. 📊 Monitorar logs para ver comunicação
4. 🎓 Preparar demonstração para apresentação

**Sistema pronto para demonstrar comunicação entre 3 linguagens!** 🚀

