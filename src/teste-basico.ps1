# Script de Teste Básico - Sistema de Mensagens Distribuído
# Apenas Python

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Teste Básico - Sistema Python" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Limpando containers anteriores..." -ForegroundColor Yellow
docker-compose down -v 2>$null

Write-Host "[2/3] Construindo e iniciando sistema..." -ForegroundColor Yellow
Write-Host "  - Broker (balanceador)" -ForegroundColor Gray
Write-Host "  - Proxy (pub/sub)" -ForegroundColor Gray
Write-Host "  - Reference (coordenador)" -ForegroundColor Gray
Write-Host "  - Server Python (3 réplicas)" -ForegroundColor Gray
Write-Host "  - Bot Python (2 réplicas)" -ForegroundColor Gray
Write-Host "  - Cliente Python (interativo)" -ForegroundColor Gray
Write-Host ""

docker-compose up --build

Write-Host ""
Write-Host "Sistema encerrado." -ForegroundColor Green

