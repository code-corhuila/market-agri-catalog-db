-- A product offered by a producer (api-contract §4.2, ProductView).
-- No foreign keys here: they go in 04_alter (Anexo A, rule 2).
CREATE TABLE catalog.product (
    id               uuid          NOT NULL DEFAULT gen_random_uuid(),
    producer_id      uuid          NOT NULL,   -- owned by auth: an id, never a foreign key (Anexo A, rule 8)
    producer_name    text          NOT NULL,   -- snapshot of the JWT name at creation (D-C31)
    name             text          NOT NULL,
    category         text          NOT NULL,
    unit             text          NOT NULL,
    quantity         numeric(12,2) NOT NULL,   -- available now, already net of reservations (D-C7, D-C12)
    price_cents      bigint        NOT NULL,   -- per unit, in minor units (ADR-012)
    municipality     text          NOT NULL,   -- as typed by the producer, shown to users
    municipality_key text          NOT NULL,   -- lower case without accents, written by the API: the filter of E-10
    photo_url        text,                     -- one photo per product (D-C8); NULL = no photo
    status           text          NOT NULL DEFAULT 'ACTIVE',
    created_at       timestamptz   NOT NULL DEFAULT now(),
    updated_at       timestamptz   NOT NULL DEFAULT now(),
    deleted_at       timestamptz,              -- NULL = alive; a date = deleted, terminal (D-C5)

    CONSTRAINT pk_product PRIMARY KEY (id),
    CONSTRAINT chk_product_producer_name_length    CHECK (char_length(btrim(producer_name)) BETWEEN 1 AND 150),
    CONSTRAINT chk_product_name_length             CHECK (char_length(btrim(name)) BETWEEN 1 AND 150),
    CONSTRAINT chk_product_category                CHECK (category IN (
        'FRUTAS', 'VERDURAS', 'HORTALIZAS', 'TUBERCULOS', 'GRANOS_Y_CEREALES',
        'CAFE', 'CACAO', 'LACTEOS', 'HIERBAS_AROMATICAS', 'OTROS')),
    CONSTRAINT chk_product_unit                    CHECK (unit IN (
        'KILOGRAMO', 'LIBRA', 'ARROBA', 'BULTO', 'CANASTA',
        'CAJA', 'DOCENA', 'MANOJO', 'LITRO', 'UNIDAD')),
    CONSTRAINT chk_product_quantity_non_negative   CHECK (quantity >= 0),
    CONSTRAINT chk_product_price_cents_range       CHECK (price_cents BETWEEN 1 AND 999999999999),
    CONSTRAINT chk_product_municipality_length     CHECK (char_length(btrim(municipality)) BETWEEN 1 AND 100),
    CONSTRAINT chk_product_municipality_key        CHECK (char_length(municipality_key) BETWEEN 1 AND 100
                                                          AND municipality_key = lower(municipality_key)),
    CONSTRAINT chk_product_photo_url               CHECK (photo_url ~ '^/media/.+'),
    CONSTRAINT chk_product_status                  CHECK (status IN ('ACTIVE', 'OUT_OF_STOCK')),
    -- E-15 (ACTIVE_REQUIRES_STOCK) and D-C12: ACTIVE always has stock; OUT_OF_STOCK may have some again
    -- after a released reservation, because restocking to ACTIVE is the owner's action (FR-013).
    CONSTRAINT chk_product_active_has_stock        CHECK (status <> 'ACTIVE' OR quantity > 0)
);
