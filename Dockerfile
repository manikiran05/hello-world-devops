FROM node:22-alpine

RUN apk add --no-cache dumb-init

ENV NODE_ENV=production

WORKDIR /app

COPY --chown=node:node package*.json ./

RUN npm ci --omit=dev \
    && npm cache clean --force \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx

COPY --chown=node:node src ./src

USER node

EXPOSE 3000

CMD ["dumb-init", "node", "src/server.js"]
