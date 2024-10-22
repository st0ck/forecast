# Forecast

Forecast is a weater forcasting service based on the entered address.

## Run project

```bash
docker-compose up --build
```

Visit http://localhost:3000

Note: To properly stop the contianers on linux always use `docker-compose down`

## Executing commands in running container

```bash
bin/run <service name> <command>
```

where
- `<service name>` is a name of a service from the `docker-compose.yml` file (e.g. `api`, `ui`, etc.)
- `<command>` is a command you'd like to execute in the container (e.g. `bin/rails c`, `bash`, `bundle exec rubocop`, etc.)

Under the hood it executes `docker exec -it <container name> <command>`.

## How it's configured

Docker compose starts following contianers:

- api (Ruby on Rails)
- ui (React)
- redis
- nginx

Every request is hittin nginx first, then based on the path patterns the requests will be redirected to the right container. The redirects configured based on the following rules:

- paths starting with `/api` is routed to the `api` container
- everything else is redirected to the `ui` contianer
- requests with paths starting with `/ws` are treated separately and serve only to support hot reload on the frontend side in the development environment

Nginx can serve as a load balancer if more servers specified.

## Debugging

Start containers and add a debugger statement.
To attach to a specific container execute

```bash
bin/attach <service name>
```

where
- `<service name>` is a name of a service from the `docker-compose.yml` file (e.g. `api`, `ui`, etc.)

For example, to debug rails app
1. add `debugger` to the code
2. execute

```bash
bin/attach meteosense-api-1
```

3. trigger an action to run the code

**Attention:** Pressing `ctrl-c` will stop the process in the container, please use `ctrl-k` instead.
