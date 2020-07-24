# Scalingo Keycloak buildpack

> This buildpack aims at installing a [Keycloak](https://keycloak.org) instance and let you configure it at your convenance.

## Usage

[Add this buildpack][1] to your Scalingo application to install the `Keycloak` server:

```shell
scalingo env-set 'BUILDPACK_URL=https://github.com/Scalingo/multi-buildpack
echo 'https://github.com/Scalingo/java-buildpack' >> .buildpacks
echo 'https://github.com/tristanrobert/keycloak-buildpack' >> .buildpacks
git add .buildpacks
git commit -m 'Add multi-buildpack java and keycloak'
```

Default version is `11.0.0`, but you can choose another one:

```shell
scalingo env-set KEYCLOAK_VERSION=10.0.2
```

## Configuration

You must have an add-on database `postgresql`.

Environment variables are set in a `.env` file. You copy the sample one:

```shell
cp .env.sample .env
```

## Hacking

Run an interactive docker scalingo stack:

```shell
 docker run --interactive --tty -e STACK=scalingo-18 --env-file  ~/Repositories/github.com/tristanrobert/keycloak-buildpack/.env -v ~/Repositories/github.com/tristanrobert/keycloak-buildpack:/buildpack scalingo/scalingo-18:latest bash
```

And test in it:

```shell
bash buildpack/bin/detect
bash buildpack/bin/compile
bash buildpack/bin/release
```

[1]: https://doc.scalingo.com/platform/deployment/buildpacks/multi
