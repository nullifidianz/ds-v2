FROM node:20-alpine

WORKDIR /app

# Instalar dependências de build para zeromq
RUN apk add --no-cache python3 make g++ zeromq-dev

COPY package.json .
RUN npm install

CMD ["node", "main.js"]

