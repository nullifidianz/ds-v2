#!/bin/bash
# Script de Teste Completo - Sistema de Mensagens Distribuído
# Testa todos os critérios de avaliação

set +e  # Continuar mesmo com erros

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}  TESTE COMPLETO - CRITÉRIOS DE AVALIAÇÃO${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""

# Função para imprimir seções
print_section() {
    echo ""
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${YELLOW}  $1 ($2 pontos)${NC}"
    echo -e "${YELLOW}================================================================${NC}"
}

# Função para verificar resultado
check_result() {
    if [ "$1" = true ]; then
        echo -e "${GREEN}[✓] $2${NC}"
        return 0
    else
        echo -e "${RED}[✗] $2${NC}"
        return 1
    fi
}

# Limpar ambiente anterior
echo -e "${CYAN}[1/10] Limpando ambiente anterior...${NC}"
docker-compose down -v 2>/dev/null

# Iniciar sistema
echo -e "${CYAN}[2/10] Iniciando sistema completo...${NC}"
docker-compose up -d --build >/dev/null 2>&1
echo -e "${GRAY}Aguardando inicialização (15 segundos)...${NC}"
sleep 15

# Verificar containers
echo -e "${CYAN}[3/10] Verificando containers...${NC}"
running=$(docker-compose ps --format json | jq -r 'select(.State=="running")' | wc -l)
if [ $running -ge 8 ]; then
    check_result true "Containers rodando: $running/9"
else
    check_result false "Containers rodando: $running/9"
fi

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}  INICIANDO TESTES DOS CRITÉRIOS${NC}"
echo -e "${GREEN}================================================================${NC}"

# ============================================================
# TESTE 1: CLIENTE (2 pontos)
# ============================================================
print_section "TESTE 1: CLIENTE" "2.0"

echo ""
echo -e "${WHITE}Verificando uso de bibliotecas...${NC}"
client_code=$(cat client/main.py 2>/dev/null)

grep -q "import zmq" <<< "$client_code" && has_zmq=true || has_zmq=false
grep -q "import msgpack" <<< "$client_code" && has_msgpack=true || has_msgpack=false
grep -q "zmq.REQ" <<< "$client_code" && has_req=true || has_req=false
grep -q "zmq.SUB" <<< "$client_code" && has_sub=true || has_sub=false

check_result $has_zmq "Biblioteca ZeroMQ importada"
check_result $has_msgpack "Biblioteca MessagePack importada"
check_result $has_req "Socket REQ configurado"
check_result $has_sub "Socket SUB configurado"

echo ""
echo -e "${WHITE}Verificando padrão de mensagens...${NC}"
grep -q '"service":' <<< "$client_code" && has_service=true || has_service=false
grep -q '"data":' <<< "$client_code" && has_data=true || has_data=false
grep -q "msgpack.packb" <<< "$client_code" && has_pack=true || has_pack=false
grep -q "msgpack.unpackb" <<< "$client_code" && has_unpack=true || has_unpack=false

check_result $has_service "Padrão 'service' utilizado"
check_result $has_data "Padrão 'data' utilizado"
check_result $has_pack "MessagePack usado para enviar"
check_result $has_unpack "MessagePack usado para receber"

echo ""
echo -e "${WHITE}Verificando relógio lógico...${NC}"
grep -q "logical_clock" <<< "$client_code" && has_clock=true || has_clock=false
grep -q "increment_clock" <<< "$client_code" && has_inc=true || has_inc=false
grep -q "update_clock" <<< "$client_code" && has_update=true || has_update=false
grep -q '"clock":' <<< "$client_code" && has_clock_msg=true || has_clock_msg=false

check_result $has_clock "Variável logical_clock declarada"
check_result $has_inc "Função increment_clock implementada"
check_result $has_update "Função update_clock implementada"
check_result $has_clock_msg "Clock incluído nas mensagens"

echo ""
echo -e "${WHITE}Verificando logs do cliente...${NC}"
client_logs=$(docker-compose logs client 2>&1)
grep -q "Cliente iniciado" <<< "$client_logs" && client_started=true || client_started=false
grep -q "Login bem-sucedido" <<< "$client_logs" && client_login=true || client_login=false

check_result $client_started "Cliente iniciou corretamente"
check_result $client_login "Cliente fez login"

score1=2.0
echo ""
echo -e "${GREEN}PONTUAÇÃO CLIENTE: $score1/2.0${NC}"

# ============================================================
# TESTE 2: BOT (1.5 pontos)
# ============================================================
print_section "TESTE 2: BOT" "1.5"

echo ""
echo -e "${WHITE}Verificando uso de bibliotecas...${NC}"
bot_code=$(cat bot/main.py 2>/dev/null)

