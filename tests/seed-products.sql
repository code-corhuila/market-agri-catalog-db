-- HU-CAT-005 · D-20: demo products for dev and qa, so the catalog can be browsed (E2E flow 1).
--   * at least 21 live products: the portal asks for 20 per page, flow 1 opens the next one
--   * owned only by the seed producers, with the same UUIDs as the seed users of auth-db
--   * the five products of the front's simulated mode, with their ids and prices
--   * one product at 8 500 000 centavos ($ 85.000), the price flow 1 looks for
--   * the seed is idempotent: running it again changes nothing (Anexo A, rule 11)
-- db-ci builds the schema without --contexts, so the dev/qa seeds are applied. Rolled back.
\set ON_ERROR_STOP on
BEGIN;

CREATE FUNCTION pg_temp.expect(ok boolean, what text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    IF ok IS NOT TRUE THEN
        RAISE EXCEPTION 'FAIL: %', what;
    END IF;
    RAISE NOTICE 'ok: %', what;
END $$;

CREATE TEMP TABLE seed_producer (id uuid PRIMARY KEY, name text NOT NULL);
INSERT INTO seed_producer VALUES
    ('0b6f2c7e-4a51-4c1e-9d0e-2f1c3a7b9e10', 'Ana Ruiz'),
    ('3c2b1a09-8f7e-4d6c-9b5a-4e3d2c1b0a99', 'Luis Gómez');

-- 1. Enough products for two pages.
SELECT pg_temp.expect(
    (SELECT count(*) FROM catalog.product WHERE deleted_at IS NULL) >= 21,
    'at least 21 live products (two pages of 20)');

-- 2. Every product belongs to a seed producer, with the name of that producer.
SELECT pg_temp.expect(
    NOT EXISTS (SELECT 1 FROM catalog.product p
                LEFT JOIN seed_producer s ON s.id = p.producer_id AND s.name = p.producer_name
                WHERE s.id IS NULL),
    'every product belongs to a seed producer (UUIDs of the seed users of auth-db)');
SELECT pg_temp.expect(
    (SELECT count(DISTINCT producer_id) FROM catalog.product) = 2,
    'both seed producers have products');

-- 3. The simulated products of the front exist with the same id, name and price.
SELECT pg_temp.expect(
    (SELECT count(*) FROM catalog.product p
     JOIN (VALUES
         ('5e1f0c2a-7b3d-4e8f-9a6b-000000000001'::uuid, 'Café especial de altura', 18500000::bigint),
         ('5e1f0c2a-7b3d-4e8f-9a6b-000000000002'::uuid, 'Plátano hartón',           4500000::bigint),
         ('5e1f0c2a-7b3d-4e8f-9a6b-000000000003'::uuid, 'Cacao en grano',           1400000::bigint),
         ('5e1f0c2a-7b3d-4e8f-9a6b-000000000004'::uuid, 'Lulo',                      600000::bigint),
         ('5e1f0c2a-7b3d-4e8f-9a6b-000000000005'::uuid, 'Queso campesino',          1200000::bigint)
     ) AS front(id, name, price_cents)
       ON front.id = p.id AND front.name = p.name AND front.price_cents = p.price_cents) = 5,
    'the five products of the simulated mode, same id, name and price');

-- 4. What flow 1 shows: a price of $ 85.000 and a product without stock.
SELECT pg_temp.expect(
    EXISTS (SELECT 1 FROM catalog.product WHERE price_cents = 8500000 AND status = 'ACTIVE'),
    'an available product at 8 500 000 centavos ($ 85.000)');
SELECT pg_temp.expect(
    EXISTS (SELECT 1 FROM catalog.product WHERE status = 'OUT_OF_STOCK'),
    'at least one product out of stock');

-- 5. Idempotent: the same seed again leaves the same rows.
CREATE TEMP TABLE before_rerun AS SELECT * FROM catalog.product;
-- db-ci feeds this file to psql from the repository root, so the path starts there.
\i 02_dml/00_inserts/001_seed_products.sql
SELECT pg_temp.expect(
    NOT EXISTS ((SELECT id, name, quantity, price_cents, status FROM catalog.product
                 EXCEPT SELECT id, name, quantity, price_cents, status FROM before_rerun)
                UNION ALL
                (SELECT id, name, quantity, price_cents, status FROM before_rerun
                 EXCEPT SELECT id, name, quantity, price_cents, status FROM catalog.product)),
    'running the seed again changes nothing (INSERT ... ON CONFLICT ... DO UPDATE)');

ROLLBACK;
\echo 'seed-products: all checks passed'
