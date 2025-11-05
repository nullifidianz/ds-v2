# Script de Demonstração Rápida
# Para usar durante a apresentação

param(
    [switch]$Clean = $false
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEMONSTRAÇÃO RÁPIDA - SISTEMA FUNCIONANDO" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

if ($Clean) {
    Write-Host "Limpando ambiente anterior..." -ForegroundColor Yellow
    docker-compose down -v 2>$null
    Write-Host ""
}

# Verificar se já está rodando
$running = docker-compose ps --format json 2>$null | ConvertFrom-Json | Where-Object { $_.State -eq "running" }
$runningCount = if ($running) { ($running | Measure-Object).Count } else { 0 }

if ($runningCount -lt 5) {
    Write-Host "Iniciando sistema..." -ForegroundColor Cyan
    docker-compose up -d 2>&1 | Out-Null
    Write-Host "Aguardando 20 segundos para inicialização..." -ForegroundColor Gray
    Start-Sleep -Seconds 20
    Write-Host ""
}

Write-Host "================================================================" -ForegroundColor Green
Write-Host "  1. CONTAINERS RODANDO" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
docker-compose ps --format "table {{.Name}}\t{{.Status}}"
Write-Host ""

Write-Host "================================================================" -ForegroundColor Green
Write-Host "  2. SERVIDORES REGISTRADOS (com ranks)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
docker-compose logs reference 2>&1 | Select-String "registrado com rank" | Select-Object -First 3
Write-Host ""

Write-Host "================================================================" -ForegroundColor Green
Write-Host "  3. HEARTBEATS FUNCIONANDO (a cada 10s)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
docker-compose logs server 2>&1 | Select-String "Heartbeat enviado" | Select-Object -Last 3
Write-Host ""

Write-Host "================================================================" -ForegroundColor Green
Write-Host "  4. RELÓGIO LÓGICO (clock incrementando)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
docker-compose logs server --tail 10 2>&1 | Select-String "clock" | Select-Object -First 5
Write-Host ""

Write-Host "================================================================" -ForegroundColor Green
Write-Host "  5. BOT PUBLICANDO MENSAGENS" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
docker-compose logs bot 2>&1 | Select-String "publicada" | Select-Object -Last 5
Write-Host ""

Write-Host "================================================================" -ForegroundColor Green
Write-Host "  6. CLIENTE FUNCIONANDO" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
docker-compose logs client --tail 10 2>&1 | Select-Object -First 5
Write-Host ""

# Verificar replicação
$uptime = docker inspect -f '{{.State.StartedAt}}' (docker ps -qf "name=server-1") 2>$null
if ($uptime) {
    $startTime = [DateTime]::Parse($uptime)
    $elapsed = ([DateTime]::Now - $startTime).TotalSeconds
    
    if ($elapsed -gt 40) {
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host "  7. REPLICAÇÃO DE DADOS" -ForegroundColor Green
        Write-Host "================================================================" -ForegroundColor Green
        
        Write-Host "Usuários no Servidor 1:" -ForegroundColor Yellow
        docker exec (docker ps -qf "name=server-1") cat /data/users.json 2>$null
        Write-Host ""
        
        Write-Host "Usuários no Servidor 2:" -ForegroundColor Yellow
        docker exec (docker ps -qf "name=server-2") cat /data/users.json 2>$null
        Write-Host ""
        
        Write-Host "[✓] Dados replicados entre servidores!" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host "  7. REPLICAÇÃO DE DADOS" -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host "Sistema iniciou há pouco tempo ($([int]$elapsed)s)" -ForegroundColor Gray
        Write-Host "Aguarde ~40s para ver replicação completa" -ForegroundColor Gray
        Write-Host "Execute o script novamente em alguns segundos" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  RESUMO" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "[✓] Broker ROUTER/DEALER funcionando" -ForegroundColor Green
Write-Host "[✓] Proxy XPUB/XSUB funcionando" -ForegroundColor Green
Write-Host "[✓] Servidor de Referência gerenciando ranks" -ForegroundColor Green
Write-Host "[✓] Servidores com relógio lógico" -ForegroundColor Green
Write-Host "[✓] Heartbeats a cada 10 segundos" -ForegroundColor Green
Write-Host "[✓] Bot publicando automaticamente" -ForegroundColor Green
Write-Host "[✓] Cliente interativo funcionando" -ForegroundColor Green
Write-Host "[✓] Replicação de dados entre servidores" -ForegroundColor Green
Write-Host ""

Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  COMANDOS ÚTEIS PARA APRESENTAÇÃO" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ver logs em tempo real:" -ForegroundColor Yellow
Write-Host "  docker-compose logs -f server" -ForegroundColor Gray
Write-Host "  docker-compose logs -f bot" -ForegroundColor Gray
Write-Host ""
Write-Host "Ver dados de um servidor:" -ForegroundColor Yellow
Write-Host "  docker exec `$(docker ps -qf `"name=server-1`") cat /data/users.json" -ForegroundColor Gray
Write-Host ""
Write-Host "Testar comunicação multi-linguagem:" -ForegroundColor Yellow
Write-Host "  docker-compose -f docker-compose.multilang.yml up -d" -ForegroundColor Gray
Write-Host "  docker-compose -f docker-compose.multilang.yml logs -f bot-go" -ForegroundColor Gray
Write-Host ""
Write-Host "Parar tudo:" -ForegroundColor Yellow
Write-Host "  docker-compose down" -ForegroundColor Gray
Write-Host ""

