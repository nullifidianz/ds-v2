# Script de Teste Multi-Linguagem
# Server Python + Client JavaScript + Bot Go

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  TESTE DE COMUNICACAO MULTI-LINGUAGEM" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuracao:" -ForegroundColor Yellow
Write-Host "  - Servidor Python   (processa requisicoes)" -ForegroundColor White
Write-Host "  - Cliente JavaScript (interface)" -ForegroundColor White
Write-Host "  - Bot Go            (publicacoes automaticas)" -ForegroundColor White
Write-Host ""
Write-Host "Comunicacao via ZeroMQ + MessagePack" -ForegroundColor Green
Write-Host ""

Write-Host "[1/4] Limpando ambiente anterior..." -ForegroundColor Yellow
docker-compose -f docker-compose.multilang.yml down -v 2>$null

Write-Host "[2/4] Construindo imagens (pode demorar na primeira vez)..." -ForegroundColor Yellow
Write-Host "  - Imagem Python (broker, proxy, reference, servidor)" -ForegroundColor Gray
Write-Host "  - Imagem JavaScript (cliente)" -ForegroundColor Gray
Write-Host "  - Imagem Go (bot)" -ForegroundColor Gray
Write-Host ""

Write-Host "[3/4] Iniciando sistema..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Aguarde ~2 minutos para build completo..." -ForegroundColor Cyan
Write-Host ""

docker-compose -f docker-compose.multilang.yml up --build

Write-Host ""
Write-Host "[4/4] Sistema encerrado." -ForegroundColor Green
Write-Host ""
Write-Host "Para ver logs separadamente:" -ForegroundColor Yellow
Write-Host "  docker-compose -f docker-compose.multilang.yml logs -f server-python" -ForegroundColor Gray
Write-Host "  docker-compose -f docker-compose.multilang.yml logs -f client-js" -ForegroundColor Gray
Write-Host "  docker-compose -f docker-compose.multilang.yml logs -f bot-go" -ForegroundColor Gray

