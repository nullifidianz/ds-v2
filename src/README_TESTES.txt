================================================================================
  SISTEMA DE MENSAGENS DISTRIBUÍDO - GUIA DE TESTES
================================================================================

📦 ESTRUTURA DO PROJETO:
  ✅ 3 Linguagens implementadas: Python, JavaScript, Go
  ✅ Comunicação via ZeroMQ + MessagePack
  ✅ 6 serviços configurados e prontos

🚀 TESTE MAIS RÁPIDO (1 comando):
  
  docker-compose up --build
  
  Aguarde ~2 minutos na primeira execução.
  O cliente Python abrirá com um menu interativo.
  
  No menu:
  - Digite 2 → Criar canal "geral"
  - Digite 4 → Inscrever em "geral"
  - Aguarde - Verá mensagens dos bots!

⚙️ SCRIPTS POWERSHELL DISPONÍVEIS:

  .\teste-basico.ps1        → Inicia sistema completo Python
  .\teste-replicacao.ps1    → Demonstra replicação entre servidores
  .\teste-logs.ps1          → Visualizador de logs interativo
  .\limpar-tudo.ps1         → Remove containers e limpa ambiente

📖 GUIAS DETALHADOS:

  INICIO-RAPIDO.md          → Início rápido e comandos básicos
  TESTES.md                 → Todos os cenários de teste (completo)

🔍 VERIFICAR STATUS:

  docker-compose ps         → Ver containers rodando
  docker-compose logs -f    → Ver logs em tempo real

🛑 PARAR SISTEMA:

  Ctrl+C                    → Parar containers
  docker-compose down       → Parar e remover containers
  docker-compose down -v    → Parar, remover e limpar dados

================================================================================

🎯 TESTES RECOMENDADOS:

1. TESTE BÁSICO (5 min)
   → docker-compose up --build
   → Criar canal e ver bots publicando

2. TESTE DE REPLICAÇÃO (10 min)
   → .\teste-replicacao.ps1
   → Ver dados sendo copiados entre servidores

3. TESTE DE LOGS (durante execução)
   → .\teste-logs.ps1
   → Monitorar componentes em tempo real

================================================================================

💡 DICAS:

  - Primeira execução demora ~2 min (build das imagens)
  - Execuções seguintes são instantâneas
  - Dados persistem entre execuções (volumes Docker)
  - Use Ctrl+C para parar suavemente
  - Servidores replicam dados a cada 30 segundos
  - Bots criam mensagens automaticamente

🐛 PROBLEMAS?

  1. Porta em uso → docker-compose down
  2. Container não inicia → docker-compose logs nome-servico
  3. Comportamento estranho → .\limpar-tudo.ps1 e reconstruir

================================================================================

📊 ARQUITETURA SIMPLIFICADA:

  Cliente/Bot → Broker → Servidor (3 réplicas Python)
                  ↓              ↓
              Proxy ←────────────┘
                  ↓
           Reference ← Heartbeats

  Broker: Balanceia carga (round-robin)
  Proxy: Distribui mensagens pub/sub
  Reference: Coordena servidores
  Servidores: Replicam dados entre si

================================================================================

✅ PRONTO PARA COMEÇAR!

Execute: docker-compose up --build

Ou abra: INICIO-RAPIDO.md para guia passo a passo

================================================================================

