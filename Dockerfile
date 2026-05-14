# Esta etapa instala todas las dependencias del proyecto.
# Incluye dependencias de desarrollo, porque para compilar TypeScript
# necesitamos herramientas como Nest CLI y TypeScript.
FROM node:24 AS dependencias

WORKDIR /usr/app

# Corepack viene con Node y permite usar la version de pnpm declarada
# en package.json, sin instalar pnpm manualmente.
RUN corepack enable

# Copiamos primero solo los archivos que definen dependencias.
# Si cambia el codigo fuente pero no cambian estos archivos,
# Docker puede reutilizar la capa de pnpm install.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

RUN pnpm install --frozen-lockfile


# Esta etapa compila la aplicacion.
# Parte desde dependencias, por lo que ya tiene node_modules instalado.
FROM dependencias AS construccion

# Recién ahora copiamos la configuracion de build y el codigo fuente.
# Asi, cambiar un archivo dentro de src no obliga a reinstalar dependencias.
COPY nest-cli.json tsconfig*.json ./
COPY src ./src

RUN pnpm run build


# Esta etapa instala solo las dependencias necesarias para ejecutar la app.
# No incluye herramientas de desarrollo, tests ni compiladores.
FROM node:24-alpine AS dependencias-produccion

WORKDIR /usr/app

RUN corepack enable

# Usamos los mismos archivos de dependencias, pero con --prod
# para instalar solamente lo necesario en ejecucion.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

RUN pnpm install --prod --frozen-lockfile


# Esta es la imagen final.
# La dejamos lo mas limpia posible: solo runtime, package.json,
# dependencias de produccion y la aplicacion ya compilada.
FROM node:24-alpine AS publicacion

WORKDIR /usr/app

COPY package.json ./
COPY --from=dependencias-produccion /usr/app/node_modules ./node_modules
COPY --from=construccion /usr/app/dist ./dist

EXPOSE 3000

# Ejecutar como usuario node evita correr la aplicacion como root.
USER node

CMD ["node", "dist/main.js"]
