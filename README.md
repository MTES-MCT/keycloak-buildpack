# Scalingo Keycloak buildpack

> This buildpack aims at installing a [Keycloak](https://keycloak.org) instance on [Scalingo](https://www.scalingo.com) and let you configure it at your convenance.

[![Deploy to Scalingo](https://cdn.scalingo.com/deploy/button.svg)](https://my.scalingo.com/deploy?source=https://github.com/MTES-MCT/keycloak-buildpack)

## Keycloak providers : 
For public providers (Public github repository) add an env variable :
```
    KEYCLOAK_PROVIDERS="provider1,provider2"
```
ex : KEYCLOAK_PROVIDERS=MTES-MCT/Keycloak-FranceConnect,jacekkow/keycloak-protocol-cas,MTES-MCT/dossierfacile-keycloak-extension

For private providers (Private github repository) add an env variable : 
```
    KEYCLOAK_PRIVATE_PROVIDER=provider1||$GITHUBID:$GITHUB_PAT,provider2||$GITHUBID:$GITHUB_PAT
```

ex: KEYCLOAK_PRIVATE_PROVIDER=MTES-MCT/Dossier-Facile-Keycloak||$GITHUBID:$GITHUB_PAT

## Suitability of releases

| Keycloak          | Buildpack |
|-------------------|-----------|
| < 17   (wildfly)  | 0.1.0     |
| >= 17  (quarkus)  | 0.2.0     |
| >= 23  (quarkus)  | 1.0.0     |

## Usage

[Add this buildpack environment variable][1] to your Scalingo application to install the `Keycloak` server:

```shell
BUILDPACK_URL=https://github.com/MTES-MCT/keycloak-buildpack
```

Default version Keycloak is `latest` found in github releases, but you can choose another one:

```shell
scalingo env-set KEYCLOAK_VERSION=23.0.4
```

See [Keycloak latest docs](https://www.keycloak.org/server/containers) to use keycloak quarkus image server.

!!! HTTPS is mandatory in production mode [4]

## Configuration

You must have an add-on database `postgresql`.

Environment variables are listed in [Keycloak quarkus configuration doc](https://www.keycloak.org/server/all-config), starting with `KC_`

### Add a user admin

In .env set these vars:

```shell
KEYCLOAK_ADMIN=your-admin-name
KEYCLOAK_ADMIN_PASSWORD=your-admin-password
```

then build again.

### Export or import data

See [Keycloak Admin CLI docs](https://www.keycloak.org/docs/latest/server_admin/index.html#admin-cli)

With [Scalingo CLI](https://doc.scalingo.com/platform/app/tasks#upload-an-archive-and-extract-it-on-the-server) you can download or upload these files.

## Hacking

Environment variables are set in a `.env` file. You copy the sample one:

```shell
cp .env.sample .env
```

Run an interactive docker scalingo stack [2]:

```shell
docker run --name keycloak -it -p 8443:8443 -v "$(pwd)"/.env:/env/.env -v "$(pwd)":/buildpack scalingo/scalingo-22:latest bash
```

And test in it:

```shell
bash buildpack/bin/detect
bash buildpack/bin/env.sh /env/.env /env
bash buildpack/bin/compile /build /cache /env
build/java/bin/keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore /build/keycloak/conf/server.keystore
bash buildpack/bin/release
```

Run Keycloak server:

```shell
export PATH=$PATH:/build/java/bin
export KEYCLOAK_ADMIN=
export KEYCLOAK_ADMIN_PASSWORD=
export KC_DB=postgres
export KC_HOSTNAME=localhost
export KC_HOSTNAME_PORT=8443
build/keycloak/bin/kc.sh --verbose start
```

You can also use docker-compose stack [3]:

```shell
docker-compose up --build -d
```

[1]: https://doc.scalingo.com/platform/deployment/buildpacks/custom
[2]: https://www.keycloak.org/server/containers
[3]: https://github.com/keycloak/keycloak/tree/main/quarkus/container
[4]: https://www.keycloak.org/server/containers#_starting_the_optimized_keycloak_docker_image
