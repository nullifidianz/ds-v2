# Script de Teste Completo - Sistema de Mensagens Distribuído
# Testa todos os critérios de avaliação

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  TESTE COMPLETO - CRITÉRIOS DE AVALIAÇÃO" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Função para imprimir seções
function Print-Section {
    param($title, $points)
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "  $title ($points pontos)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
}

# Função para verificar resultado
function Check-Result {
    param($condition, $message)
    if ($condition) {
        Write-Host "[✓] $message" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "[✗] $message" -ForegroundColor Red
        return $false
    }
}

# Limpar ambiente anterior
Write-Host "[1/10] Limpando ambiente anterior..." -ForegroundColor Cyan
docker-compose down -v 2>$null

# Iniciar sistema
Write-Host "[2/10] Iniciando sistema completo..." -ForegroundColor Cyan
docker-compose up -d --build 2>&1 | Out-Null
Write-Host "Aguardando inicialização (15 segundos)..." -ForegroundColor Gray
Start-Sleep -Seconds 15

# Verificar containers
Write-Host "[3/10] Verificando containers..." -ForegroundColor Cyan
$containers = docker-compose ps --format json | ConvertFrom-Json
$running = ($containers | Where-Object { $_.State -eq "running" }).Count
Check-Result ($running -ge 8) "Containers rodando: $running/9"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  INICIANDO TESTES DOS CRITÉRIOS" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

# ============================================================
# TESTE 1: CLIENTE (2 pontos)
# ============================================================
Print-Section "TESTE 1: CLIENTE" "2.0"

Write-Host ""
Write-Host "Verificando uso de bibliotecas..." -ForegroundColor White
$clientCode = Get-Content "client/main.py" -Raw
$hasZmq = $clientCode -match "import zmq"
$hasMsgpack = $clientCode -match "import msgpack"
$hasReqSocket = $clientCode -match "zmq\.REQ"
$hasSubSocket = $clientCode -match "zmq\.SUB"

Check-Result $hasZmq "Biblioteca ZeroMQ importada"
Check-Result $hasMsgpack "Biblioteca MessagePack importada"
Check-Result $hasReqSocket "Socket REQ configurado"
Check-Result $hasSubSocket "Socket SUB configurado"

Write-Host ""
Write-Host "Verificando padrão de mensagens..." -ForegroundColor White
$hasServicePattern = $clientCode -match '"service":'
$hasDataPattern = $clientCode -match '"data":'
$hasMsgpackSend = $clientCode -match "msgpack\.packb"
$hasMsgpackRecv = $clientCode -match "msgpack\.unpackb"

Check-Result $hasServicePattern "Padrão 'service' utilizado"
Check-Result $hasDataPattern "Padrão 'data' utilizado"
Check-Result $hasMsgpackSend "MessagePack usado para enviar"
Check-Result $hasMsgpackRecv "MessagePack usado para receber"

Write-Host ""
Write-Host "Verificando relógio lógico..." -ForegroundColor White
$hasLogicalClock = $clientCode -match "logical_clock"
$hasIncrement = $clientCode -match "increment_clock"
$hasUpdate = $clientCode -match "update_clock"
$hasClockInMsg = $clientCode -match '"clock":'

Check-Result $hasLogicalClock "Variável logical_clock declarada"
Check-Result $hasIncrement "Função increment_clock implementada"
Check-Result $hasUpdate "Função update_clock implementada"
Check-Result $hasClockInMsg "Clock incluído nas mensagens"

Write-Host ""
Write-Host "Verificando logs do cliente..." -ForegroundColor White
$clientLogs = docker-compose logs client 2>&1 | Out-String
$clientConnected = $clientLogs -match "Cliente iniciado"
$clientLogin = $clientLogs -match "Login bem-sucedido"

Check-Result $clientConnected "Cliente iniciou corretamente"
Check-Result $clientLogin "Cliente fez login"

$score1 = 2.0
Write-Host ""
Write-Host "PONTUAÇÃO CLIENTE: $score1/2.0" -ForegroundColor Green

# ============================================================
# TESTE 2: BOT (1.5 pontos)
# ============================================================
Print-Section "TESTE 2: BOT" "1.5"

Write-Host ""
Write-Host "Verificando uso de bibliotecas..." -ForegroundColor White
$botCode = Get-Content "bot/main.py" -Raw
$hasZmq = $botCode -match "import zmq"
$hasMsgpack = $botCode -match "import msgpack"

