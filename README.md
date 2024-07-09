<br/>
<p align="center">
  <h1 align="center">Suburb</h1>

  <p align="center">
    A small utility service that provides <strong>self-hostable logging, feature flags, queues and pub/sub</strong> via HTTP
  </p>
</p>

## Installing

Right now the way to install the CLI tool is via the [INSTALL.sh](https://github.com/lucaspellegrinelli/suburb/blob/main/INSTALL.sh) script. You can run it by cloning this repository and running the following command

```bash
./INSTALL.sh
```

## How to run this

The project contains both the host server code and a CLI to manage the configurations in one place.

### Running the CLI

Given that you already have a suburb host running, you can run the CLI tool to manage your configurations. Firstly set the remote host configurations

```bash
suburb config --host="https://your-remote.com/"
suburb config --token="your_api_secret"
```

Than you can interact with the features like

```bash
# Select a namespace (you can think of it like a project)
suburb config --namespace="my_namespace"

# List recent logs from the current namespace
suburb logs

# List queues in the current namespace
suburb queue

# Creates a queue called "queue_name" in the current namespace
suburb queue new "queue_name"

# Creates a feature flag in the current namespace and set it to True
suburb flag enable "flag_name"

# Gets the content of "flag_name"
suburb flag get "flag_name"

# Deletes the target feature flag
suburb flag delete "flag_name"
```

### Running the host server

You can run the host server via [Docker](https://www.docker.com/) by cloning this repository and building the provided `Dockerfile`.

```bash
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

To access these features in your code you can send HTTP requests following the API rules to your Surburb host. To simplify the process you can use one of the following clients for it (just copy these to your project):

 - [[WIP] Python Client](https://github.com/lucaspellegrinelli/suburb/blob/main/clients/suburb.py) Works but doesn't have typing or anything relevant. Just calls the API and returns the raw response
 - [[WIP] Javascript Client](https://github.com/lucaspellegrinelli/suburb/blob/main/clients/suburb.js) Works but doesn't have typing or anything relevant. Just calls the API and returns the raw response

## Running tests

To run the tests you can use the following command

```bash
gleam test
```

## License

Distributed under the Apache License 2.0. See [LICENSE](https://github.com/lucaspellegrinelli/suburb/blob/main/LICENSE) for more information.
