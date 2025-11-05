# Scripts de Teste Completo

Estes scripts testam automaticamente **TODOS** os critérios de avaliação do projeto.

## 📋 O que é testado

Os scripts verificam todos os 6 critérios de avaliação:

### 1. Cliente (2 pontos)

- ✓ Uso correto de ZeroMQ e MessagePack
- ✓ Padrão de mensagens seguido
- ✓ Relógio lógico implementado
- ✓ Funcionamento verificado nos logs

### 2. Bot (1.5 pontos)

- ✓ Uso correto das bibliotecas
- ✓ Padrão de mensagens seguido
- ✓ Publicações automáticas funcionando

### 3. Broker, Proxy e Referência (1 ponto)

- ✓ Broker ROUTER/DEALER implementado
- ✓ Proxy XPUB/XSUB implementado
- ✓ Servidor de referência com rank, list e heartbeat
- ✓ Todos os componentes rodando

### 4. Servidor (4 pontos)

- ✓ Uso correto das bibliotecas
- ✓ Padrão de mensagens seguido
- ✓ Relógio lógico implementado
- ✓ Sincronização de relógio (Berkeley)
- ✓ Eleição de coordenador
- ✓ Sincronização de dados entre servidores

### 5. Documentação (0.5 ponto)

- ✓ README.md completo
- ✓ Guias de teste disponíveis
- ✓ Documentação de arquitetura

### 6. Apresentação (1 ponto)

- ✓ Todos os componentes demonstráveis
- ✓ Sistema funcionando end-to-end

---

## 🪟 Windows (PowerShell)

### Executar o teste completo

```powershell
cd src
.\teste-completo.ps1
```

### O que o script faz

1. Limpa ambiente anterior
2. Inicia sistema completo com Docker
3. Aguarda inicialização (15 segundos)
4. Testa cada critério de avaliação:
   - Verifica código-fonte
   - Analisa logs dos containers
   - Testa replicação de dados
   - Valida documentação
5. Gera relatório final com pontuação

### Requisitos

- PowerShell 5.1 ou superior
- Docker Desktop instalado e rodando
- Docker Compose configurado

### Tempo estimado

- **Primeira execução**: ~5-8 minutos (build das imagens)
- **Execuções subsequentes**: ~2-3 minutos (imagens em cache)

---

## 🐧 Linux / macOS (Bash)

### Executar o teste completo

```bash
cd src
chmod +x teste-completo.sh  # Apenas na primeira vez
./teste-completo.sh
```

### O que o script faz

Mesmas verificações da versão Windows, mas usando sintaxe bash.

### Requisitos

- Bash 4.0 ou superior
- Docker instalado e rodando
- Docker Compose instalado
- `jq` instalado (para processar JSON)

**Instalar jq:**

Ubuntu/Debian:

```bash
sudo apt-get install jq
```

macOS:

```bash
brew install jq
```

### Tempo estimado

- **Primeira execução**: ~5-8 minutos (build das imagens)
- **Execuções subsequentes**: ~2-3 minutos (imagens em cache)

---

## 📊 Interpretando os Resultados

### Símbolos

- `[✓]` - Teste passou com sucesso (verde)
- `[✗]` - Teste falhou (vermelho)
- `[!]` - Aviso ou informação (amarelo)

### Pontuação

O script gera um relatório final com:

```
PONTUAÇÕES POR CRITÉRIO:
  1. Cliente........................: 2.0/2.0
  2. Bot............................: 1.5/1.5
  3. Broker/Proxy/Referência........: 1.0/1.0
  4. Servidor.......................: 4.0/4.0
  5. Documentação...................: 0.5/0.5
  6. Apresentação...................: 1.0/1.0

  PONTUAÇÃO TOTAL: 10.0/10.0

  🎉 PARABÉNS! NOTA MÁXIMA!
```

### Interpretação das notas

- **10.0**: Nota máxima - Todos os critérios atendidos
- **9.0-9.9**: Excelente - Projeto quase perfeito
- **7.0-8.9**: Bom - Maioria dos critérios atendidos
- **< 7.0**: Atenção - Revisar critérios que falharam

---

## 🔍 O que cada seção verifica

### Teste do Cliente

Verifica no código:

- Importações de `zmq` e `msgpack`
- Uso de sockets REQ e SUB
- Padrão `{"service": "...", "data": {...}}`
- Serialização com `msgpack.packb()`
- Variáveis e funções de relógio lógico

Verifica nos logs:

- Mensagem "Cliente iniciado"
- Confirmação de login bem-sucedido

