# Scalingo Keycloak buildpack

> This buildpack aims at installing a [Keycloak](https://keycloak.org) instance and let you configure it at your convenance.

[![Deploy to Scalingo](https://cdn.scalingo.com/deploy/button.svg)](https://my.scalingo.com/deploy?source=https://github.com/tristanrobert/keycloak-buildpack)

## Usage

[Add this buildpack environment variable][1] to your Scalingo application to install the `Keycloak` server:

```shell
BUILDPACK_URL=https://github.com/tristanrobert/keycloak-buildpack
```

Default version is `11.0.2`, but you can choose another one:

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

### Add a user admin

In .env set these vars:

```shell
KEYCLOAK_ADMIN_USERNAME=your-admin-name
KEYCLOAK_ADMIN_PASSWORD=your-admin-password
```

then build again.

### Export or import data

```shell
/app/keycloak/bin/standalone.sh \
-Djboss.socket.binding.port-offset=100 -Dkeycloak.migration.action=export \
-Dkeycloak.migration.provider=singleFile \
-Dkeycloak.migration.realmName=my_realm \
-Dkeycloak.migration.usersExportStrategy=REALM_FILE \
-Dkeycloak.migration.file=/tmp/my_realm.json
```

Don't forget the `-Djboss.socket.binding.port-offset=100` change ports to not stop server running.

You can do the same with import. See [Export/import docs](https://www.keycloak.org/docs/latest/server_admin/index.html#_export_import)

With [scalingo CLI](https://doc.scalingo.com/platform/app/tasks#upload-an-archive-and-extract-it-on-the-server) you can download or upload these files.

## Hacking

Run an interactive docker scalingo stack:

```shell
 docker run --name keycloak -it -p 8080:8080 -v ~/Repositories/github.com/tristanrobert/keycloak-buildpack/.env:/env/.env -v ~/Repositories/github.com/tristanrobert/keycloak-buildpack:/buildpack scalingo/scalingo-18:latest bash
```

And test in it:

```shell
bash buildpack/bin/detect
bash buildpack/bin/compile /build /cache /env
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
