import zmq from 'zeromq';
import msgpack from 'msgpack-lite';

const reqSocket = new zmq.Request();
await reqSocket.connect('tcp://broker:5555');

const subSocket = new zmq.Subscriber();
await subSocket.connect('tcp://proxy:5558');

console.log('Bot JS iniciado e conectado ao broker e proxy');

// Relógio lógico
let logicalClock = 0;

function incrementClock() {
  return ++logicalClock;
}

function updateClock(receivedClock) {
  logicalClock = Math.max(logicalClock, receivedClock) + 1;
  return logicalClock;
}

// Login
const username = `bot_js_${Math.floor(Math.random() * 10000)}`;
console.log(`Tentando login como: ${username}`);

const loginMsg = msgpack.encode({
  service: 'login',
  data: {
    user: username,
    timestamp: Date.now() / 1000,
    clock: incrementClock()
  }
});

await reqSocket.send(loginMsg);
const [responseBuf] = await reqSocket.receive();
const response = msgpack.decode(responseBuf);
updateClock(response.data?.clock || 0);
console.log('Resposta do login:', response);

if (response.data?.status !== 'sucesso') {
  console.error(`Erro no login: ${response.data?.description}`);
  process.exit(1);
}

console.log(`Login bem-sucedido como ${username}`);
await subSocket.subscribe(username);

const messages = [
  'Olá do bot JS!',
  'Como estão?',
  'Bot JavaScript ativo',
  'Teste de mensagem',
  'Sistema operacional',
  'Dados sincronizados',
  'Status: OK',
  'Tudo funcionando',
  'Mensagem automática',
  'Bot reportando presença'
];

// Loop principal do bot
while (true) {
  try {
    // Obter lista de canais
    const channelsMsg = msgpack.encode({
      service: 'channels',
      data: {
        timestamp: Date.now() / 1000,
        clock: incrementClock()
      }
    });
    
    await reqSocket.send(channelsMsg);
    const [channelsResp] = await reqSocket.receive();
    const channelsData = msgpack.decode(channelsResp);
    updateClock(channelsData.data?.clock || 0);
    const channels = channelsData.data?.channels || [];
    
    if (channels.length === 0) {
      console.log('Nenhum canal disponível, esperando 5 segundos...');
      await new Promise(resolve => setTimeout(resolve, 5000));
      continue;
    }
    
    // Escolher canal aleatório
    const channel = channels[Math.floor(Math.random() * channels.length)];
    console.log(`\nEnviando mensagens para o canal: ${channel}`);
    
    // Enviar 10 mensagens
    for (let i = 0; i < 10; i++) {
      const message = messages[Math.floor(Math.random() * messages.length)];
      const pubMsg = msgpack.encode({
        service: 'publish',
        data: {
          user: username,
          channel: channel,
          message: `${message} (msg ${i+1}/10)`,
          timestamp: Date.now() / 1000,
          clock: incrementClock()
        }
      });
      
      await reqSocket.send(pubMsg);
      const [pubResp] = await reqSocket.receive();
      const pubData = msgpack.decode(pubResp);
      updateClock(pubData.data?.clock || 0);
      
      if (pubData.data?.status === 'OK') {
        console.log(`Mensagem ${i+1}/10 publicada: ${message}`);
      } else {
        console.log(`Erro ao publicar mensagem: ${pubData.data?.message}`);
      }
      
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    console.log('Ciclo completo, aguardando 5 segundos antes do próximo...');
    await new Promise(resolve => setTimeout(resolve, 5000));
    
  } catch (e) {
    console.error('Erro no bot:', e);
    await new Promise(resolve => setTimeout(resolve, 5000));
  }
}

