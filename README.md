<br/>
<p align="center">
  <h1 align="center">Suburb</h1>

  <p align="center">
    A small utility service that provides <strong>self-hostable logging, feature flags and queues</strong> via HTTP
  </p>
</p>

## How to run this

The project contains both the host server code and a CLI to manage the configurations in one place.

### Running the CLI

Given that you already have a suburb host running, you can run the CLI tool to manage your configurations. Firstly set the remote host configurations

```
suburb remote set https://your-remote.com/ your_api_secret
suburb remote get
```

Than you can interact with the features like

```
suburb log list

suburb queue create "some_project" "queue_name"
suburb queue pop "some_project" "queue_name"

suburb flag list
suburb flag set "some_project" "flag_name" "true"
suburb flag get "some_project" "flag_name"
```

### Running the host server

You can run the host server via [Docker](https://www.docker.com/) by cloning this repository and building the provided `Dockerfile`.

```
docker build -t suburb .
docker run -p 8080:8080 -v $(pwd)/suburb.db:/app/suburb.db suburb
```

> You can also specify environment variables for `PORT`, `API_SECRET` and `DATABASE_PATH`

#### Without docker

The CLI also provides the command to start a host server

```
suburb host
```

> To configure the port, api key and database path just set `PORT`, `API_SECRET` and `DATABASE_PATH` in your environment variables

## How to access these in my code?

To access these features in your code you can send HTTP requests following the API rules to your Surburb host. To simplify the process you can use one of the following clients for it:

 - Python Client (IN PROGRESS)
 - Javascript Client (IN PROGRESS)

## License

Distributed under the Apache License 2.0. See [LICENSE](https://github.com/lucaspellegrinelli/suburb/blob/main/LICENSE) for more information.
