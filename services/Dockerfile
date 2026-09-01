FROM node:22-slim

WORKDIR /srv/services

COPY package.json ./
RUN npm install --omit=dev

COPY . .

CMD ["node", "zoning/index.js"]
