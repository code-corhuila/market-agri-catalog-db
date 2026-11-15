-- Stock taken by a pending payment (I-03) and given back at most once (I-04).
-- The row freezes what I-03 must answer again on a retry: the same body, even if the
-- product changed its name or price afterwards.
CREATE TABLE catalog.stock_reservation (
    transaction_id     uuid          NOT NULL,  -- sent by the caller: the idempotency key of I-03
    product_id         uuid          NOT NULL,
    producer_id        uuid          NOT NULL,  -- snapshot
    product_name       text          NOT NULL,  -- snapshot for the transaction
    unit               text          NOT NULL,  -- snapshot
    quantity           numeric(12,2) NOT NULL,
    unit_price_cents   bigint        NOT NULL,  -- price at reservation time: transactions computes the amount from it
    remaining_quantity numeric(12,2) NOT NULL,  -- product quantity right after this reservation
    created_at         timestamptz   NOT NULL DEFAULT now(),
    released_at        timestamptz,             -- NULL = holding the stock; a date = given back (I-04, TransactionFailed)

    CONSTRAINT pk_stock_reservation PRIMARY KEY (transaction_id),
    CONSTRAINT chk_stock_reservation_product_name_length CHECK (char_length(btrim(product_name)) BETWEEN 1 AND 150),
    CONSTRAINT chk_stock_reservation_unit                CHECK (unit IN (
        'KILOGRAMO', 'LIBRA', 'ARROBA', 'BULTO', 'CANASTA',
        'CAJA', 'DOCENA', 'MANOJO', 'LITRO', 'UNIDAD')),
    CONSTRAINT chk_stock_reservation_quantity_positive   CHECK (quantity > 0),
    CONSTRAINT chk_stock_reservation_unit_price_cents    CHECK (unit_price_cents BETWEEN 1 AND 999999999999),
    CONSTRAINT chk_stock_reservation_remaining_quantity  CHECK (remaining_quantity >= 0),
    CONSTRAINT chk_stock_reservation_released_after      CHECK (released_at IS NULL OR released_at >= created_at)
);
