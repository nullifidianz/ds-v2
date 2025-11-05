import zmq from 'zeromq';
import msgpack from 'msgpack-lite';
import fs from 'fs/promises';
import { hostname } from 'os';

// Configuração de diretório de dados
const DATA_DIR = '/data';
const USERS_FILE = `${DATA_DIR}/users_js.json`;
const CHANNELS_FILE = `${DATA_DIR}/channels_js.json`;
const LOGINS_FILE = `${DATA_DIR}/logins_js.json`;
const MESSAGES_FILE = `${DATA_DIR}/messages_js.json`;
const PUBLICATIONS_FILE = `${DATA_DIR}/publications_js.json`;

// Criar diretório de dados
await fs.mkdir(DATA_DIR, { recursive: true });

// Funções de persistência
async function loadJson(filepath, defaultValue = []) {
  try {
    const data = await fs.readFile(filepath, 'utf-8');
    return JSON.parse(data);
  } catch {
    return defaultValue;
  }
}

async function saveJson(filepath, data) {
  await fs.writeFile(filepath, JSON.stringify(data, null, 2));
}

// Carregar dados existentes
let users = await loadJson(USERS_FILE);
let channels = await loadJson(CHANNELS_FILE);
let logins = await loadJson(LOGINS_FILE);
let messages = await loadJson(MESSAGES_FILE);
let publications = await loadJson(PUBLICATIONS_FILE);

// Relógio lógico
let logicalClock = 0;

function incrementClock() {
  return ++logicalClock;
}

function updateClock(receivedClock) {
  logicalClock = Math.max(logicalClock, receivedClock) + 1;
  return logicalClock;
}

// Sockets ZeroMQ
const repSocket = new zmq.Reply();
await repSocket.connect('tcp://broker:5556');

const pubSocket = new zmq.Publisher();
await pubSocket.connect('tcp://proxy:5557');

const refSocket = new zmq.Request();
await refSocket.connect('tcp://reference:5559');

const subSocket = new zmq.Subscriber();
await subSocket.connect('tcp://proxy:5558');
await subSocket.subscribe('servers');
await subSocket.subscribe('replication');

console.log('Servidor JS iniciado e conectado ao broker, proxy e referência');

// Obter rank do servidor de referência
const serverName = `${process.env.SERVER_NAME || 'server_js'}_${hostname()}`;
const rankMsg = msgpack.encode({
  service: 'rank',
  data: {
    user: serverName,
    timestamp: Date.now() / 1000,
    clock: incrementClock()
  }
});

await refSocket.send(rankMsg);
const [rankResponseBuf] = await refSocket.receive();
const rankResponse = msgpack.decode(rankResponseBuf);
updateClock(rankResponse.data?.clock || 0);
const serverRank = rankResponse.data?.rank || 0;
console.log(`Servidor ${serverName} registrado com rank ${serverRank}`);

// Variáveis para eleição e sincronização
let coordinator = null;
let messageCounter = 0;

// Heartbeat
setInterval(async () => {
  try {
    const hbMsg = msgpack.encode({
      service: 'heartbeat',
      data: {
        user: serverName,
        timestamp: Date.now() / 1000,
        clock: incrementClock()
      }
    });
    await refSocket.send(hbMsg);
    const [hbResponseBuf] = await refSocket.receive();
    const hbResponse = msgpack.decode(hbResponseBuf);
    updateClock(hbResponse.data?.clock || 0);
    console.log(`Heartbeat enviado, status: ${hbResponse.data?.status}`);
  } catch (e) {
    console.error('Erro ao enviar heartbeat:', e);
  }
}, 10000);

// Sincronização de dados
setInterval(async () => {
  try {
    const replicationData = msgpack.encode({
      service: 'replication',
      data: {
        server: serverName,
        users: users,
        channels: channels,
        timestamp: Date.now() / 1000,
        clock: incrementClock()
      }
    });
    await pubSocket.send(['replication', replicationData]);
    console.log('Dados de replicação publicados');
  } catch (e) {
    console.error('Erro na sincronização de dados:', e);
  }
}, 30000);

// Receber replicação e eleições
(async () => {
  for await (const [topic, msgBuf] of subSocket) {
    try {
      const msg = msgpack.decode(msgBuf);
      
      if (msg.service === 'election') {
        coordinator = msg.data?.coordinator;
        console.log(`Novo coordenador eleito: ${coordinator}`);
        updateClock(msg.data?.clock || 0);
      } else if (msg.service === 'replication') {
        const remoteServer = msg.data?.server;
        if (remoteServer !== serverName) {
          const remoteUsers = msg.data?.users || [];
          const remoteChannels = msg.data?.channels || [];
          
          for (const user of remoteUsers) {
            if (!users.includes(user)) {
              users.push(user);
              console.log(`Usuário replicado de ${remoteServer}: ${user}`);
            }
          }
          
          for (const channel of remoteChannels) {
            if (!channels.includes(channel)) {
              channels.push(channel);
              console.log(`Canal replicado de ${remoteServer}: ${channel}`);
            }
          }
          
          await saveJson(USERS_FILE, users);
          await saveJson(CHANNELS_FILE, channels);
          updateClock(msg.data?.clock || 0);
        }
      }
    } catch (e) {
      console.error('Erro ao processar mensagem de tópico:', e);
    }
  }
})();

