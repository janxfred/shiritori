FROM node:24-bullseye-slim AS builder

WORKDIR /app/backend

# Build context is repo root. Build with: docker build -f backend/Dockerfile .
COPY backend/package*.json ./
COPY backend/tsconfig.json ./
COPY backend/prisma ./prisma/

RUN npm ci
RUN npx prisma generate

COPY backend/src ./src/

# Dictionary file used by DictionaryRepository (resolved from dist at runtime)
WORKDIR /app
COPY shiritori_list.json ./shiritori_list.json

FROM node:24-bullseye-slim AS runner

ENV NODE_ENV=production

WORKDIR /app/backend

COPY --from=builder /app/backend/package*.json ./
COPY --from=builder /app/backend/node_modules ./node_modules/
COPY --from=builder /app/backend/prisma ./prisma/
COPY --from=builder /app/backend/src ./src/
COPY --from=builder /app/shiritori_list.json /app/shiritori_list.json

EXPOSE 8080

CMD ["npm", "start"]
