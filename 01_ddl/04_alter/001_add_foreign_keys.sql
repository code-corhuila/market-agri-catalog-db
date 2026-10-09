-- Foreign keys inside the catalog schema only. Products are never deleted physically (D-C5),
-- so RESTRICT makes an accidental DELETE fail instead of erasing reservations and keys.
ALTER TABLE catalog.stock_reservation
    ADD CONSTRAINT fk_stock_reservation_product
    FOREIGN KEY (product_id) REFERENCES catalog.product (id) ON DELETE RESTRICT;

ALTER TABLE catalog.idempotency_key
    ADD CONSTRAINT fk_idempotency_key_product
    FOREIGN KEY (product_id) REFERENCES catalog.product (id) ON DELETE RESTRICT;
