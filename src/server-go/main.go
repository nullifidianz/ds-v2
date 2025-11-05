package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/pebbe/zmq4"
	"github.com/vmihailenco/msgpack/v5"
)

const dataDir = "/data"

var (
	users        []string
	channels     []string
	logins       []map[string]interface{}
	messages     []map[string]interface{}
	publications []map[string]interface{}
	
	logicalClock int
	serverName   string
	serverRank   int
	coordinator  string
	messageCounter int
)

type Message struct {
	Service string                 `msgpack:"service"`
	Data    map[string]interface{} `msgpack:"data"`
}

func incrementClock() int {
	logicalClock++
	return logicalClock
}

func updateClock(receivedClock int) int {
	if receivedClock > logicalClock {
		logicalClock = receivedClock
	}
	logicalClock++
	return logicalClock
}

func loadJSON(filename string, v interface{}) error {
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, v)
}

func saveJSON(filename string, v interface{}) error {
	data, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filename, data, 0644)
}

func main() {
	// Criar diretório de dados
	os.MkdirAll(dataDir, 0755)
	
	// Carregar dados existentes
	loadJSON(dataDir+"/users_go.json", &users)
	loadJSON(dataDir+"/channels_go.json", &channels)
	loadJSON(dataDir+"/logins_go.json", &logins)
	loadJSON(dataDir+"/messages_go.json", &messages)
	loadJSON(dataDir+"/publications_go.json", &publications)
	
	// Configurar sockets ZeroMQ
	context, _ := zmq4.NewContext()
	defer context.Term()
	
	repSocket, _ := context.NewSocket(zmq4.REP)
	defer repSocket.Close()
	repSocket.Connect("tcp://broker:5556")
	
	pubSocket, _ := context.NewSocket(zmq4.PUB)
	defer pubSocket.Close()
	pubSocket.Connect("tcp://proxy:5557")
	
	refSocket, _ := context.NewSocket(zmq4.REQ)
	defer refSocket.Close()
	refSocket.Connect("tcp://reference:5559")
	
	subSocket, _ := context.NewSocket(zmq4.SUB)
	defer subSocket.Close()
	subSocket.Connect("tcp://proxy:5558")
	subSocket.SetSubscribe("servers")
	subSocket.SetSubscribe("replication")
	
	log.Println("Servidor Go iniciado e conectado ao broker, proxy e referência")
	
	// Obter rank do servidor de referência
	hostname, _ := os.Hostname()
	serverName = fmt.Sprintf("%s_go_%s", os.Getenv("SERVER_NAME"), hostname)
	
	rankMsg := Message{
		Service: "rank",
		Data: map[string]interface{}{
			"user":      serverName,
			"timestamp": float64(time.Now().Unix()),
			"clock":     incrementClock(),
		},
	}
	rankData, _ := msgpack.Marshal(rankMsg)
	refSocket.SendBytes(rankData, 0)
	rankRespData, _ := refSocket.RecvBytes(0)
	var rankResp Message
	msgpack.Unmarshal(rankRespData, &rankResp)
	if clock, ok := rankResp.Data["clock"].(int); ok {
		updateClock(clock)
	}
	if rank, ok := rankResp.Data["rank"].(int); ok {
		serverRank = rank
	}
	log.Printf("Servidor %s registrado com rank %d\n", serverName, serverRank)
	
	// Heartbeat goroutine
	go func() {
		for {
			time.Sleep(10 * time.Second)
			hbMsg := Message{
				Service: "heartbeat",
				Data: map[string]interface{}{
					"user":      serverName,
					"timestamp": float64(time.Now().Unix()),
					"clock":     incrementClock(),
				},
			}
			hbData, _ := msgpack.Marshal(hbMsg)
			refSocket.SendBytes(hbData, 0)
			refSocket.RecvBytes(0)
		}
	}()
	
	// Sincronização de dados goroutine
	go func() {
		for {
			time.Sleep(30 * time.Second)
			replData := Message{
				Service: "replication",
				Data: map[string]interface{}{
					"server":    serverName,
					"users":     users,
					"channels":  channels,
					"timestamp": float64(time.Now().Unix()),
					"clock":     incrementClock(),
				},
			}
			replBytes, _ := msgpack.Marshal(replData)
			pubSocket.Send("replication", zmq4.SNDMORE)
			pubSocket.SendBytes(replBytes, 0)
			log.Println("Dados de replicação publicados")
		}
	}()
	
	// Receber replicação e eleições goroutine
	go func() {
		for {
			topic, _ := subSocket.Recv(0)
			msgData, _ := subSocket.RecvBytes(0)
			var msg Message
			msgpack.Unmarshal(msgData, &msg)
			
			if msg.Service == "election" {
				if coord, ok := msg.Data["coordinator"].(string); ok {
					coordinator = coord
					log.Printf("Novo coordenador eleito: %s\n", coordinator)
				}
			} else if msg.Service == "replication" && topic == "replication" {
				if remoteServer, ok := msg.Data["server"].(string); ok && remoteServer != serverName {
					if remoteUsers, ok := msg.Data["users"].([]interface{}); ok {
						for _, u := range remoteUsers {
							if user, ok := u.(string); ok {
								found := false
								for _, eu := range users {
									if eu == user {
										found = true
										break
									}
								}
								if !found {
									users = append(users, user)
									log.Printf("Usuário replicado de %s: %s\n", remoteServer, user)
								}
							}
						}
					}
					if remoteChannels, ok := msg.Data["channels"].([]interface{}); ok {
						for _, c := range remoteChannels {
							if channel, ok := c.(string); ok {
								found := false
								for _, ec := range channels {
									if ec == channel {
										found = true
										break
									}
								}
								if !found {
									channels = append(channels, channel)
									log.Printf("Canal replicado de %s: %s\n", remoteServer, channel)
								}
							}
						}
					}
					saveJSON(dataDir+"/users_go.json", users)
					saveJSON(dataDir+"/channels_go.json", channels)
				}
			}
		}
	}()
	
	// Loop principal do servidor
	for {
		msgData, _ := repSocket.RecvBytes(0)
		var msg Message
		msgpack.Unmarshal(msgData, &msg)
		log.Printf("Mensagem recebida: %+v\n", msg)
		
		if clock, ok := msg.Data["clock"].(int); ok {
			updateClock(clock)
		}
		
		messageCounter++
		if messageCounter >= 10 && coordinator != "" {
			messageCounter = 0
			log.Printf("Sincronizando relógio com coordenador %s\n", coordinator)
		}
		
		var response Message
		
		switch msg.Service {
		case "login":
			user := msg.Data["user"].(string)
			if user == "" {
				response = Message{
					Service: "login",
					Data: map[string]interface{}{
						"status":      "erro",
						"timestamp":   float64(time.Now().Unix()),
						"clock":       incrementClock(),
						"description": "Nome de usuário não fornecido",
					},
				}
			} else {
				found := false
				for _, u := range users {
					if u == user {
						found = true
						break
					}
				}
				if found {
					response = Message{
						Service: "login",
						Data: map[string]interface{}{
							"status":      "erro",
							"timestamp":   float64(time.Now().Unix()),
							"clock":       incrementClock(),
							"description": "Usuário já existe",
						},
					}
				} else {
					users = append(users, user)
					logins = append(logins, map[string]interface{}{
						"user":      user,
						"timestamp": msg.Data["timestamp"],
					})
					saveJSON(dataDir+"/users_go.json", users)
					saveJSON(dataDir+"/logins_go.json", logins)
					response = Message{
						Service: "login",
						Data: map[string]interface{}{
							"status":    "sucesso",
							"timestamp": float64(time.Now().Unix()),
							"clock":     incrementClock(),
						},
					}
				}
			}
			
		case "users":
			response = Message{
				Service: "users",
				Data: map[string]interface{}{
					"timestamp": float64(time.Now().Unix()),
					"clock":     incrementClock(),
					"users":     users,
				},
			}
			
		case "channel":
			channel := msg.Data["channel"].(string)
			found := false
			for _, c := range channels {
				if c == channel {
					found = true
					break
				}
			}
			if found {
				response = Message{
					Service: "channel",
					Data: map[string]interface{}{
						"status":      "erro",
						"timestamp":   float64(time.Now().Unix()),
						"clock":       incrementClock(),
						"description": "Canal já existe",
					},
				}
			} else {
				channels = append(channels, channel)
				saveJSON(dataDir+"/channels_go.json", channels)
				response = Message{
					Service: "channel",
					Data: map[string]interface{}{
						"status":    "sucesso",
						"timestamp": float64(time.Now().Unix()),
						"clock":     incrementClock(),
					},
				}
			}
			
		case "channels":
			response = Message{
				Service: "channels",
				Data: map[string]interface{}{
					"timestamp": float64(time.Now().Unix()),
					"clock":     incrementClock(),
					"channels":  channels,
				},
			}
			
		case "publish":
			user := msg.Data["user"].(string)
			channel := msg.Data["channel"].(string)
			message := msg.Data["message"].(string)
			timestamp := msg.Data["timestamp"]
			
			found := false
			for _, c := range channels {
				if c == channel {
					found = true
					break
				}
			}
			
			if !found {
				response = Message{
					Service: "publish",
					Data: map[string]interface{}{
						"status":    "erro",
						"message":   "Canal não existe",
						"timestamp": float64(time.Now().Unix()),
						"clock":     incrementClock(),
					},
				}
			} else {
				pubMsg := Message{
					Service: "publish",
					Data: map[string]interface{}{
						"user":      user,
						"channel":   channel,
						"message":   message,
						"timestamp": timestamp,
						"clock":     incrementClock(),
					},
				}
				pubData, _ := msgpack.Marshal(pubMsg)
				pubSocket.Send(channel, zmq4.SNDMORE)
				pubSocket.SendBytes(pubData, 0)
				
				publications = append(publications, map[string]interface{}{
					"user":      user,
					"channel":   channel,
					"message":   message,
					"timestamp": timestamp,
				})
				saveJSON(dataDir+"/publications_go.json", publications)
				
				response = Message{
					Service: "publish",
					Data: map[string]interface{}{
						"status":    "OK",
						"timestamp": float64(time.Now().Unix()),
						"clock":     incrementClock(),
					},
				}
			}
			
		case "message":
			src := msg.Data["src"].(string)
			dst := msg.Data["dst"].(string)
			message := msg.Data["message"].(string)
			timestamp := msg.Data["timestamp"]
			
			found := false
			for _, u := range users {
				if u == dst {
					found = true
					break
				}
			}
			
			if !found {
				response = Message{
					Service: "message",
					Data: map[string]interface{}{
						"status":    "erro",
						"message":   "Usuário não existe",
						"timestamp": float64(time.Now().Unix()),
						"clock":     incrementClock(),
					},
				}
			} else {
				pubMsg := Message{
					Service: "message",
					Data: map[string]interface{}{
						"src":       src,
						"dst":       dst,
						"message":   message,
						"timestamp": timestamp,
						"clock":     incrementClock(),
					},
				}
				pubData, _ := msgpack.Marshal(pubMsg)
				pubSocket.Send(dst, zmq4.SNDMORE)
				pubSocket.SendBytes(pubData, 0)
				
				messages = append(messages, map[string]interface{}{
					"src":       src,
					"dst":       dst,
					"message":   message,
					"timestamp": timestamp,
				})
				saveJSON(dataDir+"/messages_go.json", messages)
				
				response = Message{
					Service: "message",
					Data: map[string]interface{}{
						"status":    "OK",
						"timestamp": float64(time.Now().Unix()),
						"clock":     incrementClock(),
					},
				}
			}
			
		default:
			response = Message{
				Service: msg.Service,
				Data: map[string]interface{}{
					"status":      "erro",
					"timestamp":   float64(time.Now().Unix()),
					"clock":       incrementClock(),
					"description": "Serviço não reconhecido",
				},
			}
		}
		
		respData, _ := msgpack.Marshal(response)
		repSocket.SendBytes(respData, 0)
		log.Printf("Resposta enviada: %+v\n", response)
	}
}

