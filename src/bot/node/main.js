const zmq = require('zeromq');
const serializer = require('./serde');
const LamportClock = require('./clock');

class Bot {
    constructor() {
        this.reqSocket = new zmq.Request();
        this.reqSocket.connect('tcp://broker:5555');

        this.subSocket = new zmq.Subscriber();
        this.subSocket.connect('tcp://proxy:5558');

        // Gerar nome aleatório
        this.username = `Bot${Math.floor(Math.random() * 1000)}`;
        this.channels = [];
        this.loggedIn = false;
        this.clock = new LamportClock();
    }

    async login() {
        try {
            console.log(`Bot ${this.username} fazendo login...`);

            const clock = this.clock.tick();
            const response = await this.sendRequest({
                service: 'login',
                data: {
                    user: this.username,
                    timestamp: Date.now(),
                    clock: clock
                }
            });

            if (response.data.clock) {
                this.clock.update(response.data.clock);
            }

            if (response.data.status === 'sucesso') {
                this.loggedIn = true;
                console.log(`Bot ${this.username} logado com sucesso! (clock: ${this.clock.getTime()})`);

                // Inscrever-se para receber mensagens
                this.subSocket.subscribe(this.username);
                console.log(`Bot ${this.username} inscrito no tópico ${this.username}`);

                return true;
            } else {
                console.error(`Erro no login do bot ${this.username}: ${response.data.description}`);
                return false;
            }
        } catch (error) {
            console.error(`Erro no login do bot ${this.username}:`, error.message);
            return false;
        }
    }

    async getChannels() {
        try {
            const clock = this.clock.tick();
            const response = await this.sendRequest({
                service: 'channels',
                data: {
                    timestamp: Date.now(),
                    clock: clock
                }
            });

            if (response.data.clock) {
                this.clock.update(response.data.clock);
            }

            this.channels = response.data.channels || [];
            console.log(`Bot ${this.username} encontrou ${this.channels.length} canais: ${this.channels.join(', ')}`);
        } catch (error) {
            console.error(`Erro ao obter canais do bot ${this.username}:`, error.message);
            this.channels = [];
        }
    }

    async publishToChannel(channel) {
        try {
            const clock = this.clock.tick();
            const response = await this.sendRequest({
                service: 'publish',
                data: {
                    user: this.username,
                    channel: channel,
                    message: `Mensagem automática do ${this.username} no canal ${channel} - ${new Date().toISOString()}`,
                    timestamp: Date.now(),
                    clock: clock
                }
            });

            if (response.data.clock) {
                this.clock.update(response.data.clock);
            }

            if (response.data.status === 'OK') {
                console.log(`Bot ${this.username} publicou no canal ${channel} (clock: ${this.clock.getTime()})`);
            } else {
                console.log(`Erro ao publicar no canal ${channel}: ${response.data.message || 'Desconhecido'}`);
            }
        } catch (error) {
            console.error(`Erro ao publicar no canal ${channel}:`, error.message);
        }
    }

    async sendRequest(request) {
        await this.reqSocket.send(serializer.serialize(request));

        const [response] = await this.reqSocket.receive();
        return serializer.deserialize(response);
    }

    async listenForMessages() {
        for await (const [topic, message] of this.subSocket) {
            try {
                const msg = serializer.deserialize(message);
                if (msg.clock) {
                    this.clock.update(msg.clock);
                }
                console.log(`Bot ${this.username} recebeu no tópico ${topic.toString()} (clock: ${this.clock.getTime()}):`, msg);
            } catch (error) {
                console.error(`Bot ${this.username} erro ao processar mensagem:`, error.message);
            }
        }
    }

    async run() {
        console.log(`Iniciando bot ${this.username}...`);

        // Tentar login
        if (!(await this.login())) {
            console.error(`Bot ${this.username} falhou no login. Saindo.`);
            return;
        }

        // Iniciar listener de mensagens em background
        this.listenForMessages().catch(console.error);

        // Ciclo principal: obter canais e publicar
        while (this.loggedIn) {
            try {
                // Obter lista de canais
                await this.getChannels();

                if (this.channels.length === 0) {
                    console.log(`Bot ${this.username} não encontrou canais. Criando um...`);
                    // Tentar criar um canal
                    await this.sendRequest({
                        service: 'channel',
                        data: {
                            channel: `canal-${this.username.toLowerCase()}`,
                            timestamp: Date.now()
                        }
                    });
                    await this.getChannels();
                }

                if (this.channels.length > 0) {
                    // Escolher canal aleatório
                    const randomChannel = this.channels[Math.floor(Math.random() * this.channels.length)];
                    console.log(`Bot ${this.username} escolhendo canal ${randomChannel}`);

                    // Enviar 10 mensagens
                    for (let i = 0; i < 10; i++) {
                        await this.publishToChannel(randomChannel);
                        // Pequena pausa entre mensagens
                        await new Promise(resolve => setTimeout(resolve, 100));
                    }
                }

                // Pausa antes do próximo ciclo
                console.log(`Bot ${this.username} aguardando próximo ciclo...`);
                await new Promise(resolve => setTimeout(resolve, 5000));

            } catch (error) {
                console.error(`Erro no ciclo do bot ${this.username}:`, error.message);
                await new Promise(resolve => setTimeout(resolve, 2000));
            }
        }
    }

    close() {
        this.reqSocket.close();
        this.subSocket.close();
    }
}

// Executar bot
const bot = new Bot();

process.on('SIGINT', () => {
    console.log(`Encerrando bot ${bot.username}...`);
    bot.close();
    process.exit(0);
});

bot.run().catch(error => {
    console.error(`Erro fatal no bot ${bot.username}:`, error);
    bot.close();
    process.exit(1);
});
