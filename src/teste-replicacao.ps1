# Script de Teste de Replicação
# Demonstra dados sendo replicados entre servidores

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Teste de Replicação" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/6] Limpando ambiente..." -ForegroundColor Yellow
docker-compose down -v 2>$null

Write-Host "[2/6] Subindo infraestrutura (broker, proxy, reference)..." -ForegroundColor Yellow
docker-compose up -d broker proxy reference
Start-Sleep -Seconds 5

Write-Host "[3/6] Subindo 3 servidores Python..." -ForegroundColor Yellow
docker-compose up -d server
Start-Sleep -Seconds 10

Write-Host "[4/6] Verificando servidores registrados..." -ForegroundColor Yellow
docker-compose logs reference | Select-String "registrado"

Write-Host ""
Write-Host "[5/6] Criando canal de teste..." -ForegroundColor Yellow
Write-Host "  Pressione Enter para continuar após criar o canal 'teste'" -ForegroundColor Cyan

# Criar canal via cliente
$env:USERNAME = "admin"
docker-compose run --rm client

Write-Host ""
Write-Host "[6/6] Aguardando replicação (35 segundos)..." -ForegroundColor Yellow
for ($i = 35; $i -gt 0; $i--) {
    Write-Host "  $i segundos restantes..." -ForegroundColor Gray
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "Verificando dados replicados:" -ForegroundColor Green
Write-Host ""

# Obter IDs dos containers de servidor
$serverContainers = docker ps -qf "name=server"

$count = 1
foreach ($container in $serverContainers) {
    Write-Host "Servidor $count - Canais:" -ForegroundColor Yellow
    docker exec $container cat /data/channels.json 2>$null
    Write-Host ""
    $count++
}

Write-Host ""
Write-Host "Todos os servidores devem ter o canal 'teste'!" -ForegroundColor Green
Write-Host ""
Write-Host "Pressione Ctrl+C para encerrar ou Enter para limpar..." -ForegroundColor Cyan
Read-Host

docker-compose down

