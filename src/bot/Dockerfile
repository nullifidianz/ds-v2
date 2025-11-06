FROM node:20-slim

WORKDIR /app

COPY bot/node/package*.json ./
RUN npm install

COPY bot/node/ .
COPY bot/start.sh .

CMD ["npm", "start"]
