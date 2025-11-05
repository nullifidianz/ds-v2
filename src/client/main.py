import zmq
import json
import time
import sys
import os
import msgpack

req_address = "broker"
req_port = 5555

sub_address = "proxy"
sub_port = 5558

context = zmq.Context()

req_socket = context.socket(zmq.REQ)
req_socket.connect(f"tcp://{req_address}:{req_port}")

sub_socket = context.socket(zmq.SUB)
sub_socket.connect(f"tcp://{sub_address}:{sub_port}")

print("Cliente iniciado e conectado ao broker e proxy")

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

# Tentar fazer login
username = os.environ.get("USERNAME", f"user_{int(time.time())}")
print(f"Tentando login como: {username}")

login_msg = {
    "service": "login",
    "data": {
        "user": username,
        "timestamp": time.time(),
        "clock": increment_clock()
    }
}

req_socket.send(msgpack.packb(login_msg))
response = msgpack.unpackb(req_socket.recv(), raw=False)
update_clock(response.get("data", {}).get("clock", 0))
print(f"Resposta do login: {response}")

if response.get("data", {}).get("status") == "sucesso":
    print(f"Login bem-sucedido como {username}")
    # Inscrever-se no tópico do próprio usuário para receber mensagens
    sub_socket.setsockopt_string(zmq.SUBSCRIBE, username)
else:
    print(f"Erro no login: {response.get('data', {}).get('description')}")
    sys.exit(1)

# Thread para receber mensagens
import threading

def receive_messages():
    while True:
        try:
            topic = sub_socket.recv_string()
            msg = msgpack.unpackb(sub_socket.recv(), raw=False)
            update_clock(msg.get("data", {}).get("clock", 0))
            service = msg.get("service")
            data = msg.get("data", {})
            
            if service == "message":
                print(f"\n[MENSAGEM de {data.get('src')}]: {data.get('message')}")
            elif service == "publish":
                print(f"\n[CANAL {data.get('channel')} - {data.get('user')}]: {data.get('message')}")
        except Exception as e:
            print(f"Erro ao receber mensagem: {e}")
            break

receiver_thread = threading.Thread(target=receive_messages, daemon=True)
receiver_thread.start()

# Menu interativo
print("\n=== Menu ===")
print("1. Listar usuários")
print("2. Criar canal")
print("3. Listar canais")
print("4. Inscrever em canal")
print("5. Enviar mensagem privada")
print("6. Publicar em canal")
print("7. Sair")

while True:
    print("\nEscolha uma opção (1-7): ", end="", flush=True)
    try:
        choice = input().strip()
        
        if choice == "1":
            msg = {
                "service": "users",
                "data": {
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
            req_socket.send(msgpack.packb(msg))
            response = msgpack.unpackb(req_socket.recv(), raw=False)
            update_clock(response.get("data", {}).get("clock", 0))
            users = response.get("data", {}).get("users", [])
            print(f"Usuários cadastrados: {users}")
        
        elif choice == "2":
            print("Nome do canal: ", end="", flush=True)
            channel_name = input().strip()
            msg = {
                "service": "channel",
                "data": {
                    "channel": channel_name,
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
            req_socket.send(msgpack.packb(msg))
            response = msgpack.unpackb(req_socket.recv(), raw=False)
            update_clock(response.get("data", {}).get("clock", 0))
            if response.get("data", {}).get("status") == "sucesso":
                print(f"Canal '{channel_name}' criado com sucesso")
            else:
                print(f"Erro: {response.get('data', {}).get('description')}")
        
        elif choice == "3":
            msg = {
                "service": "channels",
                "data": {
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
            req_socket.send(msgpack.packb(msg))
            response = msgpack.unpackb(req_socket.recv(), raw=False)
            update_clock(response.get("data", {}).get("clock", 0))
            channels = response.get("data", {}).get("channels", [])
            print(f"Canais disponíveis: {channels}")
        
        elif choice == "4":
            print("Nome do canal: ", end="", flush=True)
            channel_name = input().strip()
            sub_socket.setsockopt_string(zmq.SUBSCRIBE, channel_name)
            print(f"Inscrito no canal '{channel_name}'")
        
        elif choice == "5":
            print("Destinatário: ", end="", flush=True)
            dst = input().strip()
            print("Mensagem: ", end="", flush=True)
            message = input().strip()
            msg = {
                "service": "message",
                "data": {
                    "src": username,
                    "dst": dst,
                    "message": message,
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
            req_socket.send(msgpack.packb(msg))
            response = msgpack.unpackb(req_socket.recv(), raw=False)
            update_clock(response.get("data", {}).get("clock", 0))
            if response.get("data", {}).get("status") == "OK":
                print("Mensagem enviada com sucesso")
            else:
                print(f"Erro: {response.get('data', {}).get('message')}")
        
        elif choice == "6":
            print("Canal: ", end="", flush=True)
            channel = input().strip()
            print("Mensagem: ", end="", flush=True)
            message = input().strip()
            msg = {
                "service": "publish",
                "data": {
                    "user": username,
                    "channel": channel,
                    "message": message,
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
            req_socket.send(msgpack.packb(msg))
            response = msgpack.unpackb(req_socket.recv(), raw=False)
            update_clock(response.get("data", {}).get("clock", 0))
            if response.get("data", {}).get("status") == "OK":
                print("Publicação realizada com sucesso")
            else:
                print(f"Erro: {response.get('data', {}).get('message')}")
        
        elif choice == "7":
            print("Saindo...")
            break
        
        else:
            print("Opção inválida")
    
    except KeyboardInterrupt:
        print("\nSaindo...")
        break
    except Exception as e:
        print(f"Erro: {e}")

context.term()
