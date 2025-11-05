package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/pebbe/zmq4"
	"github.com/vmihailenco/msgpack/v5"
)

var logicalClock int

type Message struct {
	Service string                 `msgpack:"service"`
	Data    map[string]interface{} `msgpack:"data"`
}

func incrementClock() int {
	logicalClock++
	return logicalClock
}

func updateClock(receivedClock int) {
	if receivedClock > logicalClock {
		logicalClock = receivedClock
	}
	logicalClock++
}

func main() {
	context, _ := zmq4.NewContext()
	defer context.Term()
	
	reqSocket, _ := context.NewSocket(zmq4.REQ)
	defer reqSocket.Close()
	reqSocket.Connect("tcp://broker:5555")
	
	subSocket, _ := context.NewSocket(zmq4.SUB)
	defer subSocket.Close()
	subSocket.Connect("tcp://proxy:5558")
	
	log.Println("Cliente Go iniciado e conectado ao broker e proxy")
	
	// Login
	username := os.Getenv("USERNAME")
	if username == "" {
		username = fmt.Sprintf("user_go_%d", time.Now().Unix())
	}
	log.Printf("Tentando login como: %s\n", username)
	
	loginMsg := Message{
		Service: "login",
		Data: map[string]interface{}{
			"user":      username,
			"timestamp": float64(time.Now().Unix()),
			"clock":     incrementClock(),
		},
	}
	loginData, _ := msgpack.Marshal(loginMsg)
	reqSocket.SendBytes(loginData, 0)
	respData, _ := reqSocket.RecvBytes(0)
	var response Message
	msgpack.Unmarshal(respData, &response)
	if clock, ok := response.Data["clock"].(int); ok {
		updateClock(clock)
	}
	log.Printf("Resposta do login: %+v\n", response)
	
	if status, ok := response.Data["status"].(string); !ok || status != "sucesso" {
		log.Fatalf("Erro no login: %v\n", response.Data["description"])
	}
	
	log.Printf("Login bem-sucedido como %s\n", username)
	subSocket.SetSubscribe(username)
	
	// Receber mensagens
	go func() {
		for {
			topic, _ := subSocket.Recv(0)
			msgData, _ := subSocket.RecvBytes(0)
			var msg Message
			msgpack.Unmarshal(msgData, &msg)
			if clock, ok := msg.Data["clock"].(int); ok {
				updateClock(clock)
			}
			
			if msg.Service == "message" {
				fmt.Printf("\n[MENSAGEM de %v]: %v\n", msg.Data["src"], msg.Data["message"])
			} else if msg.Service == "publish" {
				fmt.Printf("\n[CANAL %v - %v]: %v\n", msg.Data["channel"], msg.Data["user"], msg.Data["message"])
			}
			_ = topic
		}
	}()
	
	// Criar canal de teste
	log.Println("Criando canal de teste...")
	channelMsg := Message{
		Service: "channel",
		Data: map[string]interface{}{
			"channel":   "teste_go",
			"timestamp": float64(time.Now().Unix()),
			"clock":     incrementClock(),
		},
	}
	channelData, _ := msgpack.Marshal(channelMsg)
	reqSocket.SendBytes(channelData, 0)
	reqSocket.RecvBytes(0)
	log.Println("Canal criado")
	
	// Inscrever no canal
	subSocket.SetSubscribe("teste_go")
	
	// Loop de teste
	for {
		time.Sleep(30 * time.Second)
		testMsg := Message{
			Service: "publish",
			Data: map[string]interface{}{
				"user":      username,
				"channel":   "teste_go",
				"message":   fmt.Sprintf("Mensagem de teste do cliente Go %d", time.Now().Unix()),
				"timestamp": float64(time.Now().Unix()),
				"clock":     incrementClock(),
			},
		}
		testData, _ := msgpack.Marshal(testMsg)
		reqSocket.SendBytes(testData, 0)
		reqSocket.RecvBytes(0)
	}
}

