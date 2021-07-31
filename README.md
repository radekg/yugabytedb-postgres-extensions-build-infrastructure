# YugabyteDB PostgreSQL extensions build infrastructure MVP

This is a minimal setup for [YugabyteDB](https://yugabyte.com) PostgreSQL extensions building. This repository is distilled from the YugabyteDB documentation, mainly:

- [Extensions requiring installation](https://docs.yugabyte.com/latest/api/ysql/extensions/#extensions-requiring-installation)

Comes with a very basic extension which disallows a non-regular user from:

- creating a table in the _pg\_public_ tablespace
- set _default\_tablespace_ and _temp\_tablespaces_; thus change them

## Create the build infrastructure Docker image

```sh
make ext-infra
```

## Build the extension

```sh
make ext-build
```

Optionally:

```sh
make ext-clean
```

## Run PostgreSQL with the extension

```sh
make ext-run-postgres
```

## Run tests: installcheck

```sh
make ext-installcheck
```

This target will run the regression tests using PostgreSQL regression testing framework.