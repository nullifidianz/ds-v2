# 🚀 Início Rápido - Sistema Multi-Linguagem

## ✅ Sistema Pronto!

Seu sistema agora suporta comunicação entre **Python, JavaScript e Go**!

---

## 🎯 3 Formas de Testar

### 1️⃣ **Teste Mais Simples** (Server Python + Client JS + Bot Go)

```powershell
cd src
.\teste-multilang.ps1
```

**OU**

```powershell
cd src
docker-compose -f docker-compose.multilang.yml up --build
```

**O que acontece:**
- Servidor Python processa requisições
- Cliente JavaScript se conecta e cria canal
- Bot Go publica mensagens automaticamente
- **Todos se comunicam via ZeroMQ + MessagePack!**

---

### 2️⃣ **Teste Completo** (TODAS as Linguagens)

```powershell
cd src
.\teste-all-langs.ps1
```

**OU**

```powershell
cd src
docker-compose -f docker-compose.all-langs.yml up --build
```

**O que acontece:**
- 3 Servidores (Python + JS + Go)
- 3 Clientes (Python + JS + Go)
- 3 Bots (Python + JS + Go)
- **12 containers se comunicando!**

---

### 3️⃣ **Teste Básico** (Apenas Python)

```powershell
cd src
.\teste-basico.ps1
```

**OU**

```powershell
cd src
docker-compose up --build
```

---

## 📊 Como Verificar a Comunicação

### Ver Bot Go se comunicando com Servidor Python

```powershell
# Terminal 1: Servidor Python
docker-compose -f docker-compose.multilang.yml logs -f server-python

# Terminal 2: Bot Go
docker-compose -f docker-compose.multilang.yml logs -f bot-go
```

**Você verá:**
```
bot-go        | Bot Go iniciado
bot-go        | Tentando login como: bot_go_1234
server-python | Mensagem recebida: {'service': 'login', 'data': {'user': 'bot_go_1234', ...}}
server-python | Resposta enviada: {'service': 'login', 'data': {'status': 'sucesso', ...}}
bot-go        | Login bem-sucedido como bot_go_1234
bot-go        | Enviando mensagens para o canal: teste
server-python | Mensagem recebida: {'service': 'publish', 'data': {'user': 'bot_go_1234', ...}}
```

### Ver Cliente JS recebendo do Servidor Python

```powershell
docker-compose -f docker-compose.multilang.yml logs -f client-js
```

**Você verá:**
```
client-js | Cliente JS iniciado
client-js | Tentando login como: cliente_js
client-js | Resposta do login: { service: 'login', data: { status: 'sucesso', ... } }
client-js | Login bem-sucedido como cliente_js
client-js | Criando canal de teste...
client-js | Canal criado
```

---

## 🔍 Provar Comunicação Entre Linguagens

### Comando Mágico 🪄

```powershell
# Ver TODAS as comunicações entre linguagens
docker-compose -f docker-compose.multilang.yml logs -f | Select-String "bot_go|cliente_js|server_python"
```

**Você verá mensagens como:**
```
server-python | Servidor server_python_abc123 registrado
client-js     | Login bem-sucedido como cliente_js
bot-go        | Login bem-sucedido como bot_go_1234
server-python | Mensagem recebida de bot_go_1234
server-python | Resposta enviada para cliente_js
```

**Isso prova que Python, JavaScript e Go estão se comunicando!** ✅

---

## 🎓 Para Apresentação/Demonstração

### Setup Recomendado

**3 Terminais lado a lado:**

**Terminal 1 (esquerda):**
```powershell
docker-compose -f docker-compose.multilang.yml logs -f server-python
```

**Terminal 2 (centro):**
```powershell
docker-compose -f docker-compose.multilang.yml logs -f client-js
```

**Terminal 3 (direita):**
```powershell
docker-compose -f docker-compose.multilang.yml logs -f bot-go
```

Inicie o sistema:
```powershell
docker-compose -f docker-compose.multilang.yml up -d
```

**Demonstre:**
1. Bot Go enviando mensagem (Terminal 3)
2. Servidor Python recebendo (Terminal 1)
3. Cliente JS processando (Terminal 2)

**Evidência visual de comunicação entre 3 linguagens!** 🎉

---

## 📋 Estrutura dos Arquivos

```
src/
├── bot-go/                           ← NOVO! Bot em Go
│   ├── main.go
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── docker-compose.yml                ← Python apenas
├── docker-compose.multilang.yml      ← NOVO! Python + JS + Go
├── docker-compose.all-langs.yml      ← NOVO! Todas as linguagens
├── teste-multilang.ps1               ← NOVO! Script de teste
├── teste-all-langs.ps1               ← NOVO! Teste completo
└── COMUNICACAO-MULTILINGUAGEM.md     ← NOVO! Guia detalhado
```

---

## 🛠️ Comandos Úteis

### Iniciar em background
```powershell
docker-compose -f docker-compose.multilang.yml up -d
```

### Ver logs específicos
```powershell
docker-compose -f docker-compose.multilang.yml logs -f [service-name]
```

### Parar tudo
```powershell
docker-compose -f docker-compose.multilang.yml down
```

### Limpar e recomeçar
```powershell
docker-compose -f docker-compose.multilang.yml down -v
docker-compose -f docker-compose.multilang.yml up --build
```

---

## ✨ Configurações Disponíveis

| Arquivo | Servidores | Clientes | Bots | Linguagens |
|---------|-----------|----------|------|------------|
| `docker-compose.yml` | 3x Python | 1x Python | 2x Python | 1 (Python) |
| `docker-compose.multilang.yml` | 1x Python | 1x JS | 1x Go | 3 (Py+JS+Go) |
| `docker-compose.all-langs.yml` | 1 de cada | 1 de cada | 1 de cada | 3 (completo) |

---

## 🎯 Checklist de Testes

- [ ] Sistema básico Python funciona
- [ ] Bot Go compila e inicia
- [ ] Cliente JS conecta no servidor Python
- [ ] Bot Go envia mensagens para servidor Python
- [ ] Servidor Python responde para cliente JS
- [ ] Ver comunicação nos logs
- [ ] Sistema completo com todas linguagens
- [ ] Demonstração para apresentação preparada

---

## 💡 Dicas

1. **Primeira execução demora** ~3-5 minutos (build das imagens)
2. **Execuções seguintes** são instantâneas
3. **Use `-d`** para rodar em background e ver logs separadamente
4. **Cliente JS e Bot Go** são automáticos (não precisam de interação)
5. **Cliente Python** é interativo (tem menu)

---

## 🐛 Problemas?

### Bot Go não compila
```powershell
# Rebuild sem cache
docker-compose -f docker-compose.multilang.yml build --no-cache bot-go
```

### Cliente JS não conecta
```powershell
# Ver logs detalhados
docker-compose -f docker-compose.multilang.yml logs client-js
```

### Porta em uso
```powershell
# Limpar tudo
docker-compose -f docker-compose.multilang.yml down
docker-compose down
```

---

## 🎊 Pronto!

**Para começar agora:**

```powershell
cd C:\Users\Jota\Documents\PROJETOS\sistemas-distribuidos-v2\src
.\teste-multilang.ps1
```

**Sistema com Python, JavaScript e Go se comunicando!** 🚀

