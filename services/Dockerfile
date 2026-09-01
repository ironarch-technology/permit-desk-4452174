FROM node:22-slim

WORKDIR /srv/services

COPY package.json ./
RUN npm install --omit=dev

COPY . .

RUN chown -R node:node /srv/services
USER node

CMD ["node", "zoning/index.js"]
