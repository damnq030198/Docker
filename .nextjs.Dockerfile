# Base Stage: Upgrade npm and install / upgrade yarn
FROM node:21.1-alpine AS base
LABEL builder=true

# 1. Dependence Stage: Cài đặt dependencies
FROM base AS dependence
WORKDIR /app
COPY package*.json yarn.lock ./
RUN apk add --no-cache git \
    && yarn --frozen-lockfile \
    && yarn cache clean

# 2. Builder Stage: Build ứng dụng Next.js
FROM base AS builder
WORKDIR /app
COPY --from=dependence /app/node_modules ./node_modules
COPY . .
RUN apk add --no-cache git curl \
    && yarn build \
    && cd .next/standalone \
    && curl -sf https://gobinaries.com/tj/node-prune | sh \
    && node-prune

# 3. Runner Stage: Chạy ứng dụng
FROM base AS runner
WORKDIR /app
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./          
COPY --from=builder /app/next.config.mjs ./

EXPOSE 3000
CMD ["node", "server.js"]
