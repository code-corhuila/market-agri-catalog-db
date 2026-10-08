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
8. **Least privilege for the app user.** `catalog_app` only gets `catalog_writer`
   (`SELECT, INSERT, UPDATE` on `catalog`). There is **no `DELETE` on purpose**: catalog uses
   soft delete (`deleted_at`), reservations are released with `released_at`, and the photo is
   a column (D-C8). When a use case needs physical delete, it is granted **per table, in its
   own `03_dcl` changeset**. Today no table needs it; purging old `idempotency_key` rows is
   declared technical debt. `02_dml/02_deletes` is for data migrations run by the
   administrator, not for the app.

## Data dictionary

Contract: `07-api/api-contract.md` §4.2 in `market-agri-docs`. Every table lives in `catalog`.

### `product` — what a producer offers

| Column | Type | Null | Meaning and rules |
|---|---|---|---|
| `id` | `uuid` | no | Primary key, `gen_random_uuid()` |
| `producer_id` | `uuid` | no | Owner (JWT `sub`). Lives in auth: an id, **no foreign key** |
| `producer_name` | `text` | no | Snapshot of the JWT `name` at creation (D-C31), 1–150 after trim |
| `name` | `text` | no | 1–150 after trim |
| `category` | `text` | no | One of the 10 `ProductCategory` codes (D-C6) |
| `unit` | `text` | no | One of the 10 `ProductUnit` codes (D-C6) |
| `quantity` | `numeric(12,2)` | no | Available now, `>= 0`, already net of reservations (D-C7, D-C12). The type **rounds** a third decimal: the API rejects it first (`400`) |
| `price_cents` | `bigint` | no | Price per `unit` in centavos (ADR-012), 1 … 999 999 999 999. Currency is always COP: no column |
| `municipality` | `text` | no | As typed, 1–100 after trim |
| `municipality_key` | `text` | no | `municipality` in lower case without accents, written by the API; E-10 filters on it |
| `photo_url` | `text` | yes | `/media/{key}` or `NULL`, never `''` (D-C8) |
| `status` | `text` | no | `ACTIVE` or `OUT_OF_STOCK`. `ACTIVE` requires `quantity > 0` |
| `created_at`, `updated_at` | `timestamptz` | no | `updated_at` is set by the API on every change |
| `deleted_at` | `timestamptz` | yes | `NULL` = alive. A date = deleted, terminal and invisible to the API (D-C5) |

### `stock_reservation` — stock held by a pending payment

| Column | Type | Null | Meaning and rules |
|---|---|---|---|
| `transaction_id` | `uuid` | no | Primary key, sent by transactions: the idempotency key of I-03 |
| `product_id` | `uuid` | no | `fk_stock_reservation_product`, `ON DELETE RESTRICT` |
| `producer_id`, `product_name`, `unit` | — | no | Snapshots taken at reservation time |
| `quantity` | `numeric(12,2)` | no | Reserved, `> 0` |
| `unit_price_cents` | `bigint` | no | Price at reservation time; transactions computes the amount from it (D-C11) |
| `remaining_quantity` | `numeric(12,2)` | no | Product quantity right after the reservation, so a retry answers the same body |
| `created_at` | `timestamptz` | no | |
| `released_at` | `timestamptz` | yes | `NULL` = holding. A date = given back once (I-04 or `TransactionFailed`) |

### `idempotency_key` — the key each product was created with (D-C35)

| Column | Type | Null | Meaning and rules |
|---|---|---|---|
| `owner_id` | `uuid` | no | JWT `sub`. Primary key with `key_value` |
| `key_value` | `text` | no | The `Idempotency-Key` header, 8–128 characters |
| `product_id` | `uuid` | no | `fk_idempotency_key_product`, `ON DELETE RESTRICT` |
| `created_at` | `timestamptz` | no | For a future purge (technical debt) |

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