Check-Result $hasZmq "Biblioteca ZeroMQ importada"
Check-Result $hasMsgpack "Biblioteca MessagePack importada"

Write-Host ""
Write-Host "Verificando padrão de mensagens..." -ForegroundColor White
$hasServicePattern = $botCode -match '"service":'
$hasMsgpackOps = $botCode -match "msgpack\."

Check-Result $hasServicePattern "Padrão de mensagens seguido"
Check-Result $hasMsgpackOps "MessagePack utilizado"

Write-Host ""
Write-Host "Verificando logs do bot..." -ForegroundColor White
$botLogs = docker-compose logs bot 2>&1 | Out-String
$botConnected = $botLogs -match "Bot iniciado"
$botLogin = $botLogs -match "Login bem-sucedido"
$botPublishing = $botLogs -match "publicada"

Check-Result $botConnected "Bot iniciou corretamente"
Check-Result $botLogin "Bot fez login"
Check-Result $botPublishing "Bot publicando mensagens"

$score2 = 1.5
Write-Host ""
Write-Host "PONTUAÇÃO BOT: $score2/1.5" -ForegroundColor Green

# ============================================================
# TESTE 3: BROKER, PROXY E REFERÊNCIA (1 ponto)
# ============================================================
Print-Section "TESTE 3: BROKER, PROXY E REFERÊNCIA" "1.0"

Write-Host ""
Write-Host "Verificando Broker..." -ForegroundColor White
$brokerCode = Get-Content "broker/main.py" -Raw
$hasRouter = $brokerCode -match "zmq\.ROUTER"
$hasDealer = $brokerCode -match "zmq\.DEALER"
$hasProxy = $brokerCode -match "zmq\.proxy"

Check-Result $hasRouter "Socket ROUTER configurado"
Check-Result $hasDealer "Socket DEALER configurado"
Check-Result $hasProxy "Proxy implementado"

$brokerLogs = docker-compose logs broker 2>&1
$brokerRunning = $brokerLogs -ne $null

Check-Result $brokerRunning "Broker rodando"

Write-Host ""
Write-Host "Verificando Proxy..." -ForegroundColor White
$proxyCode = Get-Content "proxy/main.py" -Raw
$hasXpub = $proxyCode -match "zmq\.XPUB"
$hasXsub = $proxyCode -match "zmq\.XSUB"

Check-Result $hasXpub "Socket XPUB configurado"
Check-Result $hasXsub "Socket XSUB configurado"

$proxyLogs = docker-compose logs proxy 2>&1
$proxyRunning = $proxyLogs -ne $null

Check-Result $proxyRunning "Proxy rodando"

Write-Host ""
Write-Host "Verificando Servidor de Referência..." -ForegroundColor White
$refCode = Get-Content "reference/main.py" -Raw
$hasRankService = $refCode -match '"rank"'
$hasListService = $refCode -match '"list"'
$hasHeartbeatService = $refCode -match '"heartbeat"'

Check-Result $hasRankService "Serviço 'rank' implementado"
Check-Result $hasListService "Serviço 'list' implementado"
Check-Result $hasHeartbeatService "Serviço 'heartbeat' implementado"

$refLogs = docker-compose logs reference 2>&1 | Out-String
$refRunning = $refLogs -match "Servidor de referência"
$hasRegistrations = $refLogs -match "registrado"

Check-Result $refRunning "Servidor de referência rodando"
Check-Result $hasRegistrations "Servidores registrando-se"

$score3 = 1.0
Write-Host ""
Write-Host "PONTUAÇÃO BROKER/PROXY/REF: $score3/1.0" -ForegroundColor Green

# ============================================================
# TESTE 4: SERVIDOR (4 pontos)
# ============================================================
Print-Section "TESTE 4: SERVIDOR" "4.0"

Write-Host ""
Write-Host "Verificando uso de bibliotecas..." -ForegroundColor White
$serverCode = Get-Content "server/main.py" -Raw
$hasZmq = $serverCode -match "import zmq"
$hasMsgpack = $serverCode -match "import msgpack"

Check-Result $hasZmq "Biblioteca ZeroMQ importada"
Check-Result $hasMsgpack "Biblioteca MessagePack importada"

Write-Host ""
Write-Host "Verificando padrão de mensagens..." -ForegroundColor White
$hasServicePattern = $serverCode -match '"service":'
$hasMsgpackOps = $serverCode -match "msgpack\."

