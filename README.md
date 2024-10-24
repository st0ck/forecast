# Forecast

Forecast is a weater forcasting service based on the entered address.

DEMO:
https://github.com/user-attachments/assets/6b164750-fea5-4a68-98da-6b8298321753

[Code challenge requirements and made assumptions](docs/REQUIREMENTS_AND_ASSUMPTIONS.md)

[API description](docs/API_DESCRIPTION.md)

## App data flow

1. User types an address on the frontend, triggering a call to Address Lookup API.
2. The backend retrieves suggestions using Mapbox API and returns them to the frontend for display.

3. When the user selects an address, the React App makes two parallel API calls to the backend:
   - Current weather API for current conditions.
   - A Forecast API for a daily forecast.

4. Backend checks if the data can be retrieved from the cache
   - If a cache hit occurs, cached data is returned. Cache is stored using H3 geohashing algorithm.
   - On a cache miss, data is fetched from OpenWeather API.

5. The frontend receives and displays the current weather and the following days forecast.
Cache status headers (X-Cache-Hit, X-Cache-Age) indicate whether the data was cached.

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

## Testing

```bash
bin/run api bin/rails test test
```

## CI

The basic UI and API checks (tests, linters and vulnerability scans) are implemented using GitHub Actions.

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
bin/attach forecast-api-1
```

3. trigger an action to run the code

**Attention:** Pressing `ctrl-c` will stop the process in the container, please use `ctrl-k` instead.
