# syntax=docker/dockerfile:1
# TODO(new-service): keep this contract (multi-stage, non-root, HEALTHCHECK) even as you customize the app.

FROM node:20.20.2-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

FROM node:20.20.2-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app

RUN addgroup -g 1001 nodeapp && adduser -D -H -u 1001 -G nodeapp -s /sbin/nologin nodeapp

# Pull latest patched OS packages from Alpine's repos at build time (e.g. openssl fixes that
# post-date this base image's pinned snapshot) rather than waiting on the next base-image bump.
RUN apk update && apk upgrade --no-cache

# The base image ships a global npm/npx/corepack install for convenience, but this runtime
# stage only ever runs `node` - it never invokes npm. Removing it drops the CVEs that
# accumulate in npm's own bundled dependencies (tar, minimatch, glob, cross-spawn, pacote,
# sigstore, ...) from the final image entirely, instead of chasing them per base-image bump.
RUN rm -rf /usr/local/lib/node_modules/npm \
    /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack \
    /opt/yarn* 2>/dev/null || true

COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

USER nodeapp

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "src/server.js"]
