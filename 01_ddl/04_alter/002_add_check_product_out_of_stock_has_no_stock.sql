-- FR-013 and INV-009 (api-contract amendment 2026-10-10): the status is derived from the
-- quantity. A3 enforced one half (ACTIVE => quantity > 0); this adds the other half, so
-- OUT_OF_STOCK with stock left is no longer possible. The comment of chk_product_active_has_stock
-- in 001_create_product.sql predates the amendment and stays: an applied changeset is never edited.
ALTER TABLE catalog.product
    ADD CONSTRAINT chk_product_out_of_stock_has_no_stock CHECK (status <> 'OUT_OF_STOCK' OR quantity = 0);