### Teste do Bot

Verifica no código:

- Bibliotecas corretas
- Padrão de mensagens

Verifica nos logs:

- Inicialização do bot
- Login realizado
- Mensagens sendo publicadas

### Teste do Broker/Proxy/Referência

Verifica no código:

- Sockets ROUTER/DEALER no broker
- Sockets XPUB/XSUB no proxy
- Serviços rank, list, heartbeat no reference

Verifica nos logs:

- Componentes rodando
- Servidores se registrando

### Teste do Servidor

Verifica no código:

- Bibliotecas ZeroMQ e MessagePack
- Relógio lógico completo
- Código de sincronização de relógio
- Eleição de coordenador
- Replicação de dados

Verifica nos logs:

- Registro com rank
- Heartbeats a cada 10 segundos
- Publicação de dados de replicação

Verifica replicação real:

- Aguarda 35 segundos
- Compara arquivos `/data/users.json` entre servidores
- Confirma que dados foram replicados

### Teste da Documentação

Verifica arquivos:

- `README.md` na raiz
- `TESTES.md` com guias
- `INICIO-RAPIDO.md` com quick start

Verifica conteúdo:

- Documentação de arquitetura
- Funcionalidades descritas
- Instruções de execução

### Teste de Apresentação

Verifica:

- Todos os containers rodando
- Cada componente demonstrável
- Scripts de teste disponíveis

---

## 🐛 Troubleshooting

### Erro: "Containers não iniciaram"

```bash
# Limpar tudo e tentar novamente
docker-compose down -v
docker system prune -f
docker-compose build --no-cache
./teste-completo.sh  # ou .ps1 no Windows
```

### Erro: "Replicação não verificada"

É normal na primeira execução se os containers ainda estão inicializando.
O script aguarda 35 segundos, mas às vezes pode precisar de mais tempo.

**Solução**: Execute o script novamente (containers já estarão rodando).

### Erro: "jq: command not found" (Linux)

Instale o jq:

```bash
sudo apt-get install jq
```

### Containers ficam "Exited"

Verifique logs do container específico:

```bash
docker-compose logs <nome-do-servico>
```

### Porta já em uso

```bash
# Ver o que está usando as portas
netstat -tuln | grep 5555
netstat -tuln | grep 5556

# Parar containers anteriores
docker-compose down
```

---

## 📝 Exemplos de Uso

### Teste rápido antes da apresentação

```bash
# Limpar tudo
docker-compose down -v

# Executar teste completo
./teste-completo.sh

# Verificar que tudo está OK
# Deixar containers rodando para apresentação
```

### Teste após fazer alterações

```bash
# Não limpar (usar dados existentes)
# Apenas rebuild dos containers modificados
docker-compose up -d --build

# Executar teste
./teste-completo.sh
```

### Limpar depois do teste

```bash
# Parar containers
docker-compose down

# Ou limpar volumes também
docker-compose down -v
```

---

## 🎯 Dicas para Apresentação

1. **Execute o script antes da apresentação** para garantir que tudo funciona

2. **Deixe os containers rodando** após o teste para poder demonstrar

3. **Prepare-se para mostrar**:

   - Logs de heartbeats: `docker-compose logs server | grep Heartbeat`
   - Logs de replicação: `docker-compose logs server | grep replicação`
   - Dados replicados: `docker exec <container> cat /data/users.json`

4. **Tenha o relatório do script à mão** para mostrar os checkmarks verdes

5. **Demonstre comunicação multi-linguagem**:
   ```bash
   docker-compose -f docker-compose.multilang.yml up -d
   docker-compose -f docker-compose.multilang.yml logs bot-go
   ```

---

## 📞 Estrutura dos Scripts

Ambos os scripts seguem a mesma estrutura:

1. **Inicialização**: Limpa ambiente e inicia sistema
2. **Testes de código**: Verifica implementação no código-fonte
3. **Testes de runtime**: Verifica comportamento nos logs
4. **Testes de integração**: Verifica replicação real de dados
5. **Relatório final**: Pontuação detalhada por critério

---

## ✅ Checklist Pré-Apresentação

Use este checklist antes de apresentar:

- [ ] Script de teste completo executado com sucesso
- [ ] Pontuação 10.0/10.0 alcançada
- [ ] Todos os containers rodando
- [ ] Heartbeats visíveis nos logs
- [ ] Replicação funcionando entre servidores
- [ ] Bot publicando mensagens
- [ ] Cliente interativo funcionando
- [ ] Documentação completa e atualizada
- [ ] Teste multi-linguagem funcionando

---
