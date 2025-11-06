# DS-v2 - Sistema de Mensagens Instantâneas

Sistema distribuído para troca de mensagens privadas e publicações em canais, baseado em ZeroMQ com persistência, sincronização de relógios e replicação completa.

## Componentes

- **Broker** (Python): Proxy Req/Rep entre clientes e servidores
- **Proxy** (Python): Proxy Pub/Sub para mensagens
- **Server** (Python): Servidor principal com persistência, relógio lógico e replicação
- **Client** (Node.js): Cliente interativo
- **Bot** (Node.js): Cliente automático para testes de carga
- **Reference** (Go): Servidor de referência para ranks, eleição e sincronização

## Tecnologias

- **Python** (broker, proxy, server): `pyzmq`, `msgpack`
- **Node.js** (client, bot): `zeromq`, `@msgpack/msgpack`
- **Go** (reference): `zmq4`, `msgpack/v5`
- **ZeroMQ** para mensageria
- **MessagePack/JSON** para serialização (configurável via `SERDE`)
- **Arquivos JSON** para persistência
- **Relógio Lógico de Lamport** em todos os processos
- **Algoritmo de Berkeley** para sincronização física
- **Bully Algorithm** para eleição de coordenador

## Arquitetura

```
Clients/Bots --Req/Rep--> Broker --Req/Rep--> Servers
                    |
                    +--Pub/Sub--> Proxy --Pub/Sub--> Clients/Bots
                    |
Reference <--Req/Rep--> Servers (ranks, heartbeats, eleição)
                    |
Servers <--Pub/Sub--> replication (eventos de write)
```

## Formatos de Mensagem

### Protocolo Base
Todas as mensagens seguem o formato:
```json
{
  "service": "nome_servico",
  "data": {
    "campo1": "valor1",
    "timestamp": 1234567890,
    "clock": 42
  }
}
```

### Serviços Implementados

#### Req/Rep Services
- **login**: Cadastro de usuário
- **users**: Lista usuários cadastrados
- **channel**: Criação de canal público
- **channels**: Lista canais disponíveis
- **publish**: Publicação em canal
- **message**: Mensagem privada

#### Pub/Sub Topics
- `{username}`: Mensagens privadas
- `{channel}`: Publicações no canal
- `servers`: Anúncios de eleição
- `replication`: Eventos de replicação

## Persistência

- **Usuários**: `data/users.json`
- **Canais**: `data/channels.json`
- **Mensagens**: `data/messages/{publishes,messages}.jsonl`
- Formato: JSON Lines (um evento por linha)

## Relógios e Sincronização

### Relógio Lógico (Lamport)
- Implementado em todos os processos
- Incremento antes de enviar mensagens
- `max(local, received) + 1` ao receber
- Campo `clock` em todas as mensagens

### Sincronização Física (Berkeley)
- Executada pelo coordenador a cada 10 mensagens
- Coordenador = servidor com menor rank ativo
- Ajuste baseado na média dos relógios

### Eleição de Coordenador
- **Bully Algorithm**: Servidor com maior rank ganha
- Gatilho: Coordenador para de responder heartbeats
- Anúncio via Pub/Sub no tópico `servers`

## Replicação

### Estratégia
- **Streaming de Eventos**: Cada write gera evento no tópico `replication`
- **Aplicação Idempotente**: Eventos aplicados por `(clock, server_id)`
- **Total Order**: Lamport clock garante ordenação causal

### Eventos Replicados
- `user_login`: Novo usuário
- `channel_create`: Novo canal
- `message_publish`: Publicação em canal
- `message_send`: Mensagem privada

### Consistência
- **Last Write Wins**: Conflitos resolvidos por Lamport timestamp
- **Idempotência**: Eventos duplicados ignorados
- **Recuperação**: Eventos replay após restart

## Execução

### Pré-requisitos
- Docker e Docker Compose
- Portas 5555-5559 disponíveis

### Comandos

```bash
# Construir e executar tudo
cd src/
docker-compose up --build

# Cliente interativo
docker-compose exec client bash

# Ver logs específicos
docker-compose logs -f server
docker-compose logs -f reference

# Alterar serialização
SERDE=MSGPACK docker-compose up --build

# Escalar servidores
docker-compose up --scale server=5

# Limpar
docker-compose down -v
```

### Configuração
- **SERDE**: `JSON` (padrão) ou `MSGPACK`
- **SERVER_NAME**: Nome do servidor (para múltiplas instâncias)
- **Dados**: Montados em volume `data/`

## Desenvolvimento

### Branches por Parte
1. **parte1**: Req/Rep básico (login, users, channels)
2. **parte2**: Pub/Sub (publish, message, bot)
3. **parte3**: MessagePack
4. **parte4**: Relógios lógicos + referência + Berkeley
5. **parte5**: Replicação completa

### Testes por Parte

#### Parte 1
```bash
# Testar login
docker-compose exec client bash
# Digitar nome de usuário

# Verificar persistência
docker-compose exec server cat /data/users.json
```

#### Parte 2
```bash
# Bot deve publicar automaticamente
docker-compose logs -f bot

# Cliente deve receber mensagens
docker-compose exec client bash
# Inscrever-se em canal criado pelo bot
```

#### Parte 4
```bash
# Verificar relógios nos logs
docker-compose logs -f server | grep clock

# Testar eleição (parar referência)
docker-compose stop reference
docker-compose logs -f server | grep coordinator
```

#### Parte 5
```bash
# Verificar replicação
docker-compose logs -f server | grep "replicad"

# Testar consistência (parar um servidor)
docker-compose stop server
# Verificar se outros têm os dados
```

## Critérios de Avaliação

- **Cliente (2 pts)**: Uso correto de ZeroMQ, formatos, relógio lógico
- **Bot (1.5 pts)**: Mesmo que cliente
- **Broker/Proxy/Referência (1 pt)**: Funcionamento correto
- **Servidor (4 pts)**: Tudo acima + Berkeley + eleição + replicação
- **Documentação (0.5 pts)**: README completo e claro
- **Apresentação (1 pt)**: Demonstração funcional

## Decisões de Design

### Linguagens
- **Python**: Melhor suporte a ZeroMQ e threading para servidor complexo
- **Node.js**: Simplicidade para clientes interativos
- **Go**: Performance para servidor de referência com alta concorrência

### Persistência
- **JSON**: Simples, legível, suficiente para protótipo
- **JSONL**: Append-only para mensagens, eficiente para replicação

### Replicação
- **Event Sourcing**: Permite rebuild consistente
- **Lamport Ordering**: Garante causalidade sem relógio físico
- **Total Replication**: Simplicidade vs. sharding futuro

### Sincronização
- **Berkeley**: Adequado para poucos servidores
- **Bully**: Simples de implementar vs. Raft/Paxos

## Limitações

- Não há autenticação/autorização
- Replicação síncrona (não tolerante a falhas de rede)
- Berkeley não ajusta relógio do sistema (apenas logging)
- Eleição não trata particionamento de rede
- Não há compactação de eventos antigos

## Extensões Futuras

- Autenticação JWT
- Compressão de mensagens
- Sharding horizontal
- Consensus avançado (Raft)
- Cache distribuído (Redis)
- Interface web (React)
- Métricas e monitoring (Prometheus)