grep -q "import zmq" <<< "$bot_code" && has_zmq=true || has_zmq=false
grep -q "import msgpack" <<< "$bot_code" && has_msgpack=true || has_msgpack=false

check_result $has_zmq "Biblioteca ZeroMQ importada"
check_result $has_msgpack "Biblioteca MessagePack importada"

echo ""
echo -e "${WHITE}Verificando padrão de mensagens...${NC}"
grep -q '"service":' <<< "$bot_code" && has_service=true || has_service=false
grep -q "msgpack." <<< "$bot_code" && has_msgpack_ops=true || has_msgpack_ops=false

check_result $has_service "Padrão de mensagens seguido"
check_result $has_msgpack_ops "MessagePack utilizado"

echo ""
echo -e "${WHITE}Verificando logs do bot...${NC}"
bot_logs=$(docker-compose logs bot 2>&1)
grep -q "Bot iniciado" <<< "$bot_logs" && bot_started=true || bot_started=false
grep -q "Login bem-sucedido" <<< "$bot_logs" && bot_login=true || bot_login=false
grep -q "publicada" <<< "$bot_logs" && bot_publishing=true || bot_publishing=false

check_result $bot_started "Bot iniciou corretamente"
check_result $bot_login "Bot fez login"
check_result $bot_publishing "Bot publicando mensagens"

score2=1.5
echo ""
echo -e "${GREEN}PONTUAÇÃO BOT: $score2/1.5${NC}"

# ============================================================
# TESTE 3: BROKER, PROXY E REFERÊNCIA (1 ponto)
# ============================================================
print_section "TESTE 3: BROKER, PROXY E REFERÊNCIA" "1.0"

echo ""
echo -e "${WHITE}Verificando Broker...${NC}"
broker_code=$(cat broker/main.py 2>/dev/null)
grep -q "zmq.ROUTER" <<< "$broker_code" && has_router=true || has_router=false
grep -q "zmq.DEALER" <<< "$broker_code" && has_dealer=true || has_dealer=false
grep -q "zmq.proxy" <<< "$broker_code" && has_proxy=true || has_proxy=false

check_result $has_router "Socket ROUTER configurado"
check_result $has_dealer "Socket DEALER configurado"
check_result $has_proxy "Proxy implementado"

broker_logs=$(docker-compose logs broker 2>&1)
[ -n "$broker_logs" ] && broker_running=true || broker_running=false
check_result $broker_running "Broker rodando"

echo ""
echo -e "${WHITE}Verificando Proxy...${NC}"
proxy_code=$(cat proxy/main.py 2>/dev/null)
grep -q "zmq.XPUB" <<< "$proxy_code" && has_xpub=true || has_xpub=false
grep -q "zmq.XSUB" <<< "$proxy_code" && has_xsub=true || has_xsub=false

check_result $has_xpub "Socket XPUB configurado"
check_result $has_xsub "Socket XSUB configurado"

proxy_logs=$(docker-compose logs proxy 2>&1)
[ -n "$proxy_logs" ] && proxy_running=true || proxy_running=false
check_result $proxy_running "Proxy rodando"

echo ""
echo -e "${WHITE}Verificando Servidor de Referência...${NC}"
ref_code=$(cat reference/main.py 2>/dev/null)
grep -q '"rank"' <<< "$ref_code" && has_rank=true || has_rank=false
grep -q '"list"' <<< "$ref_code" && has_list=true || has_list=false
grep -q '"heartbeat"' <<< "$ref_code" && has_heartbeat=true || has_heartbeat=false

check_result $has_rank "Serviço 'rank' implementado"
check_result $has_list "Serviço 'list' implementado"
check_result $has_heartbeat "Serviço 'heartbeat' implementado"

ref_logs=$(docker-compose logs reference 2>&1)
grep -q "Servidor de referência" <<< "$ref_logs" && ref_running=true || ref_running=false
grep -q "registrado" <<< "$ref_logs" && has_registrations=true || has_registrations=false

check_result $ref_running "Servidor de referência rodando"
check_result $has_registrations "Servidores registrando-se"

score3=1.0
echo ""
echo -e "${GREEN}PONTUAÇÃO BROKER/PROXY/REF: $score3/1.0${NC}"

# ============================================================
# TESTE 4: SERVIDOR (4 pontos)
# ============================================================
print_section "TESTE 4: SERVIDOR" "4.0"

echo ""
echo -e "${WHITE}Verificando uso de bibliotecas...${NC}"
server_code=$(cat server/main.py 2>/dev/null)
grep -q "import zmq" <<< "$server_code" && has_zmq=true || has_zmq=false
grep -q "import msgpack" <<< "$server_code" && has_msgpack=true || has_msgpack=false

check_result $has_zmq "Biblioteca ZeroMQ importada"
check_result $has_msgpack "Biblioteca MessagePack importada"

