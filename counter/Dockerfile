FROM node:22-alpine AS deps
WORKDIR /app
# better-sqlite3 is native, so the build needs a toolchain that the final
# image doesn't have to carry.
RUN apk add --no-cache python3 make g++
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm install --omit=dev

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080
ENV DB_FILE=/data/counter.sqlite
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src
# The volume holds two integers; it still must survive redeploys.
VOLUME ["/data"]
RUN mkdir -p /data && chown -R node:node /data /app
USER node
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD node -e "fetch('http://127.0.0.1:8080/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "src/server.js"]
