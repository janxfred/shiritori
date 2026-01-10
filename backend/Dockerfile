FROM node:24-bullseye-slim

WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci && npx prisma generate

COPY . .

EXPOSE 3002

CMD ["npm", "run", "dev"]
