FROM node:24 AS construccion

WORKDIR /usr/app

RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

RUN pnpm install --frozen-lockfile

COPY nest-cli.json tsconfig*.json ./
COPY src ./src

RUN pnpm run build


FROM node:24-alpine AS publicacion

WORKDIR /usr/app

RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

RUN pnpm install --prod --frozen-lockfile

COPY --from=construccion /usr/app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main.js"]
