FROM node:22-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --only=production && npm cache clean --force

COPY dist/ ./dist/

EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=5s --retries=3   CMD wget -qO- http://localhost:9000/health || exit 1

USER node

CMD ["node", "dist/index.js"]
