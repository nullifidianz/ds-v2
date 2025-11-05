import zmq
import json
import os
import time
import msgpack
from datetime import datetime

# Configuração de diretório de dados
DATA_DIR = "/data"
os.makedirs(DATA_DIR, exist_ok=True)

# Arquivos de persistência
USERS_FILE = os.path.join(DATA_DIR, "users.json")
CHANNELS_FILE = os.path.join(DATA_DIR, "channels.json")
LOGINS_FILE = os.path.join(DATA_DIR, "logins.json")
MESSAGES_FILE = os.path.join(DATA_DIR, "messages.json")
PUBLICATIONS_FILE = os.path.join(DATA_DIR, "publications.json")

# Funções de persistência
def load_json(filepath, default=None):
    if default is None:
        default = []
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            return json.load(f)
    return default

def save_json(filepath, data):
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=2)

# Carregar dados existentes
users = load_json(USERS_FILE, [])
channels = load_json(CHANNELS_FILE, [])
logins = load_json(LOGINS_FILE, [])
messages = load_json(MESSAGES_FILE, [])
publications = load_json(PUBLICATIONS_FILE, [])

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

context = zmq.Context()

rep_socket = context.socket(zmq.REP)
rep_socket.connect("tcp://broker:5556")

pub_socket = context.socket(zmq.PUB)
pub_socket.connect("tcp://proxy:5557")

# Socket para servidor de referência
ref_socket = context.socket(zmq.REQ)
ref_socket.connect("tcp://reference:5559")

# Subscrever ao tópico 'servers' para eleições
sub_socket = context.socket(zmq.SUB)
sub_socket.connect("tcp://proxy:5558")
sub_socket.setsockopt_string(zmq.SUBSCRIBE, "servers")

print("Servidor iniciado e conectado ao broker, proxy e referência")

# Obter rank do servidor de referência
import socket
server_name = os.environ.get("SERVER_NAME", "server") + "_" + socket.gethostname()
rank_msg = {
    "service": "rank",
    "data": {
        "user": server_name,
        "timestamp": time.time(),
        "clock": increment_clock()
    }
}
ref_socket.send(msgpack.packb(rank_msg))
rank_response = msgpack.unpackb(ref_socket.recv(), raw=False)
update_clock(rank_response.get("data", {}).get("clock", 0))
server_rank = rank_response.get("data", {}).get("rank", 0)
print(f"Servidor {server_name} registrado com rank {server_rank}")

# Variáveis para eleição e sincronização
coordinator = None
message_counter = 0

# Thread para enviar heartbeats
import threading

