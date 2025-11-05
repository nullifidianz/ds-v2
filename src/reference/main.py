import zmq
import json
import time
import msgpack
import threading

context = zmq.Context()

rep_socket = context.socket(zmq.REP)
rep_socket.bind("tcp://*:5559")

print("Servidor de referência iniciado na porta 5559")

# Relógio lógico
logical_clock = 0

def increment_clock():
    global logical_clock
    logical_clock += 1
    return logical_clock

def update_clock(received_clock):
    global logical_clock
    logical_clock = max(logical_clock, received_clock) + 1
    return logical_clock

# Armazenamento de servidores
servers = {}  # {nome: {"rank": int, "last_heartbeat": timestamp}}
next_rank = 1
servers_lock = threading.Lock()

# Thread para remover servidores inativos (sem heartbeat há mais de 30 segundos)
def cleanup_inactive_servers():
    global servers
    while True:
        time.sleep(10)
        with servers_lock:
            current_time = time.time()
            inactive = [name for name, info in servers.items() 
                       if current_time - info["last_heartbeat"] > 30]
            for name in inactive:
                print(f"Removendo servidor inativo: {name}")
                del servers[name]

cleanup_thread = threading.Thread(target=cleanup_inactive_servers, daemon=True)
cleanup_thread.start()

# Loop principal
while True:
    try:
        message = msgpack.unpackb(rep_socket.recv(), raw=False)
        print(f"Mensagem recebida: {message}")
        
        service = message.get("service")
        data = message.get("data", {})
        
        # Atualizar relógio lógico
        received_clock = data.get("clock", 0)
        update_clock(received_clock)
        
        response = {}
        
        if service == "rank":
            user = data.get("user")
            
            with servers_lock:
                if user not in servers:
                    servers[user] = {
                        "rank": next_rank,
                        "last_heartbeat": time.time()
                    }
                    rank = next_rank
                    next_rank += 1
                    print(f"Novo servidor registrado: {user} com rank {rank}")
                else:
                    rank = servers[user]["rank"]
                    servers[user]["last_heartbeat"] = time.time()
                    print(f"Servidor {user} já cadastrado com rank {rank}")
            
            response = {
                "service": "rank",
                "data": {
                    "rank": rank,
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
        
        elif service == "list":
            with servers_lock:
                server_list = [
                    {"name": name, "rank": info["rank"]} 
                    for name, info in servers.items()
                ]
            
            response = {
                "service": "list",
                "data": {
                    "list": server_list,
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
        
        elif service == "heartbeat":
            user = data.get("user")
            
            with servers_lock:
                if user in servers:
                    servers[user]["last_heartbeat"] = time.time()
                    print(f"Heartbeat recebido de {user}")
                    status = "OK"
                else:
                    print(f"Heartbeat de servidor desconhecido: {user}")
                    status = "unknown"
            
            response = {
                "service": "heartbeat",
                "data": {
                    "status": status,
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
        
        else:
            response = {
                "service": service,
                "data": {
                    "status": "erro",
                    "timestamp": time.time(),
                    "clock": increment_clock(),
                    "description": "Serviço não reconhecido"
                }
            }
        
        rep_socket.send(msgpack.packb(response))
        print(f"Resposta enviada: {response}")
        
    except Exception as e:
        print(f"Erro no servidor de referência: {e}")
        error_response = {
            "service": "error",
            "data": {
                "status": "erro",
                "timestamp": time.time(),
                "clock": increment_clock(),
                "description": str(e)
            }
        }
        rep_socket.send(msgpack.packb(error_response))

