-- Each index names the query it serves (Anexo A, rule 3). The tables are new and empty,
-- so CONCURRENTLY is not needed (rule 14). Deleted products are never listed: partial indexes.

-- E-10 without filters: ORDER BY created_at DESC, id
CREATE INDEX idx_product_created_at_id
    ON catalog.product (created_at DESC, id) WHERE deleted_at IS NULL;

-- E-10 ?category=
CREATE INDEX idx_product_category_created_at_id
    ON catalog.product (category, created_at DESC, id) WHERE deleted_at IS NULL;

-- E-10 ?municipality= (compared through municipality_key)
CREATE INDEX idx_product_municipality_key_created_at_id
    ON catalog.product (municipality_key, created_at DESC, id) WHERE deleted_at IS NULL;

-- E-12: the producer's own products
CREATE INDEX idx_product_producer_id_created_at_id
    ON catalog.product (producer_id, created_at DESC, id) WHERE deleted_at IS NULL;

-- Foreign key columns (rule 3)
CREATE INDEX idx_stock_reservation_product_id ON catalog.stock_reservation (product_id);
CREATE INDEX idx_idempotency_key_product_id   ON catalog.idempotency_key (product_id);
