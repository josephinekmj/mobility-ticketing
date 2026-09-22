# MobilityTicketing: Lectures 1-4

This repository is one cumulative PostgreSQL project for the first four
lectures. It models route maintenance, scheduled trips, ticket products,
users, tickets, payments, and validations, then adds database integrity,
reporting programmability, and a rolling product-identity migration.

The transactional tables remain the source of truth. Reporting strategies and
migration experiments are kept separate from setup files so their behavior can
be compared and verified explicitly.

## Start the database

Requirements:

- Docker Desktop with Compose

Start PostgreSQL:

```bash
docker compose up -d
```

The database is available at `localhost:5432` with database `mobility`, user `mobility`, and password `mobility`.

To stop it:

```bash
docker compose down
```

The PostgreSQL entrypoint only executes files directly under its init directory;
it does not recurse into this repository's `init/`, `migrations/`, or
`experiments/` folders. Apply files explicitly in dependency order:

```bash
for file in \
	database/postgres/init/001_relational_baseline.sql \
	database/postgres/init/002_seed.sql \
	database/postgres/init/010_ticketing_draft.sql \
	database/postgres/init/011_ticketing_seed.sql \
	database/postgres/init/012_legacy_trip_capacity.sql \
	database/postgres/migrations/011_ticketing_integrity.sql \
	database/postgres/migrations/012_ticket_references.sql \
	database/postgres/migrations/013_ticket_identity_and_validity.sql \
	database/postgres/migrations/014_prices_and_currency.sql \
	database/postgres/migrations/015_payment_references.sql \
	database/postgres/migrations/016_validation_ticket_identity.sql \
	database/postgres/migrations/017_status_integrity.sql \
	database/postgres/migrations/018_supported_currency.sql \
	database/postgres/migrations/020_reporting_objects.sql \
	database/postgres/migrations/030_expand_product_identity.sql \
	database/postgres/migrations/031_backfill_ticket_product.sql
do
	docker compose exec -T postgres psql -U mobility -d mobility \
		-v ON_ERROR_STOP=1 -f "/docker-entrypoint-initdb.d/${file#database/postgres/}"
done
```

The contract migration `032_contract_product_identity.sql` is a later
deployment and must only be applied after compatibility readers/writers have
been retired and catalog dependencies have been checked. Do not use a volume
reset casually; `docker compose down -v` deletes this project's database data.

## Verification

Lecture 1 workload queries are in `database/postgres/003_queries.sql`. Run
them with representative parameters and record results. Expected-success
verification uses `-v ON_ERROR_STOP=1`.

The original Lecture 2 negative checks are in
`database/postgres/experiments/constraints_should_fail.sql`; run them
separately against the pre-contract schema. The maintained post-contract
checks are in `database/postgres/experiments/lecture02_constraints.sql`.
PostgreSQL rejection by a named constraint is expected evidence, not an
unexpected test failure. The complete invariant ownership catalogue is in
`docs/lecture02.md`.

Lecture 3 reporting definitions and comparison are documented in
`docs/lecture03.md`; run `database/postgres/experiments/lecture03_reporting.sql`
after migration `020_reporting_objects.sql`.

Lecture 4 product identity is documented in `docs/lecture04.md`; run
`database/postgres/experiments/lecture04_product_identity.sql` for the isolated
expand/backfill/NOT NULL-failure evidence. Apply `032_contract_product_identity.sql`
only after its stated preconditions are satisfied.

The complete static audit is in `docs/lecture-audit.md`.

The original Lecture 1 slice intentionally excludes MongoDB, Redis, queues,
payment logic, validation logic, reporting tables, and performance indexes.
Later lecture work in this same repository adds the ticketing, reporting, and
identity-migration objects documented above.

## Project structure

- `compose.yaml`: PostgreSQL 17 infrastructure.
- `database/postgres/init/`: baseline schema and deterministic seed files.
- `database/postgres/migrations/`: ordered integrity, reporting, and product-identity changes.
- `database/postgres/queries/`: reusable reporting queries.
- `database/postgres/experiments/`: expected failures and isolated behavior demonstrations.
- `docs/`: domain model, lab brief, audit, and Lecture 3-4 design notes.
