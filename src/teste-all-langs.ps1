# Script de Teste com TODAS as Linguagens
# 3 Servidores + 3 Clientes + 3 Bots (Total: 9 componentes + infraestrutura)

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  TESTE COMPLETO - TODAS AS LINGUAGENS" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "SERVIDORES:" -ForegroundColor Yellow
Write-Host "  1. Servidor Python" -ForegroundColor Green
Write-Host "  2. Servidor JavaScript" -ForegroundColor Green
Write-Host "  3. Servidor Go" -ForegroundColor Green
Write-Host ""
Write-Host "CLIENTES:" -ForegroundColor Yellow
Write-Host "  1. Cliente Python (interativo)" -ForegroundColor Cyan
Write-Host "  2. Cliente JavaScript (automatico)" -ForegroundColor Cyan
Write-Host "  3. Cliente Go (automatico)" -ForegroundColor Cyan
Write-Host ""
Write-Host "BOTS:" -ForegroundColor Yellow
Write-Host "  1. Bot Python" -ForegroundColor Magenta
Write-Host "  2. Bot JavaScript" -ForegroundColor Magenta
Write-Host "  3. Bot Go" -ForegroundColor Magenta
Write-Host ""
Write-Host "COMUNICACAO: ZeroMQ + MessagePack (todas as linguagens se comunicam!)" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Este teste e pesado (~12 containers). Continuar? (s/N)"
if ($confirm -ne "s" -and $confirm -ne "S") {
    Write-Host "Cancelado." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "[1/3] Limpando ambiente..." -ForegroundColor Yellow
docker-compose -f docker-compose.all-langs.yml down -v 2>$null

Write-Host "[2/3] Construindo todas as imagens..." -ForegroundColor Yellow
Write-Host "  Isso pode demorar 3-5 minutos na primeira vez..." -ForegroundColor Gray
Write-Host ""

Write-Host "[3/3] Iniciando sistema completo..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Aguarde os containers subirem e observe a magica!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Dica: Abra outro terminal e execute:" -ForegroundColor Yellow
Write-Host "  docker-compose -f docker-compose.all-langs.yml logs -f | Select-String 'replicado'" -ForegroundColor Gray
Write-Host "  Para ver dados sendo replicados entre TODAS as linguagens!" -ForegroundColor Gray
Write-Host ""

docker-compose -f docker-compose.all-langs.yml up --build

Write-Host ""
Write-Host "Sistema encerrado." -ForegroundColor Green

