# Homelab Installation Guide

the Makefile was created so that the installation, setup and management of the various
docker servcies is easier. contributions are welcome to make it even better

- clone and cd to the repo
```bash
git clone https://github.com/el-amine-404/batlab && cd batlab
```
- create the required directories, symlink the configs folder to the `$CONFIGS_ROOT`, fix ownership
```bash
make setup
```
- create the docker network used by the services
```bash
make network
```
- run the compose for one stack or all the stacks
```bash
make up STACK=<name> [SERVICE=<name>]
```

### Understanding Stacks vs. Services

When running commands via the `Makefile`, you will often see references to `STACK` and `SERVICE`. It is important to know the difference:

- **`STACK`**: Refers to the directory name inside `compose/` that holds a `docker-compose.yml` file. It groups related applications together.
- **`SERVICE`**: Refers to a specific container defined *inside* that stack's `docker-compose.yml` file.

**Example Usage:**
If you have a stack named `arr` (which contains multiple media services like `sonarr` and `radarr`):
- `make up STACK=arr` → Starts **all** services in the `arr` folder.
- `make restart STACK=arr SERVICE=sonarr` → Restarts **only** the `sonarr` container inside the `arr` stack.

You must always specify the `STACK` so the Makefile knows which folder to look in, but you only need to specify the `SERVICE` if you want to target a single container.

### Configure secrets

Create your env file from the template and fill in your private values for things
like: `HOST_IP`, `WIREGUARD_PRIVATE_KEY`, `IMMICH_DB_PASSWORD`, ...
```bash
cp compose/.env.example compose/.env
```
