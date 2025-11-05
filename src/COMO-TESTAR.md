# 🧪 Como Testar o Projeto

Guia rápido para executar os testes do projeto.

## 📦 Scripts Disponíveis

### 1. **Teste Completo** (Recomendado para validação)
Testa **TODOS** os critérios de avaliação detalhadamente.

**Windows:**
```powershell
cd src
.\teste-completo.ps1
```

**Linux/macOS:**
```bash
cd src
chmod +x teste-completo.sh  # Apenas primeira vez
./teste-completo.sh
```

**Duração:** 2-3 minutos  
**O que faz:** Verifica código-fonte, logs, replicação e gera relatório com pontuação

---

### 2. **Demonstração Rápida** (Recomendado para apresentação)
Mostra o sistema funcionando rapidamente.

**Windows:**
```powershell
cd src
.\teste-demonstracao.ps1
```

**Linux/macOS:**
```bash
cd src
chmod +x teste-demonstracao.sh  # Apenas primeira vez
./teste-demonstracao.sh
```

**Duração:** 30 segundos  
**O que faz:** Mostra containers, logs relevantes e status geral

---

### 3. **Testes Específicos** (Para desenvolvedores)

#### Sistema Básico (Python)
```powershell
cd src
.\teste-basico.ps1
```

#### Comunicação Multi-Linguagem
```powershell
cd src
.\teste-multilang.ps1
```

#### Teste de Replicação
```powershell
cd src
.\teste-replicacao.ps1
```

---

## 🎯 Qual Script Usar?

### Antes de Entregar o Projeto
✅ Use: **teste-completo** (ps1 ou sh)  
📋 Para: Validar todos os critérios de avaliação  
⏱️ Execute com calma e leia o relatório

### Durante a Apresentação
✅ Use: **teste-demonstracao** (ps1 ou sh)  
📋 Para: Mostrar rapidamente que tudo funciona  
⏱️ Execução rápida, perfeito para demonstrar

### Para Desenvolvimento
✅ Use: **teste-basico** ou scripts específicos  
📋 Para: Testar funcionalidades individuais  
⏱️ Testes rápidos e focados

---

## 🚀 Uso Básico

### Primeira Vez (com limpeza)

**Windows:**
```powershell
cd src
docker-compose down -v
.\teste-completo.ps1
```

**Linux:**
```bash
cd src
docker-compose down -v
./teste-completo.sh
```

### Execuções Seguintes (mais rápido)

**Windows:**
```powershell
cd src
.\teste-completo.ps1
```

**Linux:**
```bash
cd src
./teste-completo.sh
```

---

## 📊 Entendendo os Resultados

### Teste Completo

```
================================================================
  RELATÓRIO FINAL
================================================================

PONTUAÇÕES POR CRITÉRIO:
  1. Cliente........................: 2.0/2.0  ✓
  2. Bot............................: 1.5/1.5  ✓
  3. Broker/Proxy/Referência........: 1.0/1.0  ✓
  4. Servidor.......................: 4.0/4.0  ✓
  5. Documentação...................: 0.5/0.5  ✓
  6. Apresentação...................: 1.0/1.0  ✓

  PONTUAÇÃO TOTAL: 10.0/10.0

  🎉 PARABÉNS! NOTA MÁXIMA!
```

### Demonstração Rápida

```
================================================================
  RESUMO
================================================================
[✓] Broker ROUTER/DEALER funcionando
[✓] Proxy XPUB/XSUB funcionando
[✓] Servidor de Referência gerenciando ranks
[✓] Servidores com relógio lógico
[✓] Heartbeats a cada 10 segundos
[✓] Bot publicando automaticamente
[✓] Cliente interativo funcionando
[✓] Replicação de dados entre servidores
```

---

## 🔧 Requisitos

### Windows
- ✅ Windows 10/11
- ✅ PowerShell 5.1+
- ✅ Docker Desktop
- ✅ Docker Compose

### Linux
- ✅ Ubuntu 20.04+ ou similar
- ✅ Bash 4.0+
- ✅ Docker
- ✅ Docker Compose
- ✅ jq (para processar JSON)

**Instalar jq no Linux:**
```bash
sudo apt-get install jq
```

### macOS
- ✅ macOS 10.15+
- ✅ Bash 4.0+
- ✅ Docker Desktop
- ✅ jq

