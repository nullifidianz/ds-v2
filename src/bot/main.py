import zmq
import json
import time
import random
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

print("Bot iniciado e conectado ao broker e proxy")

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

# Tentar fazer login com nome aleatório
username = f"bot_{random.randint(1000, 9999)}"
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

if response.get("data", {}).get("status") != "sucesso":
    print(f"Erro no login: {response.get('data', {}).get('description')}")
    exit(1)

print(f"Login bem-sucedido como {username}")

# Inscrever-se no tópico do próprio usuário
sub_socket.setsockopt_string(zmq.SUBSCRIBE, username)

# Mensagens predefinidas
messages = [
    "Olá a todos!",
    "Como estão?",
    "Que dia lindo!",
    "Alguém aí?",
    "Vamos conversar!",
    "Bot reportando presença",
    "Sistema funcionando perfeitamente",
    "Tudo operacional",
    "Dados sincronizados",
    "Status: OK"
]

# Loop principal do bot
while True:
    try:
        # Obter lista de canais
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
        
        if not channels:
            print("Nenhum canal disponível, esperando 5 segundos...")
            time.sleep(5)
            continue
        
        # Escolher canal aleatório
        channel = random.choice(channels)
        print(f"\nEnviando mensagens para o canal: {channel}")
        
        # Enviar 10 mensagens
        for i in range(10):
            message = random.choice(messages)
            msg = {
                "service": "publish",
                "data": {
                    "user": username,
                    "channel": channel,
                    "message": f"{message} (msg {i+1}/10)",
                    "timestamp": time.time(),
                    "clock": increment_clock()
                }
            }
            req_socket.send(msgpack.packb(msg))
            response = msgpack.unpackb(req_socket.recv(), raw=False)
            update_clock(response.get("data", {}).get("clock", 0))
            
            if response.get("data", {}).get("status") == "OK":
                print(f"Mensagem {i+1}/10 publicada: {message}")
            else:
                print(f"Erro ao publicar mensagem: {response.get('data', {}).get('message')}")
            
            time.sleep(1)  # Esperar 1 segundo entre mensagens
        
        print("Ciclo completo, aguardando 5 segundos antes do próximo...")
        time.sleep(5)
        
    except KeyboardInterrupt:
        print("\nBot interrompido")
        break
    except Exception as e:
        print(f"Erro no bot: {e}")
        time.sleep(5)

context.term()

