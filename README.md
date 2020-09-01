# Scalingo Keycloak buildpack

> This buildpack aims at installing a [Keycloak](https://keycloak.org) instance and let you configure it at your convenance.

## Usage

[Add this buildpack environment variable][1] to your Scalingo application to install the `Keycloak` server:

```shell
BUILDPACK_URL=https://github.com/tristanrobert/keycloak-buildpack
```

Default version is `11.0.1`, but you can choose another one:

```shell
scalingo env-set KEYCLOAK_VERSION=10.0.2
```

See [Keycloak docs](https://github.com/keycloak/keycloak-containers/tree/master/server) to use keycloak image server.

## Configuration

You must have an add-on database `postgresql`.

Environment variables are set in a `.env` file. You copy the sample one:

```shell
cp .env.sample .env
```

## Hacking

Run an interactive docker scalingo stack:

```shell
 docker run --name keycloak --interactive --tty -p 8080:8080 --env-file  ~/Repositories/github.com/tristanrobert/keycloak-buildpack/.env -v ~/Repositories/github.com/tristanrobert/keycloak-buildpack:/buildpack scalingo/scalingo-18:latest bash
```

And test in it:

```shell
bash buildpack/bin/detect
bash buildpack/bin/compile /build '' ''
bash buildpack/bin/release
```

Run Keycloak server:

```shell
export PATH=$PATH:/app/java/bin
./bin/run -b 0.0.0.0
```

You can also use docker-compose stack:

```shell
docker-compose up --build -d
```

[1]: https://doc.scalingo.com/platform/deployment/buildpacks/custom