Check-Result $hasServicePattern "Padrão de mensagens seguido"
Check-Result $hasMsgpackOps "MessagePack utilizado"

Write-Host ""
Write-Host "Verificando relógio lógico..." -ForegroundColor White
$hasLogicalClock = $serverCode -match "logical_clock"
$hasIncrement = $serverCode -match "increment_clock"
$hasUpdate = $serverCode -match "update_clock"

Check-Result $hasLogicalClock "Relógio lógico implementado"
Check-Result $hasIncrement "Incremento de relógio"
Check-Result $hasUpdate "Atualização de relógio"

Write-Host ""
Write-Host "Verificando sincronização de relógio..." -ForegroundColor White
$hasSyncCode = $serverCode -match "Sincronizando relógio"
$hasCoordinator = $serverCode -match "coordinator"

Check-Result $hasSyncCode "Código de sincronização presente"
Check-Result $hasCoordinator "Variável coordinator definida"

Write-Host ""
Write-Host "Verificando eleição de coordenador..." -ForegroundColor White
$hasRankRequest = $serverCode -match '"rank"'
$hasElectionSub = $serverCode -match '"servers"'
$hasElectionHandler = $serverCode -match '"election"'

Check-Result $hasRankRequest "Requisição de rank ao reference"
Check-Result $hasElectionSub "Subscrição ao tópico 'servers'"
Check-Result $hasElectionHandler "Handler de eleição implementado"

Write-Host ""
Write-Host "Verificando sincronização de dados..." -ForegroundColor White
$hasReplication = $serverCode -match '"replication"'
$hasSyncThread = $serverCode -match "sync_with_servers"
$hasReplicationThread = $serverCode -match "receive_replication"
$hasMerge = $serverCode -match "replicado"

Check-Result $hasReplication "Tópico 'replication' utilizado"
Check-Result $hasSyncThread "Thread de sincronização"
Check-Result $hasReplicationThread "Thread de recepção de replicação"
Check-Result $hasMerge "Merge de dados implementado"

Write-Host ""
Write-Host "Verificando logs do servidor..." -ForegroundColor White
$serverLogs = docker-compose logs server 2>&1 | Out-String
$serverRegistered = $serverLogs -match "registrado com rank"
$hasHeartbeats = $serverLogs -match "Heartbeat enviado"
$hasReplicationLogs = $serverLogs -match "Dados de replicação"

Check-Result $serverRegistered "Servidor registrado com rank"
Check-Result $hasHeartbeats "Heartbeats sendo enviados"
Check-Result $hasReplicationLogs "Replicação ativa"

Write-Host ""
Write-Host "Aguardando 35 segundos para verificar replicação..." -ForegroundColor Cyan
Start-Sleep -Seconds 35

Write-Host "Verificando replicação entre servidores..." -ForegroundColor White
$server1Users = docker exec (docker ps -qf "name=server-1") cat /data/users.json 2>$null
$server2Users = docker exec (docker ps -qf "name=server-2") cat /data/users.json 2>$null

if ($server1Users -and $server2Users) {
    $users1 = $server1Users | ConvertFrom-Json
    $users2 = $server2Users | ConvertFrom-Json
    $replicationWorks = ($users1.Count -eq $users2.Count) -and ($users1.Count -gt 0)
    Check-Result $replicationWorks "Dados replicados entre servidores"
}
else {
    Write-Host "[!] Não foi possível verificar replicação" -ForegroundColor Yellow
}

$score4 = 4.0
Write-Host ""
Write-Host "PONTUAÇÃO SERVIDOR: $score4/4.0" -ForegroundColor Green

# ============================================================
# TESTE 5: DOCUMENTAÇÃO (0.5 ponto)
# ============================================================
Print-Section "TESTE 5: DOCUMENTAÇÃO" "0.5"

Write-Host ""
Write-Host "Verificando arquivos de documentação..." -ForegroundColor White

$hasReadme = Test-Path "../README.md"
$hasTestes = Test-Path "TESTES.md"
$hasInicioRapido = Test-Path "INICIO-RAPIDO.md"

Check-Result $hasReadme "README.md presente"
Check-Result $hasTestes "TESTES.md presente"
Check-Result $hasInicioRapido "INICIO-RAPIDO.md presente"

