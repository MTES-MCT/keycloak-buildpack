# Scalingo Keycloak buildpack

> This buildpack aims at installing a [Keycloak](https://keycloak.org) instance on [Scalingo](https://www.scalingo.com) and let you configure it at your convenance.

[![Deploy to Scalingo](https://cdn.scalingo.com/deploy/button.svg)](https://my.scalingo.com/deploy?source=https://github.com/MTES-MCT/keycloak-buildpack)

## Suitability of releases

| Keycloak ---------| Buildpack |
|-------------------|-----------|
| < 17   (quarkus)  | 0.1.0     |
| >= 17  (wildfly)  | 0.2.0     |

## Usage

[Add this buildpack environment variable][1] to your Scalingo application to install the `Keycloak` server:

```shell
BUILDPACK_URL=https://github.com/MTES-MCT/keycloak-buildpack
```

Default version Keycloak is `latest` found in github releases, but you can choose another one:

```shell
scalingo env-set KEYCLOAK_VERSION=17.0.0
```

See [Keycloak latest docs](https://github.com/keycloak/keycloak-containers/tree/master/server-x) to use keycloak quarkus image server.

## Configuration

You must have an add-on database `postgresql`.

Environment variables are listed in [Keycloak quarkus configuration doc](https://www.keycloak.org/server/all-config), starting with `KC_`

### Add a user admin

In .env set these vars:

```shell
KEYCLOAK_ADMIN_USERNAME=your-admin-name
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

Run an interactive docker scalingo stack:

```shell
 docker run --name keycloak -it -p 8080:8080 -v "$(pwd)"/.env:/env/.env -v "$(pwd)":/buildpack scalingo/scalingo-20:latest bash
```

And test in it:

```shell
bash buildpack/bin/detect
bash buildpack/bin/env.sh /env/.env /env
bash buildpack/bin/compile /build /cache /env
bash buildpack/bin/release
```

Run Keycloak server:

```shell
export PATH=$PATH:/build/java/bin
build/keycloak/bin/kc.sh start 
```

You can also use docker-compose stack [2]:

```shell
docker-compose up --build -d
```

[1]: https://doc.scalingo.com/platform/deployment/buildpacks/custom
[2]: https://github.com/keycloak/keycloak-containers
