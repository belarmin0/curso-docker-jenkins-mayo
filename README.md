# Curso Contenedores - API NestJS con Docker Compose

Este proyecto contiene una API backend hecha con NestJS y TypeScript.

El contexto actual de la aplicacion es:

- un contenedor `backend` para la API
- un contenedor `db-app` con PostgreSQL
- configuracion por variables de entorno
- activacion opcional del modulo de base de datos mediante `ENABLE_DB`
- endpoints de health para liveness y readiness
- un manifiesto Kubernetes de ejemplo en [`kubernetes.yaml`](kubernetes.yaml)
- un ejemplo separado de WordPress con MySQL en [`compose-wordpress/`](compose-wordpress)

El flujo principal de este repositorio hoy es levantar la aplicacion con `docker compose` usando el archivo [`docker-compose.yaml`](docker-compose.yaml) y las variables de [`.env.app`](.env.app).

## Estructura principal

- [`src/main.ts`](src/main.ts): punto de entrada de NestJS
- [`src/app.module.ts`](src/app.module.ts): modulo principal
- [`src/config/app.config.ts`](src/config/app.config.ts): configuracion centralizada
- [`src/modules/calculo`](src/modules/calculo): modulo de calculo
- [`src/modules/users-data`](src/modules/users-data): modulo de usuarios y acceso a PostgreSQL
- [`Dockerfile`](Dockerfile): imagen multi-stage de la API
- [`docker-compose.yaml`](docker-compose.yaml): orquestacion de backend + base de datos
- [`.env.app`](.env.app): variables usadas por Compose
- [`kubernetes.yaml`](kubernetes.yaml): manifiesto Kubernetes de ejemplo
- [`compose-wordpress/docker-compose.yaml`](compose-wordpress/docker-compose.yaml): ejemplo independiente de WordPress + MySQL

## Requisitos

- Docker
- Docker Compose

Si quieres ejecutar la API fuera de contenedores:

- Node.js 24
- pnpm 11

El proyecto declara `packageManager: pnpm@11.1.2` y usa `only-allow pnpm`, por lo que las instalaciones locales deben hacerse con pnpm.

## Levantar la aplicacion con Docker Compose

La forma principal de ejecutar este proyecto es:

```bash
docker compose --env-file .env.app up --build
```

Para dejarlo en segundo plano:

```bash
docker compose --env-file .env.app up --build -d
```

Para detenerlo:

```bash
docker compose --env-file .env.app down
```

La API queda expuesta en:

- `http://localhost:3000`

## Variables de entorno que hoy existen en `.env.app`

