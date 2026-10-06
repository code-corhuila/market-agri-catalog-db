# market-agri-catalog-db

> Schema of the **catalog** domain: PostgreSQL 16, versioned with Liquibase.

Part of the **Marketplace Agrícola Huila** distributed system. Governance and documentation
live in [`market-agri-docs`](https://github.com/code-corhuila/market-agri-docs).

This repository owns **only the `catalog` schema**: its tables, roles, grants and migrations.
It does **not** define a database instance or a volume — the single PostgreSQL instance lives
in [`market-agri-infra`](https://github.com/code-corhuila/market-agri-infra) (Anexo J,
ADR-010). `market-agri-catalog-api` consumes the schema with the `catalog_app` user and never
versions it (ADR-011).

## Layout

```
changelog/changelog-master.yaml   single entry point: Liquibase runs only what it includes
01_ddl/    structure  00_extensions .. 10_indexes (extensions are created by market-agri-infra)
02_dml/    data       inserts, updates, deletes, upserts, patches
03_dcl/    access     catalog_reader / catalog_writer, grants, GRANT catalog_writer TO catalog_app
04_tcl/    control    transaction blocks, manual recoveries, release tags
05_rollbacks/          mirror: one .rollback.sql for every .sql (no changelogs here)
deploy/compose.yml     only the catalog-db-migrate runner (valid when market-agri-infra includes it)
.github/workflows/     db-ci.yml: rebuild from empty, J.10 isolation query, full rollback, rebuild
```

## Rules

1. Everything of this domain lives in the `catalog` schema; nothing in `public` except the
   Liquibase control tables `databasechangelog_catalog` / `databasechangeloglock_catalog` (J.6).
2. Tables are singular and created **without** foreign keys in `03_tables`; keys go in
   `04_alter`, each with its `ON DELETE` and an index. **No foreign keys to other schemas.**
3. Closed sets of values are a `CHECK`, never an `ENUM`. Money is `bigint` in cents.
4. Every changeset declares its rollback in `05_rollbacks/<mirror path>`.
5. An applied changeset is **never edited**; a correction is a new changeset.
   Changeset id: `<family>-<folder>-NNN`, never reused. `labels`: `"<SUBTASK-ID>,<family>,<folder>"`.
6. Seeds are idempotent (`INSERT … ON CONFLICT … DO UPDATE`).
7. Incompatible changes go in two releases (expand, then contract).

## Run it (always from `market-agri-infra`)

```bash
docker network create platform-dev                                   # once per machine and environment
docker compose --env-file env/dev.env run --rm catalog-db-migrate    # starts postgres, waits, migrates
docker compose --env-file env/dev.env run --rm catalog-db-migrate status --verbose
docker compose --env-file env/dev.env run --rm catalog-db-migrate rollback-count 1
```

In `qa` and `main`: back up first (`pg_dump`), migrate **before** deploying the `-api`.

## Branching

No permanent branch accepts a direct commit — you enter through a child branch and leave
through a Pull Request. Promotion is by re-application (`git cherry-pick -x`), never by merge.

```
develop  <--PR (squash)--  feat/… fix/… chore/…
qa       <--PR (merge)---  qa/…
main     <--PR (merge)---  release/… hotfix/…
```

Full rules: `00-governance/branching-policy.md` and `00-governance/git-conventions.md` in
`market-agri-docs`.
