import zmq from 'zeromq';
import msgpack from 'msgpack-lite';

const reqSocket = new zmq.Request();
await reqSocket.connect('tcp://broker:5555');

const subSocket = new zmq.Subscriber();
await subSocket.connect('tcp://proxy:5558');

console.log('Cliente JS iniciado e conectado ao broker e proxy');

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
const username = process.env.USERNAME || `user_js_${Date.now()}`;
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

if (response.data?.status === 'sucesso') {
  console.log(`Login bem-sucedido como ${username}`);
  await subSocket.subscribe(username);
} else {
  console.error(`Erro no login: ${response.data?.description}`);
  process.exit(1);
}

// Receber mensagens
(async () => {
  for await (const [topic, msgBuf] of subSocket) {
    try {
      const msg = msgpack.decode(msgBuf);
      updateClock(msg.data?.clock || 0);
      const service = msg.service;
      const data = msg.data || {};
      
      if (service === 'message') {
        console.log(`\n[MENSAGEM de ${data.src}]: ${data.message}`);
      } else if (service === 'publish') {
        console.log(`\n[CANAL ${data.channel} - ${data.user}]: ${data.message}`);
      }
    } catch (e) {
      console.error('Erro ao receber mensagem:', e);
    }
  }
})();

// Criar um canal de teste
console.log('Criando canal de teste...');
const channelMsg = msgpack.encode({
  service: 'channel',
  data: {
    channel: 'teste_js',
    timestamp: Date.now() / 1000,
    clock: incrementClock()
  }
});
await reqSocket.send(channelMsg);
const [channelResp] = await reqSocket.receive();
updateClock(msgpack.decode(channelResp).data?.clock || 0);
console.log('Canal criado');

// Inscrever no canal
await subSocket.subscribe('teste_js');

// Loop de teste publicando mensagens
setInterval(async () => {
  try {
    const testMsg = msgpack.encode({
      service: 'publish',
      data: {
        user: username,
        channel: 'teste_js',
        message: `Mensagem de teste do cliente JS ${Date.now()}`,
        timestamp: Date.now() / 1000,
        clock: incrementClock()
      }
    });
    await reqSocket.send(testMsg);
    const [testResp] = await reqSocket.receive();
    updateClock(msgpack.decode(testResp).data?.clock || 0);
  } catch (e) {
    console.error('Erro ao publicar:', e);
  }
}, 30000);

// Manter o processo ativo
process.on('SIGINT', () => {
  console.log('\nSaindo...');
  process.exit(0);
});

