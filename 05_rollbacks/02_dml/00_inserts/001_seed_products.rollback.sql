-- Removes the 21 demo products of 001_seed_products.sql, by their fixed ids.
-- Fails on purpose (ON DELETE RESTRICT) if a seed product already has reservations or an
-- idempotency key: in qa, demo data that was used is not rolled back.
DELETE FROM catalog.product
WHERE id IN (SELECT ('5e1f0c2a-7b3d-4e8f-9a6b-' || lpad(n::text, 12, '0'))::uuid
             FROM generate_series(1, 21) AS n);