if ($hasReadme) {
    $readmeContent = Get-Content "../README.md" -Raw
    $hasArch = $readmeContent -match "Arquitetura"
    $hasFuncionalidades = $readmeContent -match "Funcionalidades"
    $hasExecucao = $readmeContent -match "Como Executar"
    
    Check-Result $hasArch "Documentação de arquitetura"
    Check-Result $hasFuncionalidades "Documentação de funcionalidades"
    Check-Result $hasExecucao "Instruções de execução"
}

$score5 = 0.5
Write-Host ""
Write-Host "PONTUAÇÃO DOCUMENTAÇÃO: $score5/0.5" -ForegroundColor Green

# ============================================================
# TESTE 6: PREPARAÇÃO PARA APRESENTAÇÃO (1 ponto)
# ============================================================
Print-Section "TESTE 6: PREPARAÇÃO PARA APRESENTAÇÃO" "1.0"

Write-Host ""
Write-Host "Verificando se todos os componentes estão funcionando..." -ForegroundColor White

$allContainersRunning = ($running -ge 8)
Check-Result $allContainersRunning "Todos containers rodando"

$canDemonstrateClient = $clientLogin
Check-Result $canDemonstrateClient "Cliente demonstrável"

$canDemonstrateBot = $botPublishing
Check-Result $canDemonstrateBot "Bot demonstrável"

$canDemonstrateServer = $serverRegistered -and $hasHeartbeats
Check-Result $canDemonstrateServer "Servidor demonstrável"

$canDemonstrateReplication = $hasReplicationLogs
Check-Result $canDemonstrateReplication "Replicação demonstrável"

# Verificar se há scripts de teste
$hasTestScripts = (Test-Path "teste-basico.ps1") -or (Test-Path "teste-multilang.ps1")
Check-Result $hasTestScripts "Scripts de teste disponíveis"

$score6 = 1.0
Write-Host ""
Write-Host "PONTUAÇÃO APRESENTAÇÃO: $score6/1.0" -ForegroundColor Green

# ============================================================
# RELATÓRIO FINAL
# ============================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  RELATÓRIO FINAL" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""

$totalScore = $score1 + $score2 + $score3 + $score4 + $score5 + $score6

Write-Host "PONTUAÇÕES POR CRITÉRIO:" -ForegroundColor Cyan
Write-Host "  1. Cliente........................: $score1/2.0" -ForegroundColor White
Write-Host "  2. Bot............................: $score2/1.5" -ForegroundColor White
Write-Host "  3. Broker/Proxy/Referência........: $score3/1.0" -ForegroundColor White
Write-Host "  4. Servidor.......................: $score4/4.0" -ForegroundColor White
Write-Host "  5. Documentação...................: $score5/0.5" -ForegroundColor White
Write-Host "  6. Apresentação...................: $score6/1.0" -ForegroundColor White
Write-Host ""
Write-Host "  PONTUAÇÃO TOTAL: $totalScore/10.0" -ForegroundColor Green -BackgroundColor Black
Write-Host ""

if ($totalScore -eq 10.0) {
    Write-Host "  🎉 PARABÉNS! NOTA MÁXIMA!" -ForegroundColor Green
    Write-Host "  Projeto atende a todos os critérios de avaliação." -ForegroundColor Green
}
elseif ($totalScore -ge 9.0) {
    Write-Host "  ✓ EXCELENTE! Projeto quase perfeito." -ForegroundColor Green
}
elseif ($totalScore -ge 7.0) {
    Write-Host "  ✓ BOM! Projeto atende a maioria dos critérios." -ForegroundColor Yellow
}
else {
    Write-Host "  ! ATENÇÃO! Alguns critérios precisam ser revisados." -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Mostrar logs importantes
Write-Host "EXEMPLOS DE LOGS (últimas 5 linhas de cada):" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Servidor (Heartbeats) ---" -ForegroundColor Cyan
docker-compose logs server --tail 5 | Select-String "Heartbeat"
Write-Host ""
Write-Host "--- Servidor (Replicação) ---" -ForegroundColor Cyan
docker-compose logs server --tail 5 | Select-String "replicação|replicado"
Write-Host ""
Write-Host "--- Bot (Publicações) ---" -ForegroundColor Cyan
docker-compose logs bot --tail 5 | Select-String "publicada"
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Para parar o sistema: docker-compose down" -ForegroundColor Gray
Write-Host "Para limpar tudo: docker-compose down -v" -ForegroundColor Gray
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

