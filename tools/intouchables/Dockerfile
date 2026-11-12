FROM node:24.22.1-bookworm-slim
ENV NODE_ENV=production PORT=10000
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund
COPY --chown=node:node server/ ./server/
COPY --chown=node:node shared/ ./shared/
COPY --chown=node:node tools/intouchables/ ./tools/intouchables/
RUN node --check tools/intouchables/server.mjs
USER node
EXPOSE 10000
CMD ["node", "tools/intouchables/server.mjs"]
