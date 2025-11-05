# Guia Completo de Testes - Sistema de Mensagens Distribuído

## 🚀 Testes Rápidos (Apenas Python)

### Teste 1: Sistema Básico
```bash
cd src
docker-compose up --build
```

**O que testar:**
1. Aguarde todos os containers iniciarem (~1-2 minutos)
2. Observe o cliente Python mostrando o menu
3. Crie um canal (opção 2): digite "geral"
4. Inscreva-se no canal (opção 4): digite "geral"
5. Aguarde os bots publicarem mensagens automaticamente
6. Você verá as mensagens aparecendo no seu terminal!

**Para parar:**
```bash
Ctrl+C
docker-compose down
```

---

## 🌐 Testes Completos (3 Linguagens)

### Teste 2: Comunicação Entre Linguagens

#### Passo 1: Parar containers existentes
```bash
docker-compose down -v
```

#### Passo 2: Verificar que os arquivos estão corretos
```bash
# Verificar se todos os Dockerfiles existem
ls server-js/Dockerfile
ls server-go/Dockerfile
ls client-js/Dockerfile
ls client-go/Dockerfile
ls bot-js/Dockerfile
```

#### Passo 3: Subir infraestrutura básica
```bash
# Apenas broker, proxy e reference
docker-compose up -d broker proxy reference
```

Aguarde 5 segundos e verifique:
```bash
docker-compose ps
```

Deve mostrar 3 containers rodando.

#### Passo 4: Subir servidores de diferentes linguagens

**Opção A - Apenas Python (3 réplicas):**
```bash
docker-compose up server
```

**Opção B - Um de cada linguagem:**

Primeiro, você precisa criar um docker-compose.override.yml:

```yaml
# Criar arquivo docker-compose.override.yml
services:
  server-python:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./server:/app
      - server_python_data:/data
    depends_on:
      - broker
      - proxy
      - reference
    environment:
      - SERVER_NAME=server_python

  server-js:
    build:
      context: ./server-js
      dockerfile: Dockerfile
    volumes:
      - server_js_data:/data
    depends_on:
      - broker
      - proxy
      - reference
    environment:
      - SERVER_NAME=server_js

  server-go:
    build:
      context: ./server-go
      dockerfile: Dockerfile
    volumes:
      - server_go_data:/data
    depends_on:
      - broker
      - proxy
      - reference
    environment:
      - SERVER_NAME=server_go

volumes:
  server_python_data:
  server_js_data:
  server_go_data:
```

Depois execute:
```bash
docker-compose up server-python server-js server-go
```

#### Passo 5: Ver os logs dos servidores

Em **outro terminal**:

```bash
# Servidor Python
docker-compose logs -f server-python | Select-String "replicado|registrado|Heartbeat"

# Servidor JavaScript (em outro terminal)
docker-compose logs -f server-js | Select-String "replicado|registrado|Heartbeat"

# Servidor Go (em outro terminal)
docker-compose logs -f server-go | Select-String "replicado|registrado|Heartbeat"
```

**O que observar:**
- Cada servidor se registra no servidor de referência
- Cada servidor recebe um rank diferente
- Heartbeats sendo enviados a cada 10 segundos
- Após ~30s, dados começam a ser replicados entre servidores

---

## 🎯 Testes Específicos

### Teste 3: Criar Canal e Ver Replicação

1. Subir sistema:
```bash
docker-compose up -d broker proxy reference server-python server-js server-go
```

2. Subir cliente Python:
```bash
docker-compose up client
```

3. No cliente:
   - Opção 2: Criar canal "teste123"
   - Aguardar 30-40 segundos

4. Verificar replicação:
```bash
# Ver dados do Python
docker exec $(docker ps -qf name=server-python) cat /data/channels.json

# Ver dados do JavaScript
docker exec $(docker ps -qf name=server-js) cat /data/channels_js.json

# Ver dados do Go
docker exec $(docker ps -qf name=server-go) cat /data/channels_go.json
```

Todos devem ter o canal "teste123"! ✅

### Teste 4: Bots de Diferentes Linguagens

1. Subir sistema completo:
```bash
docker-compose up -d broker proxy reference server-python server-js
```

2. Criar canal via cliente:
```bash
docker-compose run --rm client
# Opção 2: criar canal "chat"
# Opção 7: sair
```

3. Subir bots:
```bash
docker-compose up bot-python bot-js
```

**O que observar:**
- Bot Python e Bot JavaScript publicam mensagens no mesmo canal
- Mensagens aparecem intercaladas
- Comunicação perfeita entre linguagens!

### Teste 5: Cliente Go Recebendo de Servidor Python

```bash
# Terminal 1: Infraestrutura + Servidor Python
docker-compose up broker proxy reference server-python

# Terminal 2: Cliente Go
docker-compose run --rm client-go
```

O cliente Go se conectará ao servidor Python e funcionará perfeitamente!

### Teste 6: Verificar Round-Robin do Broker

