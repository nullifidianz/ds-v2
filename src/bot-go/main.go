package main

import (
	"fmt"
	"log"
	"math/rand"
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
	rand.Seed(time.Now().UnixNano())
	
	context, _ := zmq4.NewContext()
	defer context.Term()
	
	reqSocket, _ := context.NewSocket(zmq4.REQ)
	defer reqSocket.Close()
	reqSocket.Connect("tcp://broker:5555")
	
	subSocket, _ := context.NewSocket(zmq4.SUB)
	defer subSocket.Close()
	subSocket.Connect("tcp://proxy:5558")
	
	log.Println("Bot Go iniciado e conectado ao broker e proxy")
	
	// Login
	username := fmt.Sprintf("bot_go_%d", rand.Intn(10000))
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
	
	if status, ok := response.Data["status"].(string); !ok || status != "sucesso" {
		log.Fatalf("Erro no login")
	}
	
	log.Printf("Login bem-sucedido como %s\n", username)
	subSocket.SetSubscribe(username)
	
	messages := []string{
		"Olá do bot Go!",
		"Bot Go ativo",
		"Mensagem automática Go",
		"Sistema Go funcionando",
		"Teste de Go",
		"Bot em Go reportando",
		"Status Go: OK",
		"Go é rápido!",
		"Bot Go presente",
		"Golang em ação!",
	}
	
	// Loop principal
	for {
		time.Sleep(5 * time.Second)
		
		// Obter canais
		channelsMsg := Message{
			Service: "channels",
			Data: map[string]interface{}{
				"timestamp": float64(time.Now().Unix()),
				"clock":     incrementClock(),
			},
		}
		channelsData, _ := msgpack.Marshal(channelsMsg)
		reqSocket.SendBytes(channelsData, 0)
		channelsResp, _ := reqSocket.RecvBytes(0)
		var channelsData2 Message
		msgpack.Unmarshal(channelsResp, &channelsData2)
		
		if clock, ok := channelsData2.Data["clock"].(int); ok {
			updateClock(clock)
		}
		
		channels, ok := channelsData2.Data["channels"].([]interface{})
		if !ok || len(channels) == 0 {
			log.Println("Nenhum canal disponível, esperando 5 segundos...")
			continue
		}
		
		// Escolher canal aleatório
		channel := channels[rand.Intn(len(channels))].(string)
		log.Printf("\nEnviando mensagens para o canal: %s\n", channel)
		
		// Enviar 10 mensagens
		for i := 0; i < 10; i++ {
			message := messages[rand.Intn(len(messages))]
			pubMsg := Message{
				Service: "publish",
				Data: map[string]interface{}{
					"user":      username,
					"channel":   channel,
					"message":   fmt.Sprintf("%s (msg %d/10)", message, i+1),
					"timestamp": float64(time.Now().Unix()),
					"clock":     incrementClock(),
				},
			}
			pubData, _ := msgpack.Marshal(pubMsg)
			reqSocket.SendBytes(pubData, 0)
			pubResp, _ := reqSocket.RecvBytes(0)
			var pubRespData Message
			msgpack.Unmarshal(pubResp, &pubRespData)
			
			if clock, ok := pubRespData.Data["clock"].(int); ok {
				updateClock(clock)
			}
			
			if status, ok := pubRespData.Data["status"].(string); ok && status == "OK" {
				log.Printf("Mensagem %d/10 publicada: %s\n", i+1, message)
			} else {
				log.Printf("Erro ao publicar mensagem %d/10\n", i+1)
			}
			
			time.Sleep(1 * time.Second)
		}
		
		log.Println("Ciclo completo, aguardando 5 segundos...")
	}
}

