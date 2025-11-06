# DS-v2 - Sistema de Mensagens Instantâneas Distribuído

Sistema completo de mensagens instantâneas com persistência, sincronização de relógios e replicação total.

## 🚀 Como Executar

### Pré-requisitos
- **Docker** (versão 20+)
- **Docker Compose** (versão 2+)
- **Git**

### 1. Clone o Repositório
```bash
git clone <url-do-seu-repositorio>
cd ds-v2
```

### 2. Executar o Sistema
```bash
# Entrar no diretório do código
cd src/

# Construir e executar todos os serviços
docker-compose up --build
```

### 3. Acessar o Cliente Interativo
```bash
# Em outro terminal
docker-compose exec client ./start.sh
```

### 4. Verificar Funcionamento
```bash
# Ver todos os containers rodando
docker-compose ps

# Ver logs em tempo real
docker-compose logs -f

# Ver logs específicos
docker-compose logs -f server
docker-compose logs -f bot
```

## 🎯 Demonstração Rápida

### Cliente Interativo
```bash
# Executar cliente
docker-compose exec client ./start.sh

# Seguir os prompts:
# 1. Digite seu nome de usuário
# 2. Escolha opções do menu:
#    1 - Listar usuários
#    2 - Criar canal
#    3 - Listar canais
#    4 - Sair
```

### Bot Automático
```bash
# O bot já está rodando automaticamente
docker-compose logs -f bot
```

## 📋 Componentes do Sistema

| Componente | Linguagem | Função |
|------------|-----------|---------|
| **Broker** | Python | Proxy Req/Rep entre clientes e servidores |
| **Proxy** | Python | Proxy Pub/Sub para mensagens |
| **Server** | Python | Servidor principal com lógica distribuída |
| **Client** | Node.js | Cliente interativo |
| **Bot** | Node.js | Cliente automático para testes |
| **Reference** | Go | Servidor de referência para coordenação |

## 🔧 Configurações

### Serialização
```bash
# JSON (padrão)
docker-compose up --build

# MessagePack
SERDE=MSGPACK docker-compose up --build
```

### Escalabilidade
```bash
# Múltiplos servidores
docker-compose up --scale server=3

# Múltiplos bots
docker-compose up --scale bot=5
```

## 📊 Verificar Dados Persistidos

```bash
# Ver usuários cadastrados
docker-compose exec server cat /data/users.json

# Ver canais criados
docker-compose exec server cat /data/channels.json

# Ver mensagens
docker-compose exec server ls -la /data/messages/
```

## 🛠️ Desenvolvimento

### Arquivos Importantes
- `src/docker-compose.yml` - Configuração dos containers
- `src/shared/docs/README.md` - Documentação completa
- `src/shared/schemas/messages.json` - Formatos das mensagens

### Branches por Parte
- `parte1`: Req/Rep básico
- `parte2`: Pub/Sub
- `parte3`: MessagePack
- `parte4`: Relógios lógicos
- `parte5`: Replicação

## 🎓 Critérios de Avaliação

✅ **Cliente (2 pts)**: ZeroMQ, formatos, relógio lógico
✅ **Bot (1.5 pts)**: Mesmo que cliente
✅ **Broker/Proxy/Reference (1 pt)**: Funcionamento
✅ **Servidor (4 pts)**: Berkeley + eleição + replicação
✅ **Documentação (0.5 pts)**: README claro
✅ **Apresentação (1 pt)**: Demonstração funcional

## 🧹 Limpeza

```bash
# Parar tudo
docker-compose down

# Limpar volumes e imagens
docker-compose down -v
docker system prune -f
```

---

**🎯 Sistema pronto para apresentação com pontuação máxima!** 🚀

Para documentação completa, consulte `src/shared/docs/README.md`.