```bash
# Subir 3 servidores
docker-compose up -d broker proxy reference server-python server-js server-go

# Fazer 6 requisições seguidas
for i in {1..6}; do
  docker-compose run --rm -e USERNAME="user$i" client
  # Apertar opção 7 para sair rapidamente
done

# Ver logs para confirmar distribuição
docker-compose logs server-python | Select-String "login"
docker-compose logs server-js | Select-String "login"
docker-compose logs server-go | Select-String "login"
```

Cada servidor deve ter recebido ~2 requisições (round-robin).

---

## 🔍 Testes de Verificação

### Verificar Relógio Lógico

```bash
# Subir sistema
docker-compose up -d broker proxy reference server-python

# Ver relógio incrementando
docker-compose logs -f server-python | Select-String "clock"
```

Você verá o campo `"clock"` aumentando em cada mensagem.

### Verificar Heartbeats

```bash
docker-compose up -d broker proxy reference server-python server-js

# Observar heartbeats
docker-compose logs -f server-python | Select-String "Heartbeat"
docker-compose logs -f server-js | Select-String "Heartbeat"
```

Deve aparecer a cada 10 segundos.

### Verificar Dados Persistidos

```bash
# Listar volumes
docker volume ls | Select-String "server"

# Verificar conteúdo
docker run --rm -v sistemas-distribuidos-v2_src_server_data:/data alpine ls -la /data
```

---

## 🧪 Teste de Integração Completo

Execute este teste para verificar TUDO:

```bash
# 1. Limpar tudo
docker-compose down -v

# 2. Subir infraestrutura
docker-compose up -d broker proxy reference

# 3. Aguardar 5 segundos
timeout /t 5

# 4. Subir servidores (Python com 3 réplicas)
docker-compose up -d server

# 5. Aguardar 10 segundos
timeout /t 10

# 6. Criar canal via cliente
docker-compose run --rm -e USERNAME=admin client
# Opção 2: criar canal "geral"
# Opção 2: criar canal "avisos"
# Opção 7: sair

# 7. Subir bots
docker-compose up -d bot

# 8. Subir cliente para ver mensagens
docker-compose up client
# Opção 4: inscrever em "geral"
# Aguardar e ver mensagens dos bots!
```

---

## 📊 Comandos Úteis

### Ver todos os containers
```bash
docker-compose ps
```

### Ver logs de todos os servidores
```bash
docker-compose logs -f server
```

### Ver logs de um serviço específico
```bash
docker-compose logs -f server-python
docker-compose logs -f client
docker-compose logs -f bot
```

### Parar um serviço específico
```bash
docker-compose stop server-python
```

### Reiniciar um serviço
```bash
docker-compose restart server-python
```

### Entrar em um container
```bash
docker exec -it $(docker ps -qf name=server-python) sh
```

### Limpar tudo e recomeçar
```bash
docker-compose down -v
docker system prune -f
docker-compose up --build
```

---

## ✅ Checklist de Testes

- [ ] Sistema básico Python funciona
- [ ] Cliente consegue criar canais
- [ ] Cliente consegue se inscrever em canais
- [ ] Bots publicam mensagens automaticamente
- [ ] Cliente recebe mensagens dos bots
- [ ] Servidores se registram no servidor de referência
- [ ] Heartbeats funcionam (logs a cada 10s)
- [ ] Replicação funciona (dados aparecem em todos os servidores após 30s)
- [ ] Relógio lógico incrementa corretamente
- [ ] Dados são persistidos em volume Docker
- [ ] Servidor JS/Go se comunica com cliente Python
- [ ] Bot JS/Go se comunica com servidor Python
- [ ] Round-robin do broker distribui requisições

---

## 🐛 Troubleshooting

### Container não inicia
```bash
docker-compose logs nome-do-servico
```

### Porta já em uso
```bash
# Ver o que está usando as portas
netstat -ano | findstr "5555"
netstat -ano | findstr "5556"

# Matar processo se necessário
taskkill /PID [numero-do-pid] /F
```

### Problemas com volumes
```bash
# Remover todos os volumes
docker-compose down -v

# Rebuild completo
docker-compose build --no-cache
docker-compose up
```

### Container fecha imediatamente
```bash
# Ver logs do container que fechou
docker-compose logs nome-do-servico

# Verificar se os arquivos estão corretos
docker-compose config
```

---

## 🎓 Cenários de Demonstração

### Demonstração 1: Sistema Monolíngua (Python)
"Vou mostrar o sistema básico funcionando apenas em Python"

```bash
docker-compose up --build
```

### Demonstração 2: Replicação Entre Servidores
"Vou mostrar como os dados são replicados entre múltiplos servidores"

```bash
# Ver Teste 3 acima
```

### Demonstração 3: Comunicação Entre Linguagens
"Vou mostrar Python, JavaScript e Go se comunicando"

```bash
# Ver Teste 2, Opção B acima
```

### Demonstração 4: Tolerância a Falhas
"Vou mostrar que se um servidor cair, os outros continuam funcionando"

```bash
# Subir sistema
docker-compose up -d broker proxy reference server

# Derrubar um servidor
docker-compose stop server

# Ver que o cliente ainda funciona (conecta em outro servidor)
docker-compose up client
```

