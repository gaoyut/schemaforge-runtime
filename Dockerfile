ARG FLYWAY_VERSION=13.4.0
FROM redgate/flyway:${FLYWAY_VERSION}

ARG FLYWAY_VERSION
ARG VCS_REF=unknown

LABEL org.opencontainers.image.title="SchemaForge Runtime" \
      org.opencontainers.image.description="Database-independent Flyway runtime for version-controlled schemas" \
      org.opencontainers.image.version="${FLYWAY_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}"

ENV FLYWAY_LOCATIONS=filesystem:/flyway/sql

COPY --chmod=0555 bin/schemaforge /usr/local/bin/schemaforge

ENTRYPOINT ["/usr/local/bin/schemaforge"]
CMD ["migrate"]
