FROM node:20-slim

WORKDIR /app

COPY client/node/package*.json ./
RUN npm install

COPY client/node/ .
COPY client/start.sh .

# Garantir permissão de execução do script
# Normalizar quebras de linha (Windows -> Unix) e dar permissão de execução
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

CMD ["npm", "start"]
