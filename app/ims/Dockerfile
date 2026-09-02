# syntax=docker/dockerfile:1

FROM node:20.17.0-bookworm-slim AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

FROM node:20.17.0-bookworm-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app

RUN groupadd --gid 1001 nodeapp && useradd --uid 1001 --gid nodeapp --shell /bin/false --create-home nodeapp

COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

USER nodeapp

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "src/server.js"]
