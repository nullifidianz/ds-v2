# 🚀 Início Rápido - Sistema de Mensagens Distribuído

## ✅ Teste Mais Simples (1 comando)

Abra o PowerShell na pasta `src` e execute:

```powershell
docker-compose up --build
```

**O que acontece:**

1. Builds das imagens Docker (~2-3 minutos na primeira vez)
2. Inicialização de todos os containers
3. Cliente Python abre com um menu interativo

**No menu do cliente:**

- Digite `2` → Criar canal → Digite `geral` → Enter
- Digite `4` → Inscrever em canal → Digite `geral` → Enter
- Aguarde alguns segundos...
- Você verá mensagens dos bots aparecerem! 🎉

**Para parar:**

- Pressione `Ctrl+C`
- Digite: `docker-compose down`

---

## 🎯 Testes Usando Scripts PowerShell

### Teste 1: Sistema Básico

```powershell
.\teste-basico.ps1
```

Inicia o sistema completo em Python.

### Teste 2: Ver Replicação de Dados

```powershell
.\teste-replicacao.ps1
```

Demonstra como os dados são replicados entre os 3 servidores.

### Teste 3: Ver Logs em Tempo Real

```powershell
.\teste-logs.ps1
```

Abre visualizador de logs interativo.

### Limpar Tudo

```powershell
.\limpar-tudo.ps1
```

Remove todos os containers, volumes e imagens.

---

## 📖 Guia Detalhado

Para ver TODOS os cenários de teste, consulte: **[TESTES.md](TESTES.md)**

---

## 🧪 Teste Rápido de Comunicação

Para verificar que os componentes estão se comunicando:

```powershell
# 1. Subir o sistema
docker-compose up -d

# 2. Ver logs de um servidor
docker-compose logs -f server

# 3. Em outro terminal, ver logs do broker
docker-compose logs -f broker

# 4. Em outro terminal, interagir com o cliente
docker-compose attach client
```

Você verá:

- ✅ Servidor registrando-se no servidor de referência
- ✅ Heartbeats a cada 10 segundos
- ✅ Replicação de dados a cada 30 segundos
- ✅ Mensagens sendo roteadas pelo broker
- ✅ Bots publicando automaticamente

---

## ⚠️ Troubleshooting

### "Cannot connect" ou "Connection refused"

```powershell
# Aguarde alguns segundos - containers ainda estão inicializando
Start-Sleep -Seconds 10
docker-compose ps
```

### Porta já em uso

```powershell
# Ver o que está usando a porta
netstat -ano | findstr "5555"

# Ou simplesmente limpar tudo:
docker-compose down
.\limpar-tudo.ps1
```

### Container não inicia

```powershell
# Ver logs do container específico
docker-compose logs nome-do-servico

# Exemplo:
docker-compose logs broker
docker-compose logs server
```

### Rebuild completo

```powershell
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

---

## 📊 Comandos Úteis

### Ver status de todos os containers

```powershell
docker-compose ps
```

### Ver logs de um serviço

```powershell
docker-compose logs -f server
docker-compose logs -f client
docker-compose logs -f bot
```

### Parar tudo

```powershell
docker-compose down
```

### Parar e remover volumes (limpa dados)

```powershell
docker-compose down -v
```

### Reiniciar um serviço específico

```powershell
docker-compose restart server
```

---

## 🎓 Próximos Passos

1. ✅ Testar sistema básico Python
2. 📖 Ler [TESTES.md](TESTES.md) para testes avançados
3. 🌐 Adicionar servidores JavaScript/Go (veja TESTES.md)
4. 🔍 Explorar persistência de dados
5. 🧪 Testar tolerância a falhas

---

## 💡 Dicas

- Use **Ctrl+C** para parar os containers
- Use `docker-compose logs -f` para acompanhar em tempo real
- Os bots criam mensagens automaticamente após encontrar canais
- Dados são persistidos em volumes Docker
- O broker distribui requisições em round-robin entre os servidores

---

## 📞 Estrutura do Sistema

```
Clientes/Bots → Broker (5555) → Servidores (3 réplicas)
                  ↓
Clientes/Bots ← Proxy (5558) ← Servidores
                  ↓
            Reference (5559) ← Servidores (heartbeat)
```

**Fluxo:**

1. Cliente faz login → Broker → Servidor Python 1
2. Cliente cria canal → Broker → Servidor Python 2
3. Cliente lista canais → Broker → Servidor Python 3
4. Servidores replicam dados entre si a cada 30s
5. Bot publica mensagem → Broker → Servidor
6. Servidor publica no canal → Proxy → Todos inscritos recebem

**Pronto para começar! Execute:** `docker-compose up --build` 🚀
