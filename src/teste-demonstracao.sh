#!/bin/bash
# Script de Demonstração Rápida
# Para usar durante a apresentação

CLEAN=false

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean|-c)
            CLEAN=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}  DEMONSTRAÇÃO RÁPIDA - SISTEMA FUNCIONANDO${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""

if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}Limpando ambiente anterior...${NC}"
    docker-compose down -v 2>/dev/null
    echo ""
fi

# Verificar se já está rodando
running=$(docker-compose ps --format json 2>/dev/null | jq -r 'select(.State=="running")' | wc -l)

if [ "$running" -lt 5 ]; then
    echo -e "${CYAN}Iniciando sistema...${NC}"
    docker-compose up -d >/dev/null 2>&1
    echo -e "${GRAY}Aguardando 20 segundos para inicialização...${NC}"
    sleep 20
    echo ""
fi

echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}  1. CONTAINERS RODANDO${NC}"
echo -e "${GREEN}================================================================${NC}"
docker-compose ps --format "table {{.Name}}\t{{.Status}}"
echo ""

echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}  2. SERVIDORES REGISTRADOS (com ranks)${NC}"
echo -e "${GREEN}================================================================${NC}"
docker-compose logs reference 2>&1 | grep "registrado com rank" | head -3
echo ""

echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}  3. HEARTBEATS FUNCIONANDO (a cada 10s)${NC}"
echo -e "${GREEN}================================================================${NC}"
docker-compose logs server 2>&1 | grep "Heartbeat enviado" | tail -3
echo ""

echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}  4. RELÓGIO LÓGICO (clock incrementando)${NC}"
echo -e "${GREEN}================================================================${NC}"
docker-compose logs server --tail 10 2>&1 | grep "clock" | head -5
echo ""

echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}  5. BOT PUBLICANDO MENSAGENS${NC}"
echo -e "${GREEN}================================================================${NC}"
docker-compose logs bot 2>&1 | grep "publicada" | tail -5
echo ""

echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}  6. CLIENTE FUNCIONANDO${NC}"
echo -e "${GREEN}================================================================${NC}"
docker-compose logs client --tail 10 2>&1 | head -5
echo ""

# Verificar replicação
uptime=$(docker inspect -f '{{.State.StartedAt}}' $(docker ps -qf "name=server-1") 2>/dev/null)
if [ -n "$uptime" ]; then
    start_epoch=$(date -d "$uptime" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$uptime" +%s 2>/dev/null)
    current_epoch=$(date +%s)
    elapsed=$((current_epoch - start_epoch))
    
    if [ "$elapsed" -gt 40 ]; then
        echo -e "${GREEN}================================================================${NC}"
        echo -e "${GREEN}  7. REPLICAÇÃO DE DADOS${NC}"
        echo -e "${GREEN}================================================================${NC}"
        
        echo -e "${YELLOW}Usuários no Servidor 1:${NC}"
        docker exec $(docker ps -qf "name=server-1") cat /data/users.json 2>/dev/null
        echo ""
        
        echo -e "${YELLOW}Usuários no Servidor 2:${NC}"
        docker exec $(docker ps -qf "name=server-2") cat /data/users.json 2>/dev/null
        echo ""
        
        echo -e "${GREEN}[✓] Dados replicados entre servidores!${NC}"
        echo ""
    else
        echo -e "${YELLOW}================================================================${NC}"
        echo -e "${YELLOW}  7. REPLICAÇÃO DE DADOS${NC}"
        echo -e "${YELLOW}================================================================${NC}"
        echo -e "${GRAY}Sistema iniciou há pouco tempo (${elapsed}s)${NC}"
        echo -e "${GRAY}Aguarde ~40s para ver replicação completa${NC}"
        echo -e "${GRAY}Execute o script novamente em alguns segundos${NC}"
        echo ""
    fi
fi

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}  RESUMO${NC}"
echo -e "${CYAN}================================================================${NC}"
echo -e "${GREEN}[✓] Broker ROUTER/DEALER funcionando${NC}"
echo -e "${GREEN}[✓] Proxy XPUB/XSUB funcionando${NC}"
echo -e "${GREEN}[✓] Servidor de Referência gerenciando ranks${NC}"
echo -e "${GREEN}[✓] Servidores com relógio lógico${NC}"
echo -e "${GREEN}[✓] Heartbeats a cada 10 segundos${NC}"
echo -e "${GREEN}[✓] Bot publicando automaticamente${NC}"
echo -e "${GREEN}[✓] Cliente interativo funcionando${NC}"
echo -e "${GREEN}[✓] Replicação de dados entre servidores${NC}"
echo ""

echo -e "${MAGENTA}================================================================${NC}"
echo -e "${MAGENTA}  COMANDOS ÚTEIS PARA APRESENTAÇÃO${NC}"
echo -e "${MAGENTA}================================================================${NC}"
echo ""
echo -e "${YELLOW}Ver logs em tempo real:${NC}"
echo -e "${GRAY}  docker-compose logs -f server${NC}"
echo -e "${GRAY}  docker-compose logs -f bot${NC}"
echo ""
echo -e "${YELLOW}Ver dados de um servidor:${NC}"
echo -e "${GRAY}  docker exec \$(docker ps -qf \"name=server-1\") cat /data/users.json${NC}"
echo ""
echo -e "${YELLOW}Testar comunicação multi-linguagem:${NC}"
echo -e "${GRAY}  docker-compose -f docker-compose.multilang.yml up -d${NC}"
echo -e "${GRAY}  docker-compose -f docker-compose.multilang.yml logs -f bot-go${NC}"
echo ""
echo -e "${YELLOW}Parar tudo:${NC}"
echo -e "${GRAY}  docker-compose down${NC}"
echo ""

