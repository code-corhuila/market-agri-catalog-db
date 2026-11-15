ALTER TABLE catalog.idempotency_key   DROP CONSTRAINT IF EXISTS fk_idempotency_key_product;
ALTER TABLE catalog.stock_reservation DROP CONSTRAINT IF EXISTS fk_stock_reservation_product;