def send_heartbeat():
    while True:
        time.sleep(10)
        try:
            hb_msg = {
                "service": "heartbeat",
                "data": {
                    "user": server_name,
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
            ref_socket.send(msgpack.packb(hb_msg))
            hb_response = msgpack.unpackb(ref_socket.recv(), raw=False)
            update_clock(hb_response.get("data", {}).get("clock", 0))
            print(f"Heartbeat enviado, status: {hb_response.get('data', {}).get('status')}")
        except Exception as e:
            print(f"Erro ao enviar heartbeat: {e}")

heartbeat_thread = threading.Thread(target=send_heartbeat, daemon=True)
heartbeat_thread.start()

# Thread para sincronização de dados entre servidores
def sync_with_servers():
    """Sincroniza dados com outros servidores periodicamente"""
    while True:
        time.sleep(30)  # Sincronizar a cada 30 segundos
        try:
            # Obter lista de servidores do servidor de referência
            list_msg = {
                "service": "list",
                "data": {
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
            ref_socket.send(msgpack.packb(list_msg))
            list_response = msgpack.unpackb(ref_socket.recv(), raw=False)
            update_clock(list_response.get("data", {}).get("clock", 0))
            server_list = list_response.get("data", {}).get("list", [])
            
            # Publicar dados atuais no tópico de replicação
            # (outros servidores inscritos receberão)
            replication_data = {
                "service": "replication",
                "data": {
                    "server": server_name,
                    "users": users,
                    "channels": channels,
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
            pub_socket.send_string("replication", zmq.SNDMORE)
            pub_socket.send(msgpack.packb(replication_data))
            print("Dados de replicação publicados")
            
        except Exception as e:
            print(f"Erro na sincronização de dados: {e}")

# Subscrever ao tópico de replicação
sub_socket.setsockopt_string(zmq.SUBSCRIBE, "replication")

# Thread para receber dados de replicação
def receive_replication():
    """Recebe e merge dados de outros servidores"""
    rep_sub = context.socket(zmq.SUB)
    rep_sub.connect("tcp://proxy:5558")
    rep_sub.setsockopt_string(zmq.SUBSCRIBE, "replication")
    
    while True:
        try:
            topic = rep_sub.recv_string()
            msg = msgpack.unpackb(rep_sub.recv(), raw=False)
            
            if msg.get("service") == "replication":
                data = msg.get("data", {})
                remote_server = data.get("server")
                
                if remote_server != server_name:  # Não processar próprios dados
                    remote_users = data.get("users", [])
                    remote_channels = data.get("channels", [])
                    
                    # Merge de usuários
                    for user in remote_users:
                        if user not in users:
                            users.append(user)
                            print(f"Usuário replicado de {remote_server}: {user}")
                    
                    # Merge de canais
                    for channel in remote_channels:
                        if channel not in channels:
                            channels.append(channel)
                            print(f"Canal replicado de {remote_server}: {channel}")
                    
                    # Salvar dados atualizados
                    save_json(USERS_FILE, users)
                    save_json(CHANNELS_FILE, channels)
                    
                    update_clock(data.get("clock", 0))
        except Exception as e:
            print(f"Erro ao receber replicação: {e}")

sync_thread = threading.Thread(target=sync_with_servers, daemon=True)
sync_thread.start()

replication_thread = threading.Thread(target=receive_replication, daemon=True)
replication_thread.start()

# Loop principal do servidor
while True:
    try:
        # Verificar mensagens no tópico servers (eleição) com timeout
        try:
            topic = sub_socket.recv_string(zmq.NOBLOCK)
            election_msg = msgpack.unpackb(sub_socket.recv(), raw=False)
            if election_msg.get("service") == "election":
                new_coordinator = election_msg.get("data", {}).get("coordinator")
                coordinator = new_coordinator
                print(f"Novo coordenador eleito: {coordinator}")
                update_clock(election_msg.get("data", {}).get("clock", 0))
        except zmq.Again:
            pass  # Sem mensagens de eleição
        
        # Receber mensagem (MessagePack)
        message = msgpack.unpackb(rep_socket.recv(), raw=False)
        print(f"Mensagem recebida: {message}")
        
        service = message.get("service")
        data = message.get("data", {})
        
        # Atualizar relógio lógico com o recebido
        received_clock = data.get("clock", 0)
        update_clock(received_clock)
        
        # Incrementar contador de mensagens e sincronizar relógio se necessário
        message_counter += 1
        if message_counter >= 10 and coordinator:
            message_counter = 0
            # Sincronização de relógio simplificada (Berkeley)
            # Em produção, implementaria a coleta de tempos de todos os servidores
            print(f"Sincronizando relógio com coordenador {coordinator}")
        
        response = {}
        
        # Processar serviços
        if service == "login":
            user = data.get("user")
            timestamp = data.get("timestamp")
            
            if not user:
                response = {
                    "service": "login",
                    "data": {
                        "status": "erro",
                        "timestamp": time.time(),
                        "clock": increment_clock(),
                        "description": "Nome de usuário não fornecido"
                    }
                }
            elif user in users:
                response = {
                    "service": "login",
                    "data": {
                        "status": "erro",
                        "timestamp": time.time(),
                        "clock": increment_clock(),
                        "description": "Usuário já existe"
                    }
                }
            else:
                users.append(user)
                logins.append({"user": user, "timestamp": timestamp})
                save_json(USERS_FILE, users)
                save_json(LOGINS_FILE, logins)
                response = {
                    "service": "login",
                    "data": {
                        "status": "sucesso",
                        "timestamp": time.time(),
                        "clock": increment_clock()
                    }
                }
        
        elif service == "users":
            response = {
                "service": "users",
                "data": {
                    "timestamp": time.time(),
                    "clock": increment_clock(),
                    "users": users
                }
            }
        
        elif service == "channel":
            channel = data.get("channel")
            timestamp = data.get("timestamp")
            
            if not channel:
                response = {
                    "service": "channel",
                    "data": {
                        "status": "erro",
                        "timestamp": time.time(),
                        "clock": increment_clock(),
                        "description": "Nome de canal não fornecido"
                    }
                }
            elif channel in channels:
                response = {
                    "service": "channel",
                    "data": {
                        "status": "erro",
                        "timestamp": time.time(),
                        "clock": increment_clock(),
                        "description": "Canal já existe"
                    }
                }
            else:
                channels.append(channel)
                save_json(CHANNELS_FILE, channels)
                response = {
                    "service": "channel",
                    "data": {
                        "status": "sucesso",
                        "timestamp": time.time(),
                        "clock": increment_clock()
                    }
                }
        
        elif service == "channels":
            response = {
                "service": "channels",
                "data": {
                    "timestamp": time.time(),
                    "clock": increment_clock(),
                    "channels": channels
                }
            }
        
        elif service == "publish":
            user = data.get("user")
            channel = data.get("channel")
            msg_content = data.get("message")
            timestamp = data.get("timestamp")
            
            if channel not in channels:
                response = {
                    "service": "publish",
                    "data": {
                        "status": "erro",
                        "message": "Canal não existe",
                        "timestamp": time.time(),
                        "clock": increment_clock()
                    }
                }
            else:
                # Publicar no canal
                pub_msg = {
                    "service": "publish",
                    "data": {
                        "user": user,
                        "channel": channel,
                        "message": msg_content,
                        "timestamp": timestamp,
                        "clock": increment_clock()
                    }
                }
                pub_socket.send_string(channel, zmq.SNDMORE)
                pub_socket.send(msgpack.packb(pub_msg))
                
                # Salvar publicação
                publications.append({
                    "user": user,
                    "channel": channel,
                    "message": msg_content,
                    "timestamp": timestamp
                })
                save_json(PUBLICATIONS_FILE, publications)
                
                response = {
                    "service": "publish",
                    "data": {
                        "status": "OK",
                        "timestamp": time.time(),
                        "clock": increment_clock()
                    }
                }
        
        elif service == "message":
            src = data.get("src")
            dst = data.get("dst")
            msg_content = data.get("message")
            timestamp = data.get("timestamp")
            
            if dst not in users:
                response = {
                    "service": "message",
                    "data": {
                        "status": "erro",
                        "message": "Usuário não existe",
                        "timestamp": time.time(),
                        "clock": increment_clock()
                    }
                }
            else:
                # Publicar para o usuário destino
                pub_msg = {
                    "service": "message",
                    "data": {
                        "src": src,
                        "dst": dst,
                        "message": msg_content,
                        "timestamp": timestamp,
                        "clock": increment_clock()
                    }
                }
                pub_socket.send_string(dst, zmq.SNDMORE)
                pub_socket.send(msgpack.packb(pub_msg))
                
                # Salvar mensagem
                messages.append({
                    "src": src,
                    "dst": dst,
                    "message": msg_content,
                    "timestamp": timestamp
                })
                save_json(MESSAGES_FILE, messages)
                
                response = {
                    "service": "message",
                    "data": {
                        "status": "OK",
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
        
        # Enviar resposta (MessagePack)
        rep_socket.send(msgpack.packb(response))
        print(f"Resposta enviada: {response}")
        
    except Exception as e:
        print(f"Erro no servidor: {e}")
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
