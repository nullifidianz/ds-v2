package main

import (
	"fmt"
	"log"
	"os"
	"sort"
	"sync"
	"time"

	"github.com/pebbe/zmq4"
	"github.com/vmihailenco/msgpack/v5"
)

// LamportClock implements Lamport logical clock
type LamportClock struct {
	time int
	mu   sync.Mutex
}

func (c *LamportClock) Tick() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.time++
	return c.time
}

func (c *LamportClock) Update(receivedTime int) int {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.time = max(c.time, receivedTime) + 1
	return c.time
}

func (c *LamportClock) GetTime() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.time
}

// ServerInfo represents a server in the system
type ServerInfo struct {
	Name    string    `json:"name"`
	Rank    int       `json:"rank"`
	LastSeen time.Time `json:"last_seen"`
}

// ReferenceServer manages server ranks and heartbeats
type ReferenceServer struct {
	socket       *zmq4.Socket
	clock        *LamportClock
	servers      map[string]*ServerInfo
	nextRank     int
	serversMutex sync.RWMutex
	serdeFormat  string
}

func NewReferenceServer() *ReferenceServer {
	context, _ := zmq4.NewContext()
	socket, _ := context.NewSocket(zmq4.REP)
	socket.Bind("tcp://*:5559")

	serdeFormat := os.Getenv("SERDE")
	if serdeFormat == "" {
		serdeFormat = "JSON"
	}

	return &ReferenceServer{
		socket:      socket,
		clock:       &LamportClock{},
		servers:     make(map[string]*ServerInfo),
		nextRank:    1,
		serdeFormat: serdeFormat,
	}
}

func (rs *ReferenceServer) serialize(data interface{}) ([]byte, error) {
	if rs.serdeFormat == "MSGPACK" {
		return msgpack.Marshal(data)
	}
	// Simple JSON implementation
	jsonStr := fmt.Sprintf("%v", data)
	return []byte(jsonStr), nil
}

func (rs *ReferenceServer) deserialize(data []byte, v interface{}) error {
	if rs.serdeFormat == "MSGPACK" {
		return msgpack.Unmarshal(data, v)
	}
	// Simple JSON implementation - would need proper JSON unmarshaling
	return nil
}

type Request struct {
	Service string                 `msgpack:"service"`
	Data    map[string]interface{} `msgpack:"data"`
}

type Response struct {
	Service string                 `msgpack:"service"`
	Data    map[string]interface{} `msgpack:"data"`
}

func (rs *ReferenceServer) handleRank(data map[string]interface{}) Response {
	user, ok := data["user"].(string)
	if !ok || user == "" {
		clock := rs.clock.Tick()
		return Response{
			Service: "rank",
			Data: map[string]interface{}{
				"status":     "error",
				"message":    "Nome do servidor obrigatório",
				"timestamp":  time.Now().Unix(),
				"clock":      clock,
			},
		}
	}

	rs.serversMutex.Lock()
	defer rs.serversMutex.Unlock()

	// Check if server already exists
	if server, exists := rs.servers[user]; exists {
		server.LastSeen = time.Now()
		clock := rs.clock.Tick()
		return Response{
			Service: "rank",
			Data: map[string]interface{}{
				"rank":      server.Rank,
				"timestamp": time.Now().Unix(),
				"clock":     clock,
			},
		}
	}

	// Register new server
	rank := rs.nextRank
	rs.nextRank++
	rs.servers[user] = &ServerInfo{
		Name:     user,
		Rank:     rank,
		LastSeen: time.Now(),
	}

	clock := rs.clock.Tick()
	log.Printf("Servidor %s registrado com rank %d", user, rank)

	return Response{
		Service: "rank",
		Data: map[string]interface{}{
			"rank":      rank,
			"timestamp": time.Now().Unix(),
			"clock":     clock,
		},
	}
}

