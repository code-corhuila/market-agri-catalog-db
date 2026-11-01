-- HU-CAT-004 · FR-013, INV-009: the product status follows the quantity.
--   quantity > 0 -> ACTIVE        (chk_product_active_has_stock, A3)
--   quantity = 0 -> OUT_OF_STOCK  (chk_product_out_of_stock_has_no_stock, A4)
-- The API writes status and quantity in the same UPDATE; the database refuses any row where
-- they disagree. Run by db-ci after the first update; everything is rolled back at the end.
\set ON_ERROR_STOP on
BEGIN;

-- Fails the run unless the statement is refused by exactly the expected CHECK.
CREATE FUNCTION pg_temp.expect_check(stmt text, expected text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    got text;
BEGIN
    EXECUTE stmt;
    RAISE EXCEPTION 'FAIL: accepted, % should refuse it: %', expected, stmt;
EXCEPTION WHEN check_violation THEN
    GET STACKED DIAGNOSTICS got = CONSTRAINT_NAME;
    IF got IS DISTINCT FROM expected THEN
        RAISE EXCEPTION 'FAIL: refused by %, expected %: %', got, expected, stmt;
    END IF;
    RAISE NOTICE 'ok: % refuses it', expected;
END $$;

-- A valid product row with the given quantity and status.
CREATE FUNCTION pg_temp.insert_product(quantity numeric, status text) RETURNS text
LANGUAGE sql AS $$
    SELECT format(
        'INSERT INTO catalog.product (producer_id, producer_name, name, category, unit, quantity,'
        ' price_cents, municipality, municipality_key, status) VALUES (gen_random_uuid(),'
        ' %L, %L, %L, %L, %s, %s, %L, %L, %L)',
        'Ana Ruiz', 'Café pergamino seco', 'CAFE', 'ARROBA', quantity, 8500000,
        'Garzón', 'garzon', status);
$$;

-- 1. The two rows that agree are accepted.
DO $$ BEGIN EXECUTE pg_temp.insert_product(40, 'ACTIVE'); END $$;
DO $$ BEGIN EXECUTE pg_temp.insert_product(0, 'OUT_OF_STOCK'); END $$;

-- 2. Stock but OUT_OF_STOCK: refused (new in A4).
SELECT pg_temp.expect_check(pg_temp.insert_product(12.5, 'OUT_OF_STOCK'),
                            'chk_product_out_of_stock_has_no_stock');

-- 3. No stock but ACTIVE: refused (A3, kept).
SELECT pg_temp.expect_check(pg_temp.insert_product(0, 'ACTIVE'), 'chk_product_active_has_stock');

-- 4. A released reservation gives stock back: changing only the quantity is refused,
--    changing quantity and status together is accepted.
SELECT pg_temp.expect_check(
    $q$UPDATE catalog.product SET quantity = 5 WHERE status = 'OUT_OF_STOCK'$q$,
    'chk_product_out_of_stock_has_no_stock');
UPDATE catalog.product SET quantity = 5, status = 'ACTIVE' WHERE status = 'OUT_OF_STOCK';

-- 5. The last unit is sold: the same rule in the other direction.
SELECT pg_temp.expect_check(
    $q$UPDATE catalog.product SET quantity = 0 WHERE quantity = 5$q$,
    'chk_product_active_has_stock');
UPDATE catalog.product SET quantity = 0, status = 'OUT_OF_STOCK' WHERE quantity = 5;

ROLLBACK;
\echo 'product-status: all checks passed'
