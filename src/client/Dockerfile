FROM node:20-slim

WORKDIR /app

COPY client/node/package*.json ./
RUN npm install

COPY client/node/ .

CMD ["npm", "start"]