func (rs *ReferenceServer) handleList(data map[string]interface{}) Response {
	rs.serversMutex.RLock()
	defer rs.serversMutex.RUnlock()

	// Clean up old servers (no heartbeat for more than 30 seconds)
	now := time.Now()
	activeServers := make([]map[string]interface{}, 0)

	for _, server := range rs.servers {
		if now.Sub(server.LastSeen) < 30*time.Second {
			activeServers = append(activeServers, map[string]interface{}{
				"name": server.Name,
				"rank": server.Rank,
			})
		}
	}

	// Sort by rank
	sort.Slice(activeServers, func(i, j int) bool {
		return activeServers[i]["rank"].(int) < activeServers[j]["rank"].(int)
	})

	clock := rs.clock.Tick()
	return Response{
		Service: "list",
		Data: map[string]interface{}{
			"list":      activeServers,
			"timestamp": time.Now().Unix(),
			"clock":     clock,
		},
	}
}

func (rs *ReferenceServer) handleHeartbeat(data map[string]interface{}) Response {
	user, ok := data["user"].(string)
	if !ok || user == "" {
		clock := rs.clock.Tick()
		return Response{
			Service: "heartbeat",
			Data: map[string]interface{}{
				"status":    "error",
				"message":   "Nome do servidor obrigatório",
				"timestamp": time.Now().Unix(),
				"clock":     clock,
			},
		}
	}

	rs.serversMutex.Lock()
	defer rs.serversMutex.Unlock()

	if server, exists := rs.servers[user]; exists {
		server.LastSeen = time.Now()
		clock := rs.clock.Tick()
		return Response{
			Service: "heartbeat",
			Data: map[string]interface{}{
				"status":    "OK",
				"timestamp": time.Now().Unix(),
				"clock":     clock,
			},
		}
	}

	clock := rs.clock.Tick()
	return Response{
		Service: "heartbeat",
		Data: map[string]interface{}{
			"status":    "error",
			"message":   "Servidor não registrado",
			"timestamp": time.Now().Unix(),
			"clock":     clock,
		},
	}
}

func (rs *ReferenceServer) processRequest(request Request) Response {
	// Update clock if received
	if clockVal, ok := request.Data["clock"]; ok {
		if clockInt, ok := clockVal.(int); ok {
			rs.clock.Update(clockInt)
		}
	}

	switch request.Service {
	case "rank":
		return rs.handleRank(request.Data)
	case "list":
		return rs.handleList(request.Data)
	case "heartbeat":
		return rs.handleHeartbeat(request.Data)
	default:
		clock := rs.clock.Tick()
		return Response{
			Service: request.Service,
			Data: map[string]interface{}{
				"status":    "error",
				"message":   fmt.Sprintf("Serviço '%s' não suportado", request.Service),
				"timestamp": time.Now().Unix(),
				"clock":     clock,
			},
		}
	}
}

func (rs *ReferenceServer) run() {
	log.Printf("Servidor de referência iniciado (SERDE=%s). Aguardando conexões...", rs.serdeFormat)

	for {
		msg, err := rs.socket.RecvBytes(0)
		if err != nil {
			log.Printf("Erro ao receber mensagem: %v", err)
			continue
		}

		var request Request
		if err := rs.deserialize(msg, &request); err != nil {
			log.Printf("Erro ao desserializar: %v", err)
			continue
		}

		log.Printf("Recebido (clock=%d): %+v", rs.clock.GetTime(), request)

		response := rs.processRequest(request)

		log.Printf("Enviando (clock=%d): %+v", rs.clock.GetTime(), response)

		responseBytes, err := rs.serialize(response)
		if err != nil {
			log.Printf("Erro ao serializar resposta: %v", err)
			continue
		}

		if _, err := rs.socket.SendBytes(responseBytes, 0); err != nil {
			log.Printf("Erro ao enviar resposta: %v", err)
		}
	}
}

func main() {
	server := NewReferenceServer()
	server.run()
}
