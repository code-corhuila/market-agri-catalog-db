-- The database half of idempotent creation (D-C35, Anexo A, Anexo C 5.3.8): E-13 inserts the
-- product and its key in ONE transaction; if the key already exists it rolls back and answers
-- 200 with the original product.
CREATE TABLE catalog.idempotency_key (
    owner_id   uuid        NOT NULL,  -- JWT sub: two producers may send the same key by chance
    key_value  text        NOT NULL,  -- the Idempotency-Key header
    product_id uuid        NOT NULL,  -- the product created with this key
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_idempotency_key PRIMARY KEY (owner_id, key_value),
    CONSTRAINT chk_idempotency_key_key_value_length CHECK (char_length(key_value) BETWEEN 8 AND 128)
);