El archivo [`.env.app`](.env.app) define actualmente:

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=curso_contenedores
ENABLE_DB=true
APP_VERSION=1.0.0
```

Estas son las unicas variables declaradas hoy en ese archivo.

Con ese arranque:

- PostgreSQL se crea con la base `curso_contenedores`
- la API se conecta al contenedor `db-app`
- el modulo de usuarios queda habilitado porque `ENABLE_DB=true`

## Variables que realmente consume la aplicacion

En codigo, la aplicacion NestJS lee estas variables:

- `PORT`: puerto HTTP de la API. Por defecto `3000`
- `ENABLE_DB`: habilita o deshabilita el modulo de base de datos
- `DB_HOST`: host de PostgreSQL. Por defecto `localhost`
- `DB_PORT`: puerto de PostgreSQL. Por defecto `5432`
- `DB_USERNAME`: usuario de PostgreSQL. Por defecto `postgres`
- `DB_PASSWORD`: password de PostgreSQL. Por defecto `password`
- `DB_NAME`: nombre de la base de datos. Por defecto `nestjs_db`

Estas variables salen de [`src/config/app.config.ts`](src/config/app.config.ts) y luego se usan en [`src/main.ts`](src/main.ts) y [`src/modules/users-data/database/database.module.ts`](src/modules/users-data/database/database.module.ts).

Importante:

- `PORT` si existe en la aplicacion, pero hoy no esta definido en `.env.app`
- `APP_VERSION` si existe en `docker-compose.yaml` y `kubernetes.yaml`, pero la aplicacion no lo usa en ningun archivo `src/`
- `POSTGRES_USER`, `POSTGRES_PASSWORD` y `POSTGRES_DB` no los lee NestJS directamente

Cuando se usa Compose, esas variables que si consume la app quedan resueltas asi dentro del servicio `backend`:

- `DB_HOST=db-app`
- `DB_PORT=5432`
- `DB_USERNAME=${POSTGRES_USER}`
- `DB_PASSWORD=${POSTGRES_PASSWORD}`
- `DB_NAME=${POSTGRES_DB}`
- `ENABLE_DB=${ENABLE_DB:-false}`

Si `ENABLE_DB=false`, la aplicacion arranca sin cargar el modulo `users-data`.

## Ejecutar sin Docker

Instala dependencias:

```bash
pnpm install
```

Ejecuta en desarrollo:

```bash
pnpm run start:dev
```

Si quieres levantar la API local con base habilitada, por ejemplo:

```bash
ENABLE_DB=true \
DB_HOST=localhost \
DB_PORT=5432 \
DB_USERNAME=postgres \
DB_PASSWORD=postgres \
DB_NAME=curso_contenedores \
pnpm run start:dev
```

## Comandos utiles

```bash
pnpm run build
pnpm run lint
pnpm run test
pnpm run test:cov
```

La salida compilada queda en `dist/`.

## Endpoints principales

### Basicos

- `GET /hello`
- `GET /hi`

### Calculo

- `GET /calculo?operacion=suma&a=10&b=20`
- `GET /calculo?operacion=resta&a=20&b=5`
- `GET /calculo?operacion=multiplicacion&a=3&b=4`
- `GET /calculo?operacion=division&a=10&b=2`

### Health

- `GET /health/live`
- `GET /health/ready`

`/health/live` responde si la app sigue viva.

`/health/ready` responde si la app esta lista para recibir trafico. Si la base esta habilitada, valida que `DataSource` este inicializado. Si `ENABLE_DB=false`, responde `ok` y marca la base como `skipped`.

### Carga

- `GET /cpu`
- `GET /memory`
- `GET /memory?size=200`

Estos endpoints sirven para pruebas simples de consumo de CPU y memoria.

### Usuarios

Con `ENABLE_DB=true`, tambien quedan disponibles:

- `POST /users`
- `GET /users`
- `GET /users/:id`
- `PATCH /users/:id`
- `DELETE /users/:id`

La entidad `usuarios` incluye:

- `id`
- `nombre`
- `edad`
- `created_at`
- `updated_at`

## Base de datos

El acceso a base de datos usa:

- `@nestjs/config`
- `@nestjs/typeorm`
- PostgreSQL

La configuracion vive principalmente en:

- [`src/config/app.config.ts`](src/config/app.config.ts)
- [`src/modules/users-data/database/database.module.ts`](src/modules/users-data/database/database.module.ts)

TypeORM esta configurado con:

- `autoLoadEntities: true`
- `synchronize: true`
- `logging: ['error']`

## Ejemplo WordPress

La carpeta [`compose-wordpress/`](compose-wordpress) contiene un ejemplo independiente de WordPress con MySQL.

Ese ejemplo usa:

- [`compose-wordpress/docker-compose.yaml`](compose-wordpress/docker-compose.yaml)
- [`compose-wordpress/.env.wordpress`](compose-wordpress/.env.wordpress)
- secretos en [`compose-wordpress/secrets/`](compose-wordpress/secrets)

Para levantarlo:

```bash
docker compose --env-file compose-wordpress/.env.wordpress -f compose-wordpress/docker-compose.yaml up -d
```

WordPress queda expuesto en:

- `http://localhost:8080`

Este ejemplo no corresponde al flujo principal de la API NestJS.