**Instalar jq no macOS:**
```bash
brew install jq
```

---

## ⏱️ Tempo de Execução

| Script | Primeira Vez | Execuções Seguintes |
|--------|--------------|---------------------|
| **teste-completo** | 5-8 min | 2-3 min |
| **teste-demonstracao** | 2-3 min | 30 seg |
| **teste-basico** | 3-5 min | 1-2 min |
| **teste-multilang** | 5-10 min | 2-3 min |

*Primeira execução demora mais devido ao build das imagens Docker*

---

## 🐛 Problemas Comuns

### "Containers não iniciaram"

**Solução:**
```bash
docker-compose down -v
docker system prune -f
docker-compose up -d --build
```

### "Porta já em uso"

**Solução:**
```bash
# Parar containers anteriores
docker-compose down

# Ver o que está usando a porta
netstat -ano | findstr "5555"  # Windows
netstat -tuln | grep 5555      # Linux
```

### "jq: command not found" (Linux)

**Solução:**
```bash
sudo apt-get install jq
```

### "Replicação não verificada"

**Causa:** Sistema ainda inicializando  
**Solução:** Execute o script novamente após 1 minuto

---

## 📝 Roteiro de Apresentação

### 1. Executar Demonstração (30s)
```bash
./teste-demonstracao.sh
```

### 2. Mostrar Logs em Tempo Real (1-2 min)
```bash
# Heartbeats
docker-compose logs -f server | grep Heartbeat

# Bot publicando
docker-compose logs -f bot
```

### 3. Mostrar Replicação (30s)
```bash
# Ver dados do servidor 1
docker exec $(docker ps -qf "name=server-1") cat /data/users.json

# Ver dados do servidor 2
docker exec $(docker ps -qf "name=server-2") cat /data/users.json
```

### 4. Demonstrar Multi-Linguagem (2 min)
```bash
docker-compose -f docker-compose.multilang.yml up -d
docker-compose -f docker-compose.multilang.yml logs -f bot-go
```

### 5. Mostrar Relatório Completo (opcional)
```bash
./teste-completo.sh
```

---

## 💡 Dicas

### Para Economizar Tempo

1. **Deixe containers rodando** entre testes
   ```bash
   # Não use docker-compose down entre testes
   # Apenas reinicie se necessário
   ```

2. **Use demonstração rápida** durante apresentação
   ```bash
   ./teste-demonstracao.sh  # Rápido e eficiente
   ```

3. **Prepare ambiente antes** da apresentação
   ```bash
   # 10 minutos antes da apresentação
   docker-compose up -d
   # Deixe rodando e aquecendo
   ```

### Para Garantir Sucesso

1. ✅ Execute teste completo **antes** da apresentação
2. ✅ Verifique que pontuação é 10.0/10.0
3. ✅ Deixe containers rodando para demonstrar
4. ✅ Tenha os comandos úteis à mão
5. ✅ Teste multi-linguagem funcionando

---

## 📚 Documentação Adicional

- **Testes Detalhados**: Ver [TESTES.md](TESTES.md)
- **Scripts Completos**: Ver [README_TESTES_COMPLETOS.md](README_TESTES_COMPLETOS.md)
- **Início Rápido**: Ver [INICIO-RAPIDO.md](INICIO-RAPIDO.md)
- **Multi-Linguagem**: Ver [COMUNICACAO-MULTILINGUAGEM.md](COMUNICACAO-MULTILINGUAGEM.md)

---

## ✅ Checklist Final

Antes da apresentação:

- [ ] Executei `teste-completo` com sucesso
- [ ] Pontuação obtida: 10.0/10.0
- [ ] Todos os containers rodando
- [ ] Testei `teste-demonstracao`
- [ ] Verifiquei logs de heartbeats
- [ ] Confirmei replicação funcionando
- [ ] Testei comunicação multi-linguagem
- [ ] Preparei comandos para demonstração
- [ ] Li a documentação completa
- [ ] Entendi cada critério de avaliação

---

## 🎉 Pronto!

Com estes scripts, você pode:

✅ **Validar** que todos os critérios foram atendidos  
✅ **Demonstrar** rapidamente durante a apresentação  
✅ **Testar** funcionalidades específicas  
✅ **Depurar** problemas facilmente  

**Boa sorte na apresentação! 🚀**