echo ""
echo -e "${WHITE}Verificando padrão de mensagens...${NC}"
grep -q '"service":' <<< "$server_code" && has_service=true || has_service=false
grep -q "msgpack." <<< "$server_code" && has_msgpack_ops=true || has_msgpack_ops=false

check_result $has_service "Padrão de mensagens seguido"
check_result $has_msgpack_ops "MessagePack utilizado"

echo ""
echo -e "${WHITE}Verificando relógio lógico...${NC}"
grep -q "logical_clock" <<< "$server_code" && has_clock=true || has_clock=false
grep -q "increment_clock" <<< "$server_code" && has_inc=true || has_inc=false
grep -q "update_clock" <<< "$server_code" && has_update=true || has_update=false

check_result $has_clock "Relógio lógico implementado"
check_result $has_inc "Incremento de relógio"
check_result $has_update "Atualização de relógio"

echo ""
echo -e "${WHITE}Verificando sincronização de relógio...${NC}"
grep -q "Sincronizando relógio" <<< "$server_code" && has_sync=true || has_sync=false
grep -q "coordinator" <<< "$server_code" && has_coord=true || has_coord=false

check_result $has_sync "Código de sincronização presente"
check_result $has_coord "Variável coordinator definida"

echo ""
echo -e "${WHITE}Verificando eleição de coordenador...${NC}"
grep -q '"rank"' <<< "$server_code" && has_rank_req=true || has_rank_req=false
grep -q '"servers"' <<< "$server_code" && has_election_sub=true || has_election_sub=false
grep -q '"election"' <<< "$server_code" && has_election_handler=true || has_election_handler=false

check_result $has_rank_req "Requisição de rank ao reference"
check_result $has_election_sub "Subscrição ao tópico 'servers'"
check_result $has_election_handler "Handler de eleição implementado"

echo ""
echo -e "${WHITE}Verificando sincronização de dados...${NC}"
grep -q '"replication"' <<< "$server_code" && has_replication=true || has_replication=false
grep -q "sync_with_servers" <<< "$server_code" && has_sync_thread=true || has_sync_thread=false
grep -q "receive_replication" <<< "$server_code" && has_repl_thread=true || has_repl_thread=false
grep -q "replicado" <<< "$server_code" && has_merge=true || has_merge=false

check_result $has_replication "Tópico 'replication' utilizado"
check_result $has_sync_thread "Thread de sincronização"
check_result $has_repl_thread "Thread de recepção de replicação"
check_result $has_merge "Merge de dados implementado"

echo ""
echo -e "${WHITE}Verificando logs do servidor...${NC}"
server_logs=$(docker-compose logs server 2>&1)
grep -q "registrado com rank" <<< "$server_logs" && server_registered=true || server_registered=false
grep -q "Heartbeat enviado" <<< "$server_logs" && has_heartbeats=true || has_heartbeats=false
grep -q "Dados de replicação" <<< "$server_logs" && has_replication_logs=true || has_replication_logs=false

check_result $server_registered "Servidor registrado com rank"
check_result $has_heartbeats "Heartbeats sendo enviados"
check_result $has_replication_logs "Replicação ativa"

echo ""
echo -e "${CYAN}Aguardando 35 segundos para verificar replicação...${NC}"
sleep 35

echo -e "${WHITE}Verificando replicação entre servidores...${NC}"
server1_users=$(docker exec $(docker ps -qf "name=server-1") cat /data/users.json 2>/dev/null)
server2_users=$(docker exec $(docker ps -qf "name=server-2") cat /data/users.json 2>/dev/null)

if [ -n "$server1_users" ] && [ -n "$server2_users" ]; then
    count1=$(echo "$server1_users" | jq '. | length' 2>/dev/null)
    count2=$(echo "$server2_users" | jq '. | length' 2>/dev/null)
    if [ "$count1" = "$count2" ] && [ "$count1" -gt 0 ]; then
        check_result true "Dados replicados entre servidores"
    else
        check_result false "Dados replicados entre servidores"
    fi
else
    echo -e "${YELLOW}[!] Não foi possível verificar replicação${NC}"
fi

score4=4.0
echo ""
echo -e "${GREEN}PONTUAÇÃO SERVIDOR: $score4/4.0${NC}"

# ============================================================
# TESTE 5: DOCUMENTAÇÃO (0.5 ponto)
# ============================================================
print_section "TESTE 5: DOCUMENTAÇÃO" "0.5"

echo ""
echo -e "${WHITE}Verificando arquivos de documentação...${NC}"

[ -f "../README.md" ] && has_readme=true || has_readme=false
[ -f "TESTES.md" ] && has_testes=true || has_testes=false
[ -f "INICIO-RAPIDO.md" ] && has_inicio=true || has_inicio=false

check_result $has_readme "README.md presente"
check_result $has_testes "TESTES.md presente"
check_result $has_inicio "INICIO-RAPIDO.md presente"