// Loop principal do servidor
for await (const [msgBuf] of repSocket) {
  try {
    const message = msgpack.decode(msgBuf);
    console.log('Mensagem recebida:', message);
    
    const service = message.service;
    const data = message.data || {};
    
    updateClock(data.clock || 0);
    
    messageCounter++;
    if (messageCounter >= 10 && coordinator) {
      messageCounter = 0;
      console.log(`Sincronizando relógio com coordenador ${coordinator}`);
    }
    
    let response = {};
    
    if (service === 'login') {
      const user = data.user;
      const timestamp = data.timestamp;
      
      if (!user) {
        response = {
          service: 'login',
          data: {
            status: 'erro',
            timestamp: Date.now() / 1000,
            clock: incrementClock(),
            description: 'Nome de usuário não fornecido'
          }
        };
      } else if (users.includes(user)) {
        response = {
          service: 'login',
          data: {
            status: 'erro',
            timestamp: Date.now() / 1000,
            clock: incrementClock(),
            description: 'Usuário já existe'
          }
        };
      } else {
        users.push(user);
        logins.push({ user, timestamp });
        await saveJson(USERS_FILE, users);
        await saveJson(LOGINS_FILE, logins);
        response = {
          service: 'login',
          data: {
            status: 'sucesso',
            timestamp: Date.now() / 1000,
            clock: incrementClock()
          }
        };
      }
    } else if (service === 'users') {
      response = {
        service: 'users',
        data: {
          timestamp: Date.now() / 1000,
          clock: incrementClock(),
          users: users
        }
      };
    } else if (service === 'channel') {
      const channel = data.channel;
      
      if (!channel) {
        response = {
          service: 'channel',
          data: {
            status: 'erro',
            timestamp: Date.now() / 1000,
            clock: incrementClock(),
            description: 'Nome de canal não fornecido'
          }
        };
      } else if (channels.includes(channel)) {
        response = {
          service: 'channel',
          data: {
            status: 'erro',
            timestamp: Date.now() / 1000,
            clock: incrementClock(),
            description: 'Canal já existe'
          }
        };
      } else {
        channels.push(channel);
        await saveJson(CHANNELS_FILE, channels);
        response = {
          service: 'channel',
          data: {
            status: 'sucesso',
            timestamp: Date.now() / 1000,
            clock: incrementClock()
          }
        };
      }
    } else if (service === 'channels') {
      response = {
        service: 'channels',
        data: {
          timestamp: Date.now() / 1000,
          clock: incrementClock(),
          channels: channels
        }
      };
    } else if (service === 'publish') {
      const user = data.user;
      const channel = data.channel;
      const msgContent = data.message;
      const timestamp = data.timestamp;
      
      if (!channels.includes(channel)) {
        response = {
          service: 'publish',
          data: {
            status: 'erro',
            message: 'Canal não existe',
            timestamp: Date.now() / 1000,
            clock: incrementClock()
          }
        };
      } else {
        const pubMsg = msgpack.encode({
          service: 'publish',
          data: {
            user,
            channel,
            message: msgContent,
            timestamp,
            clock: incrementClock()
          }
        });
        await pubSocket.send([channel, pubMsg]);
        
        publications.push({ user, channel, message: msgContent, timestamp });
        await saveJson(PUBLICATIONS_FILE, publications);
        
        response = {
          service: 'publish',
          data: {
            status: 'OK',
            timestamp: Date.now() / 1000,
            clock: incrementClock()
          }
        };
      }
    } else if (service === 'message') {
      const src = data.src;
      const dst = data.dst;
      const msgContent = data.message;
      const timestamp = data.timestamp;
      
      if (!users.includes(dst)) {
        response = {
          service: 'message',
          data: {
            status: 'erro',
            message: 'Usuário não existe',
            timestamp: Date.now() / 1000,
            clock: incrementClock()
          }
        };
      } else {
        const pubMsg = msgpack.encode({
          service: 'message',
          data: {
            src,
            dst,
            message: msgContent,
            timestamp,
            clock: incrementClock()
          }
        });
        await pubSocket.send([dst, pubMsg]);
        
        messages.push({ src, dst, message: msgContent, timestamp });
        await saveJson(MESSAGES_FILE, messages);
        
        response = {
          service: 'message',
          data: {
            status: 'OK',
            timestamp: Date.now() / 1000,
            clock: incrementClock()
          }
        };
      }
    } else {
      response = {
        service: service,
        data: {
          status: 'erro',
          timestamp: Date.now() / 1000,
          clock: incrementClock(),
          description: 'Serviço não reconhecido'
        }
      };
    }
    
    await repSocket.send(msgpack.encode(response));
    console.log('Resposta enviada:', response);
  } catch (e) {
    console.error('Erro no servidor:', e);
    const errorResponse = msgpack.encode({
      service: 'error',
      data: {
        status: 'erro',
        timestamp: Date.now() / 1000,
        clock: incrementClock(),
        description: e.message
      }
    });
    await repSocket.send(errorResponse);
  }
}

