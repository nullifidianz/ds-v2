# Script para Limpar Todo o Ambiente Docker

Write-Host "========================================" -ForegroundColor Red
Write-Host "  Limpeza Completa do Ambiente" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

Write-Host "ATENÇÃO: Isso irá remover:" -ForegroundColor Yellow
Write-Host "  - Todos os containers do projeto" -ForegroundColor White
Write-Host "  - Todos os volumes de dados" -ForegroundColor White
Write-Host "  - Todas as imagens criadas" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Deseja continuar? (s/N)"

if ($confirm -ne "s" -and $confirm -ne "S") {
    Write-Host "Operação cancelada." -ForegroundColor Green
    exit
}

Write-Host ""
Write-Host "[1/4] Parando todos os containers..." -ForegroundColor Yellow
docker-compose down -v

Write-Host "[2/4] Removendo imagens do projeto..." -ForegroundColor Yellow
docker images "cc7261:proj" -q | ForEach-Object { docker rmi $_ -f }

Write-Host "[3/4] Limpando sistema Docker..." -ForegroundColor Yellow
docker system prune -f

Write-Host "[4/4] Limpeza concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "Para reconstruir, execute: docker-compose up --build" -ForegroundColor Cyan