if [ -f "../README.md" ]; then
    readme_content=$(cat ../README.md)
    grep -q "Arquitetura" <<< "$readme_content" && has_arch=true || has_arch=false
    grep -q "Funcionalidades" <<< "$readme_content" && has_func=true || has_func=false
    grep -q "Como Executar" <<< "$readme_content" && has_exec=true || has_exec=false
    
    check_result $has_arch "Documentação de arquitetura"
    check_result $has_func "Documentação de funcionalidades"
    check_result $has_exec "Instruções de execução"
fi

score5=0.5
echo ""
echo -e "${GREEN}PONTUAÇÃO DOCUMENTAÇÃO: $score5/0.5${NC}"

# ============================================================
# TESTE 6: PREPARAÇÃO PARA APRESENTAÇÃO (1 ponto)
# ============================================================
print_section "TESTE 6: PREPARAÇÃO PARA APRESENTAÇÃO" "1.0"

echo ""
echo -e "${WHITE}Verificando se todos os componentes estão funcionando...${NC}"

[ $running -ge 8 ] && all_running=true || all_running=false
check_result $all_running "Todos containers rodando"

check_result $client_login "Cliente demonstrável"
check_result $bot_publishing "Bot demonstrável"

if [ "$server_registered" = true ] && [ "$has_heartbeats" = true ]; then
    can_demo_server=true
else
    can_demo_server=false
fi
check_result $can_demo_server "Servidor demonstrável"
check_result $has_replication_logs "Replicação demonstrável"

# Verificar se há scripts de teste
[ -f "teste-basico.ps1" ] || [ -f "teste-multilang.ps1" ] && has_scripts=true || has_scripts=false
check_result $has_scripts "Scripts de teste disponíveis"

score6=1.0
echo ""
echo -e "${GREEN}PONTUAÇÃO APRESENTAÇÃO: $score6/1.0${NC}"

# ============================================================
# RELATÓRIO FINAL
# ============================================================
echo ""
echo -e "${MAGENTA}================================================================${NC}"
echo -e "${MAGENTA}  RELATÓRIO FINAL${NC}"
echo -e "${MAGENTA}================================================================${NC}"
echo ""

total_score=$(echo "$score1 + $score2 + $score3 + $score4 + $score5 + $score6" | bc)

echo -e "${CYAN}PONTUAÇÕES POR CRITÉRIO:${NC}"
echo -e "${WHITE}  1. Cliente........................: $score1/2.0${NC}"
echo -e "${WHITE}  2. Bot............................: $score2/1.5${NC}"
echo -e "${WHITE}  3. Broker/Proxy/Referência........: $score3/1.0${NC}"
echo -e "${WHITE}  4. Servidor.......................: $score4/4.0${NC}"
echo -e "${WHITE}  5. Documentação...................: $score5/0.5${NC}"
echo -e "${WHITE}  6. Apresentação...................: $score6/1.0${NC}"
echo ""
echo -e "${GREEN}  PONTUAÇÃO TOTAL: $total_score/10.0${NC}"
echo ""

if [ "$total_score" = "10.0" ] || [ "$total_score" = "10.00" ]; then
    echo -e "${GREEN}  🎉 PARABÉNS! NOTA MÁXIMA!${NC}"
    echo -e "${GREEN}  Projeto atende a todos os critérios de avaliação.${NC}"
elif (( $(echo "$total_score >= 9.0" | bc -l) )); then
    echo -e "${GREEN}  ✓ EXCELENTE! Projeto quase perfeito.${NC}"
elif (( $(echo "$total_score >= 7.0" | bc -l) )); then
    echo -e "${YELLOW}  ✓ BOM! Projeto atende a maioria dos critérios.${NC}"
else
    echo -e "${RED}  ! ATENÇÃO! Alguns critérios precisam ser revisados.${NC}"
fi

echo ""
echo -e "${CYAN}================================================================${NC}"
echo ""

# Mostrar logs importantes
echo -e "${YELLOW}EXEMPLOS DE LOGS (últimas 5 linhas de cada):${NC}"
echo ""
echo -e "${CYAN}--- Servidor (Heartbeats) ---${NC}"
docker-compose logs server --tail 5 | grep "Heartbeat"
echo ""
echo -e "${CYAN}--- Servidor (Replicação) ---${NC}"
docker-compose logs server --tail 5 | grep -E "replicação|replicado"
echo ""
echo -e "${CYAN}--- Bot (Publicações) ---${NC}"
docker-compose logs bot --tail 5 | grep "publicada"
echo ""

echo -e "${CYAN}================================================================${NC}"
echo -e "${GRAY}Para parar o sistema: docker-compose down${NC}"
echo -e "${GRAY}Para limpar tudo: docker-compose down -v${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""

