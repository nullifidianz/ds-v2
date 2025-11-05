# Script para Ver Logs em Tempo Real

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Visualizador de Logs" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Escolha qual serviço monitorar:" -ForegroundColor Yellow
Write-Host "  1. Todos os servidores" -ForegroundColor White
Write-Host "  2. Broker" -ForegroundColor White
Write-Host "  3. Proxy" -ForegroundColor White
Write-Host "  4. Servidor de Referência" -ForegroundColor White
Write-Host "  5. Cliente" -ForegroundColor White
Write-Host "  6. Bots" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Opção (1-6)"

switch ($choice) {
    "1" { 
        Write-Host "Mostrando logs dos servidores..." -ForegroundColor Green
        docker-compose logs -f server 
    }
    "2" { 
        Write-Host "Mostrando logs do broker..." -ForegroundColor Green
        docker-compose logs -f broker 
    }
    "3" { 
        Write-Host "Mostrando logs do proxy..." -ForegroundColor Green
        docker-compose logs -f proxy 
    }
    "4" { 
        Write-Host "Mostrando logs do servidor de referência..." -ForegroundColor Green
        docker-compose logs -f reference 
    }
    "5" { 
        Write-Host "Mostrando logs do cliente..." -ForegroundColor Green
        docker-compose logs -f client 
    }
    "6" { 
        Write-Host "Mostrando logs dos bots..." -ForegroundColor Green
        docker-compose logs -f bot 
    }
    default { 
        Write-Host "Opção inválida" -ForegroundColor Red
    }
}

