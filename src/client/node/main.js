const zmq = require('zeromq');
const readline = require('readline');
const serializer = require('./serde');
const LamportClock = require('./clock');

class Client {
    constructor() {
        this.reqSocket = new zmq.Request();
        this.reqSocket.connect('tcp://broker:5555');

        this.rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });

        this.username = null;
        this.clock = new LamportClock();
    }

    async login() {
        const question = (query) => new Promise(resolve => this.rl.question(query, resolve));

        while (!this.username) {
            const username = (await question('Digite seu nome de usuário: ')).trim();

            if (!username) {
                console.log('Nome de usuário não pode ser vazio.');
                continue;
            }

            try {
                const clock = this.clock.tick();
                const response = await this.sendRequest({
                    service: 'login',
                    data: {
                        user: username,
                        timestamp: Date.now(),
                        clock: clock
                    }
                });

                // Atualizar relógio com resposta
                if (response.data.clock) {
                    this.clock.update(response.data.clock);
                }

                if (response.data.status === 'sucesso') {
                    this.username = username;
                    console.log(`Login realizado com sucesso como ${username}! (clock: ${this.clock.getTime()})`);
                } else {
                    console.log(`Erro no login: ${response.data.description || 'Desconhecido'}`);
                }
            } catch (error) {
                console.error('Erro na comunicação:', error.message);
            }
        }
    }

    async listUsers() {
        try {
            const clock = this.clock.tick();
            const response = await this.sendRequest({
                service: 'users',
                data: {
                    timestamp: Date.now(),
                    clock: clock
                }
            });

            if (response.data.clock) {
                this.clock.update(response.data.clock);
            }

            console.log('Usuários cadastrados:');
            response.data.users.forEach(user => console.log(`- ${user}`));
        } catch (error) {
            console.error('Erro ao listar usuários:', error.message);
        }
    }

    async createChannel() {
        const question = (query) => new Promise(resolve => this.rl.question(query, resolve));

        const channelName = (await question('Digite o nome do canal: ')).trim();

        if (!channelName) {
            console.log('Nome do canal não pode ser vazio.');
            return;
        }

        try {
            const clock = this.clock.tick();
            const response = await this.sendRequest({
                service: 'channel',
                data: {
                    channel: channelName,
                    timestamp: Date.now(),
                    clock: clock
                }
            });

            if (response.data.clock) {
                this.clock.update(response.data.clock);
            }

            if (response.data.status === 'sucesso') {
                console.log(`Canal '${channelName}' criado com sucesso!`);
            } else {
                console.log(`Erro ao criar canal: ${response.data.description || 'Desconhecido'}`);
            }
        } catch (error) {
            console.error('Erro ao criar canal:', error.message);
        }
    }

    async listChannels() {
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

            console.log('Canais disponíveis:');
            response.data.channels.forEach(channel => console.log(`- ${channel}`));
        } catch (error) {
            console.error('Erro ao listar canais:', error.message);
        }
    }

    async sendRequest(request) {
        await this.reqSocket.send(serializer.serialize(request));

        const [response] = await this.reqSocket.receive();
        return serializer.deserialize(response);
    }

	async sendPrivateMessage() {
		const question = (query) => new Promise(resolve => this.rl.question(query, resolve));

		const dst = (await question('Destinatário (usuário): ')).trim();
		if (!dst) {
			console.log('Destinatário não pode ser vazio.');
			return;
		}

		const text = (await question('Mensagem: ')).trim();
		if (!text) {
			console.log('Mensagem não pode ser vazia.');
			return;
		}

		try {
			const clock = this.clock.tick();
			const response = await this.sendRequest({
				service: 'message',
				data: {
					src: this.username,
					dst: dst,
					message: text,
					timestamp: Date.now(),
					clock: clock
				}
			});

			if (response.data.clock) {
				this.clock.update(response.data.clock);
			}

			if (response.data.status === 'OK') {
				console.log(`Mensagem enviada para ${dst}. (clock: ${this.clock.getTime()})`);
			} else {
				console.log(`Erro ao enviar mensagem: ${response.data.message || response.data.description || 'Desconhecido'}`);
			}
		} catch (error) {
			console.error('Erro ao enviar mensagem privada:', error.message);
		}
	}

	async publishToChannel() {
		const question = (query) => new Promise(resolve => this.rl.question(query, resolve));

		const channel = (await question('Canal: ')).trim();
		if (!channel) {
			console.log('Canal não pode ser vazio.');
			return;
		}

		const text = (await question('Mensagem: ')).trim();
		if (!text) {
			console.log('Mensagem não pode ser vazia.');
			return;
		}

		try {
			const clock = this.clock.tick();
			const response = await this.sendRequest({
				service: 'publish',
				data: {
					user: this.username,
					channel: channel,
					message: text,
					timestamp: Date.now(),
					clock: clock
				}
			});

			if (response.data.clock) {
				this.clock.update(response.data.clock);
			}

			if (response.data.status === 'OK') {
				console.log(`Publicado em #${channel}. (clock: ${this.clock.getTime()})`);
			} else {
				console.log(`Erro ao publicar: ${response.data.message || response.data.description || 'Desconhecido'}`);
			}
		} catch (error) {
			console.error('Erro ao publicar em canal:', error.message);
		}
	}

    showMenu() {
        console.log('\n=== Menu ===');
        console.log('1. Listar usuários');
        console.log('2. Criar canal');
		console.log('3. Listar canais');
		console.log('4. Enviar mensagem privada');
		console.log('5. Publicar em canal');
		console.log('6. Sair');
        console.log('============');
    }

    async run() {
        console.log('Cliente iniciado. Fazendo login...');
        await this.login();

        let running = true;
        while (running) {
            this.showMenu();

            const choice = await new Promise(resolve => {
                this.rl.question('Escolha uma opção: ', resolve);
            });

            switch (choice.trim()) {
                case '1':
                    await this.listUsers();
                    break;
                case '2':
                    await this.createChannel();
                    break;
                case '3':
                    await this.listChannels();
                    break;
                case '4':
					await this.sendPrivateMessage();
					break;
				case '5':
					await this.publishToChannel();
					break;
				case '6':
					running = false;
					console.log('Saindo...');
                    break;
                default:
                    console.log('Opção inválida.');
            }
        }

        this.rl.close();
        this.reqSocket.close();
    }
}

// Executar cliente
const client = new Client();
client.run().catch(console.error);
