import zmq
import json
import os
import time
import threading
from typing import Dict, List, Any, Optional
from serde import serializer
from clock import LamportClock

class Server:
    def __init__(self, server_name: str = None):
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.REP)
        self.socket.connect("tcp://broker:5556")

        # Socket para publicar mensagens
        self.pub_socket = self.context.socket(zmq.PUB)
        self.pub_socket.connect("tcp://proxy:5557")

        # Socket para comunicação com referência
        self.ref_socket = self.context.socket(zmq.REQ)
        self.ref_socket.connect("tcp://reference:5559")

        # Relógio lógico
        self.clock = LamportClock()

        # Dados do servidor
        # Preferir nome configurado; caso contrário, usar HOSTNAME do container (único). Como fallback final, usa PID.
        self.server_name = server_name or os.getenv("SERVER_NAME") or os.getenv("HOSTNAME", f"server-{os.getpid()}")
        self.rank = None
        self.coordinator = None
        self.other_servers = []
        self.message_count = 0

        # Berkeley sync
        self.berkeley_enabled = True
        self.berkeley_interval = 10

        # Dados persistentes
        self.data_dir = "/data"
        os.makedirs(self.data_dir, exist_ok=True)

        self.users_file = os.path.join(self.data_dir, "users.json")
        self.channels_file = os.path.join(self.data_dir, "channels.json")
        self.messages_dir = os.path.join(self.data_dir, "messages")
        os.makedirs(self.messages_dir, exist_ok=True)

        # Carregar dados existentes
        self.users = self._load_json(self.users_file, [])
        self.channels = self._load_json(self.channels_file, [])

        # Socket para replicação
        self.rep_socket = self.context.socket(zmq.SUB)
        self.rep_socket.connect("tcp://proxy:5558")
        self.rep_socket.setsockopt_string(zmq.SUBSCRIBE, "replication")

        # Estado da replicação
        self.applied_events = set()  # (clock, server_id) já aplicados
        self.server_id = hash(self.server_name) % 10000  # ID simples baseado no nome

        # Iniciar threads de manutenção
        self.start_maintenance_threads()

    def _load_json(self, filepath: str, default: Any) -> Any:
        """Carrega JSON ou retorna valor padrão"""
        if os.path.exists(filepath):
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except json.JSONDecodeError:
                return default
        return default

    def _save_json(self, filepath: str, data: Any):
        """Salva dados em JSON"""
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

    def _persist_message(self, message_data: Dict, message_type: str):
        """Persiste mensagem em arquivo JSONL"""
        filename = f"{message_type}s.jsonl"
        filepath = os.path.join(self.messages_dir, filename)

        with open(filepath, 'a', encoding='utf-8') as f:
            json.dump(message_data, f, ensure_ascii=False)
            f.write('\n')

    def _publish_message(self, topic: str, message: Dict):
        """Publica mensagem no tópico especificado"""
        envelope = [topic.encode('utf-8'), serializer.serialize(message)]
        self.pub_socket.send_multipart(envelope)
        print(f"Publicado no tópico '{topic}': {message}")

    def _user_exists(self, username: str) -> bool:
        """Verifica se usuário existe"""
        return any(u["name"] == username for u in self.users)

    def _channel_exists(self, channel: str) -> bool:
        """Verifica se canal existe"""
        return any(c["name"] == channel for c in self.channels)

    def start_maintenance_threads(self):
        """Inicia threads de manutenção em background"""
        # Thread para heartbeat com referência
        threading.Thread(target=self.heartbeat_loop, daemon=True).start()

        # Thread para eleição se necessário
        threading.Thread(target=self.election_monitor, daemon=True).start()

        # Thread para replicação
        threading.Thread(target=self.replication_listener, daemon=True).start()

    def register_with_reference(self):
        """Registra este servidor com o servidor de referência"""
        try:
            clock = self.clock.tick()
            request = {
                "service": "rank",
                "data": {
                    "user": self.server_name,
                    "timestamp": time.time(),
                    "clock": clock
                }
            }

            self.ref_socket.send(serializer.serialize(request))
            response_raw = self.ref_socket.recv()
            response = serializer.deserialize(response_raw)

            if response.get("data", {}).get("rank"):
                self.rank = response["data"]["rank"]
                print(f"Servidor {self.server_name} registrado com rank {self.rank}")

                if response.get("data", {}).get("clock"):
                    self.clock.update(response["data"]["clock"])

                return True
            else:
                print(f"Erro ao registrar servidor: {response}")
                return False

        except Exception as e:
            print(f"Erro na comunicação com referência: {e}")
            return False

    def update_server_list(self):
        """Atualiza lista de servidores do servidor de referência"""
        try:
            clock = self.clock.tick()
            request = {
                "service": "list",
                "data": {
                    "timestamp": time.time(),
                    "clock": clock
                }
            }

            self.ref_socket.send(serializer.serialize(request))
            response_raw = self.ref_socket.recv()
            response = serializer.deserialize(response_raw)

            if response.get("data", {}).get("list"):
                self.other_servers = response["data"]["list"]
                # Remove este servidor da lista
                self.other_servers = [s for s in self.other_servers if s["name"] != self.server_name]

                # Atualizar coordenador (menor rank ativo)
                if self.other_servers:
                    sorted_servers = sorted(self.other_servers, key=lambda s: s["rank"])
                    self.coordinator = sorted_servers[0]["name"]
                else:
                    self.coordinator = self.server_name

                print(f"Lista de servidores atualizada. Coordenador: {self.coordinator}")

                if response.get("data", {}).get("clock"):
                    self.clock.update(response["data"]["clock"])

        except Exception as e:
            print(f"Erro ao atualizar lista de servidores: {e}")

    def heartbeat_loop(self):
        """Loop de heartbeat com o servidor de referência"""
        while True:
            try:
                if not self.rank:
                    if not self.register_with_reference():
                        time.sleep(5)
                        continue

                # Enviar heartbeat
                clock = self.clock.tick()
                request = {
                    "service": "heartbeat",
                    "data": {
                        "user": self.server_name,
                        "timestamp": time.time(),
                        "clock": clock
                    }
                }

                self.ref_socket.send(serializer.serialize(request))
                response_raw = self.ref_socket.recv()
                response = serializer.deserialize(response_raw)

                if response.get("data", {}).get("clock"):
                    self.clock.update(response["data"]["clock"])

                # Atualizar lista a cada heartbeat
                self.update_server_list()

            except Exception as e:
                print(f"Erro no heartbeat: {e}")
                self.rank = None  # Forçar re-registro

            time.sleep(10)  # Heartbeat a cada 10 segundos

    def election_monitor(self):
        """Monitora necessidade de eleição"""
        while True:
            time.sleep(5)

            if not self.coordinator or self.coordinator == self.server_name:
                continue

            # Verificar se coordenador ainda está ativo
            coordinator_active = any(s["name"] == self.coordinator for s in self.other_servers)

            if not coordinator_active:
                print(f"Coordenador {self.coordinator} não está ativo. Iniciando eleição...")
                self.start_election()

    def start_election(self):
        """Inicia processo de eleição usando algoritmo Bully"""
        if not self.other_servers:
            self.coordinator = self.server_name
            self.announce_coordinator()
            return

        # Encontrar servidores com rank maior
        higher_rank_servers = [s for s in self.other_servers if s["rank"] > self.rank]

        if not higher_rank_servers:
            # Este é o servidor com maior rank, é o novo coordenador
            self.coordinator = self.server_name
            self.announce_coordinator()
            return

        # Enviar mensagens de eleição para servidores com rank maior
        election_won = True
        for server in higher_rank_servers:
            try:
                # Simular envio de mensagem de eleição
                # Em implementação real, precisaria de socket direto para cada servidor
                print(f"Enviando eleição para {server['name']} (rank {server['rank']})")
                # Se nenhum servidor com rank maior responder, este ganha
                time.sleep(1)  # Simular timeout
            except:
                continue

        if election_won:
            self.coordinator = self.server_name
            self.announce_coordinator()

    def announce_coordinator(self):
        """Anuncia novo coordenador via PUB/SUB"""
        message = {
            "service": "election",
            "data": {
                "coordinator": self.coordinator,
                "timestamp": time.time(),
                "clock": self.clock.tick()
            }
        }

        self._publish_message("servers", message)
        print(f"Novo coordenador anunciado: {self.coordinator}")

    def sync_berkeley(self):
        """Sincroniza relógio usando algoritmo de Berkeley"""
        if not self.coordinator or self.coordinator != self.server_name:
            return  # Só o coordenador pode iniciar Berkeley

        try:
            # Simular coleta de tempos dos outros servidores
            # Em implementação real, enviaria requisições para cada servidor
            times = [time.time()]

            if times:
                # Calcular média e ajustar
                average_time = sum(times) / len(times)
                adjustment = average_time - time.time()

                print(f"Sincronização Berkeley: ajuste de {adjustment:.3f} segundos")
                # Em implementação real, ajustaria o relógio do sistema

        except Exception as e:
            print(f"Erro na sincronização Berkeley: {e}")

    def check_berkeley_sync(self):
        """Verifica se deve sincronizar relógio"""
        self.message_count += 1
        if self.berkeley_enabled and self.message_count >= self.berkeley_interval:
            self.sync_berkeley()
            self.message_count = 0

    def publish_event(self, event_type: str, event_data: Dict):
        """Publica evento para replicação"""
        event = {
            "type": event_type,
            "server_id": self.server_id,
            "clock": self.clock.get_time(),
            "data": event_data,
            "timestamp": time.time()
        }

        self._publish_message("replication", event)
        print(f"Evento replicado: {event_type} (clock={event['clock']})")

    def apply_event(self, event: Dict):
        """Aplica evento de replicação de forma idempotente"""
        event_key = (event["clock"], event["server_id"])

        # Verificar se já foi aplicado
        if event_key in self.applied_events:
            return  # Já aplicado, ignorar

        # Verificar se devemos aplicar (Lamport clock rule)
        if event["clock"] <= self.clock.get_time():
            return  # Evento muito antigo, ignorar

        event_type = event["type"]
        event_data = event["data"]

        try:
            if event_type == "user_login":
                # Aplicar login de usuário
                user = event_data["user"]
                if not self._user_exists(user):
                    self.users.append({
                        "name": user,
                        "login_timestamp": event_data["timestamp"]
                    })
                    self._save_json(self.users_file, self.users)
                    print(f"Usuário replicado: {user}")

            elif event_type == "channel_create":
                # Aplicar criação de canal
                channel = event_data["channel"]
                if not self._channel_exists(channel):
                    self.channels.append({
                        "name": channel,
                        "created_timestamp": event_data["timestamp"]
                    })
                    self._save_json(self.channels_file, self.channels)
                    print(f"Canal replicado: {channel}")

            elif event_type == "message_publish":
                # Aplicar publicação de mensagem
                self._persist_message(event_data, "publish")
                print(f"Mensagem replicada: {event_data['channel']}:{event_data['user']}")

            elif event_type == "message_send":
                # Aplicar envio de mensagem privada
                self._persist_message(event_data, "message")
                print(f"Mensagem privada replicada: {event_data['src']}->{event_data['dst']}")

            # Marcar como aplicado
            self.applied_events.add(event_key)

            # Atualizar relógio se necessário
            if event["clock"] > self.clock.get_time():
                self.clock.update(event["clock"])

        except Exception as e:
            print(f"Erro ao aplicar evento {event_type}: {e}")

    def replication_listener(self):
        """Ouve eventos de replicação"""
        while True:
            try:
                [topic, message_raw] = self.rep_socket.recv_multipart()
                message = serializer.deserialize(message_raw)

                # Aplicar evento se não for do próprio servidor
                if message.get("server_id") != self.server_id:
                    self.apply_event(message)

            except Exception as e:
                print(f"Erro no listener de replicação: {e}")
                time.sleep(1)

    def handle_login(self, data: Dict) -> Dict:
        """Processa login de usuário"""
        user = data.get("user", "").strip()
        timestamp = data.get("timestamp", time.time())

        if not user:
            clock = self.clock.tick()
            return {
                "service": "login",
                "data": {
                    "status": "erro",
                    "timestamp": timestamp,
                    "clock": clock,
                    "description": "Nome de usuário vazio"
                }
            }

        # Adicionar usuário se não existir
        if user not in self.users:
            self.users.append({
                "name": user,
                "login_timestamp": timestamp
            })
            self._save_json(self.users_file, self.users)

            # Publicar evento de replicação
            self.publish_event("user_login", {
                "user": user,
                "timestamp": timestamp
            })

        clock = self.clock.tick()
        return {
            "service": "login",
            "data": {
                "status": "sucesso",
                "timestamp": timestamp,
                "clock": clock
            }
        }

    def handle_users(self, data: Dict) -> Dict:
        """Lista usuários cadastrados"""
        timestamp = data.get("timestamp", time.time())
        user_names = [u["name"] for u in self.users]

        clock = self.clock.tick()
        return {
            "service": "users",
            "data": {
                "timestamp": timestamp,
                "clock": clock,
                "users": user_names
            }
        }

    def handle_channel(self, data: Dict) -> Dict:
        """Cria novo canal"""
        channel = data.get("channel", "").strip()
        timestamp = data.get("timestamp", time.time())

        if not channel:
            clock = self.clock.tick()
            return {
                "service": "channel",
                "data": {
                    "status": "erro",
                    "timestamp": timestamp,
                    "clock": clock,
                    "description": "Nome de canal vazio"
                }
            }

        # Adicionar canal se não existir
        if channel not in self.channels:
            self.channels.append({
                "name": channel,
                "created_timestamp": timestamp
            })
            self._save_json(self.channels_file, self.channels)

            # Publicar evento de replicação
            self.publish_event("channel_create", {
                "channel": channel,
                "timestamp": timestamp
            })

        clock = self.clock.tick()
        return {
            "service": "channel",
            "data": {
                "status": "sucesso",
                "timestamp": timestamp,
                "clock": clock
            }
        }

    def handle_channels(self, data: Dict) -> Dict:
        """Lista canais disponíveis"""
        timestamp = data.get("timestamp", time.time())
        channel_names = [c["name"] for c in self.channels]

        clock = self.clock.tick()
        return {
            "service": "channels",
            "data": {
                "timestamp": timestamp,
                "clock": clock,
                "channels": channel_names
            }
        }

    def handle_publish(self, data: Dict) -> Dict:
        """Processa publicação em canal"""
        user = data.get("user", "").strip()
        channel = data.get("channel", "").strip()
        message = data.get("message", "").strip()
        timestamp = data.get("timestamp", time.time())

        # Validações
        if not user or not channel or not message:
            clock = self.clock.tick()
            return {
                "service": "publish",
                "data": {
                    "status": "erro",
                    "timestamp": timestamp,
                    "clock": clock,
                    "message": "Usuário, canal e mensagem são obrigatórios"
                }
            }

        if not self._user_exists(user):
            clock = self.clock.tick()
            return {
                "service": "publish",
                "data": {
                    "status": "erro",
                    "timestamp": timestamp,
                    "clock": clock,
                    "message": f"Usuário '{user}' não encontrado"
                }
            }

        if not self._channel_exists(channel):
            clock = self.clock.tick()
            return {
                "service": "publish",
                "data": {
                    "status": "erro",
                    "timestamp": timestamp,
                    "clock": clock,
                    "message": f"Canal '{channel}' não encontrado"
                }
            }

        # Tick do relógio antes de publicar
        clock = self.clock.tick()

        # Criar dados da mensagem
        message_data = {
            "user": user,
            "channel": channel,
            "message": message,
            "timestamp": timestamp,
            "clock": clock,
            "type": "publish"
        }

        # Persistir
        self._persist_message(message_data, "publish")

        # Publicar para usuários
        self._publish_message(channel, {
            "user": user,
            "message": message,
            "timestamp": timestamp,
            "clock": clock
        })

        # Publicar evento de replicação
        self.publish_event("message_publish", message_data)

        # Verificar sincronização Berkeley
        self.check_berkeley_sync()

        return {
            "service": "publish",
            "data": {
                "status": "OK",
                "timestamp": timestamp,
                "clock": clock
            }
        }

    def handle_message(self, data: Dict) -> Dict:
        """Processa envio de mensagem privada"""
        src = data.get("src", "").strip()
        dst = data.get("dst", "").strip()
        message = data.get("message", "").strip()
        timestamp = data.get("timestamp", time.time())

        # Validações
        if not src or not dst or not message:
            clock = self.clock.tick()
            return {
                "service": "message",
                "data": {
                    "status": "erro",
                    "timestamp": timestamp,
                    "clock": clock,
                    "message": "Remetente, destinatário e mensagem são obrigatórios"
                }
            }

        if not self._user_exists(src):
            clock = self.clock.tick()
            return {
                "service": "message",
                "data": {
                    "status": "erro",
                    "timestamp": timestamp,
                    "clock": clock,
                    "message": f"Remetente '{src}' não encontrado"
                }
            }

        if not self._user_exists(dst):
            clock = self.clock.tick()
            return {
                "service": "message",
                "data": {
                    "status": "erro",
                    "timestamp": timestamp,
                    "clock": clock,
                    "message": f"Destinatário '{dst}' não encontrado"
                }
            }

        # Tick do relógio antes de enviar
        clock = self.clock.tick()

        # Criar dados da mensagem
        message_data = {
            "src": src,
            "dst": dst,
            "message": message,
            "timestamp": timestamp,
            "clock": clock,
            "type": "message"
        }

        # Persistir
        self._persist_message(message_data, "message")

        # Publicar para o destinatário
        self._publish_message(dst, {
            "src": src,
            "message": message,
            "timestamp": timestamp,
            "clock": clock
        })

        # Publicar evento de replicação
        self.publish_event("message_send", message_data)

        # Verificar sincronização Berkeley
        self.check_berkeley_sync()

        return {
            "service": "message",
            "data": {
                "status": "OK",
                "timestamp": timestamp,
                "clock": clock
            }
        }

    def process_request(self, request: Dict) -> Dict:
        """Processa requisição e retorna resposta"""
        service = request.get("service")
        data = request.get("data", {})

        if service == "login":
            return self.handle_login(data)
        elif service == "users":
            return self.handle_users(data)
        elif service == "channel":
            return self.handle_channel(data)
        elif service == "channels":
            return self.handle_channels(data)
        elif service == "publish":
            return self.handle_publish(data)
        elif service == "message":
            return self.handle_message(data)
        else:
            # Serviço desconhecido
            timestamp = data.get("timestamp", time.time())
            clock = self.clock.tick()
            return {
                "service": service or "unknown",
                "data": {
                    "status": "erro",
                    "timestamp": timestamp,
                    "clock": clock,
                    "description": f"Serviço '{service}' não suportado"
                }
            }

    def run(self):
        """Loop principal do servidor"""
        print(f"Servidor iniciado (SERDE={serializer.format}). Aguardando conexões...")
        try:
            while True:
                # Receber mensagem
                raw_message = self.socket.recv()
                message = serializer.deserialize(raw_message)

                # Atualizar relógio ao receber mensagem
                if 'clock' in message.get('data', {}):
                    self.clock.update(message['data']['clock'])

                print(f"Recebido (clock={self.clock.get_time()}): {message}")

                # Processar
                response = self.process_request(message)
                print(f"Enviando (clock={self.clock.get_time()}): {response}")

                # Verificar sincronização Berkeley
                self.check_berkeley_sync()

                # Enviar resposta
                self.socket.send(serializer.serialize(response))

        except KeyboardInterrupt:
            print("Servidor interrompido.")
        finally:
            self.socket.close()
            self.pub_socket.close()
            self.ref_socket.close()
            self.rep_socket.close()
            self.context.term()

if __name__ == "__main__":
    server_name = os.getenv("SERVER_NAME")
    server = Server(server_name)
    server.run()
