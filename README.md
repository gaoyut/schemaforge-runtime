# SchemaForge Runtime

A database-independent Flyway runtime for schema version management. Business SQL
does not belong in this repository. Each application builds its own immutable image
from this runtime and copies its versioned SQL into `/flyway/sql`.

## Responsibilities

- Pin and update the Flyway runtime version.
- Provide one consistent container entrypoint.
- Accept database credentials only at runtime.
- Supply database-specific driver variants when a driver is not bundled by Flyway.

## Build

Requirements: Docker or a compatible builder.

```sh
make build
make smoke
```

The default image is `schemaforge-runtime:13.4.0`. Override versions explicitly:

```sh
make build FLYWAY_VERSION=13.4.0 IMAGE_TAG=13.4.0
```

## Use from an application schema repository

```dockerfile
FROM 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/platform/schemaforge-runtime:13.4.0
COPY migrations/ /flyway/sql/
```

Run the resulting image with secrets supplied by the runtime environment:

```sh
docker run --rm \
  -e FLYWAY_URL='jdbc:jtds:sybase://db.example:5000/application_db' \
  -e FLYWAY_USER='schema_owner' \
  -e FLYWAY_PASSWORD='replace-at-runtime' \
  application-schema:1.0.0 migrate
```

Never put credentials in this repository, a Dockerfile, build arguments, image
labels, or a committed Flyway configuration file.

## Sybase ASE first-use profile

The Redgate Flyway CLI includes the jTDS driver. Use:

```text
jdbc:jtds:sybase://HOST:PORT/DATABASE
```

Sybase scripts use `GO` as the statement delimiter. Sybase ASE does not support
`flyway.schemas` or transactional DDL, so keep each migration focused and test
failure recovery against a disposable ASE database.

Example migration:

```sql
CREATE TABLE schemaforge_version_probe (
    probe_id NUMERIC(18, 0) IDENTITY,
    created_at DATETIME NOT NULL,
    CONSTRAINT pk_schemaforge_version_probe PRIMARY KEY (probe_id)
)
GO
```

## Push to Amazon ECR

Requirements: Docker, AWS CLI, and authenticated AWS credentials with limited ECR
permissions.

```sh
make push \
  AWS_ACCOUNT_ID=123456789012 \
  AWS_REGION=ap-southeast-1 \
  IMAGE_TAG=13.4.0
```

This creates the `platform/schemaforge-runtime` repository if necessary, enables
scan-on-push, installs the lifecycle policy from `ecr/lifecycle-policy.json`, and
pushes the versioned image. Do not publish `latest`; deployments should reference
a fixed tag or digest.

## Entrypoint behavior

The default command is `migrate`. Database operations require `FLYWAY_URL`,
`FLYWAY_USER`, and `FLYWAY_PASSWORD`. Other Flyway arguments are forwarded without
modification.

Examples:

```sh
docker run --rm schemaforge-runtime:13.4.0 -v
docker run --rm [runtime environment and secrets] schemaforge-runtime:13.4.0 info
docker run --rm [runtime environment and secrets] schemaforge-runtime:13.4.0 validate
```
