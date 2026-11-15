-- Demo products for dev and qa only (D-20): main starts with an empty catalog.
-- Producers are the seed producers of auth-db, with the same UUIDs (the front's simulated mode
-- uses them too); the first five products are the simulated ones, same id, name and price.
-- 21 products: the portal asks for 20 per page and E2E flow 1 opens the next one.
-- Money in integer centavos (ADR-029): 8500000 is $ 85.000. Status follows the quantity
-- (INV-009) and municipality_key is the municipality in lower case without accents (D-16).
-- Idempotent (Anexo A, rule 11): running it again leaves the same rows.
WITH producer (producer, producer_id, producer_name) AS (VALUES
    ('ana',  '0b6f2c7e-4a51-4c1e-9d0e-2f1c3a7b9e10'::uuid, 'Ana Ruiz'),
    ('luis', '3c2b1a09-8f7e-4d6c-9b5a-4e3d2c1b0a99'::uuid, 'Luis Gómez')
), seed (id, name, category, unit, quantity, price_cents, municipality, municipality_key, producer, created_at) AS (VALUES
    -- the first row fixes the types of every column
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000001'::uuid, 'Café especial de altura',  'CAFE',               'ARROBA',    12.5::numeric(12,2),     18500000::bigint,    'Garzón',      'garzon',         'ana',    '2026-10-01T14:00:00Z'::timestamptz),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000002', 'Plátano hartón',           'FRUTAS',             'CANASTA',   30,        4500000,    'Garzón',      'garzon',         'ana',    '2026-10-02T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000003', 'Cacao en grano',           'CACAO',              'KILOGRAMO', 80,        1400000,    'Neiva',       'neiva',          'luis',   '2026-10-03T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000004', 'Lulo',                     'FRUTAS',             'KILOGRAMO', 0,          600000,    'Pitalito',    'pitalito',       'luis',   '2026-10-04T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000005', 'Queso campesino',          'LACTEOS',            'LIBRA',     20,        1200000,    'La Plata',    'la plata',       'ana',    '2026-10-05T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000006', 'Granadilla',               'FRUTAS',             'CANASTA',   15,        6000000,    'Pitalito',    'pitalito',       'luis',   '2026-10-06T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000007', 'Tomate chonto',            'HORTALIZAS',         'CAJA',      25,        7000000,    'Gigante',     'gigante',        'ana',    '2026-10-07T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000008', 'Arveja verde',             'VERDURAS',           'BULTO',     10,       16000000,    'La Plata',    'la plata',       'ana',    '2026-10-08T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000009', 'Papa pastusa',             'TUBERCULOS',         'BULTO',     18,       12000000,    'San Agustín', 'san agustin',    'luis',   '2026-10-09T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000010', 'Fríjol cargamanto',        'GRANOS_Y_CEREALES',  'KILOGRAMO', 150,        900000,    'Acevedo',     'acevedo',        'luis',   '2026-10-10T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000011', 'Maíz amarillo',            'GRANOS_Y_CEREALES',  'ARROBA',    40,        4200000,    'Campoalegre', 'campoalegre',    'ana',    '2026-10-11T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000012', 'Cilantro',                 'HIERBAS_AROMATICAS', 'MANOJO',    60,         150000,    'Rivera',      'rivera',         'ana',    '2026-10-12T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000013', 'Leche cruda',              'LACTEOS',            'LITRO',     0,          220000,    'Palermo',     'palermo',        'luis',   '2026-10-13T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000014', 'Huevos criollos',          'OTROS',              'DOCENA',    35,        1500000,    'Timaná',      'timana',         'ana',    '2026-10-14T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000015', 'Café pergamino seco',      'CAFE',               'ARROBA',    22.75,    32000000,    'Pitalito',    'pitalito',       'luis',   '2026-10-15T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000016', 'Yuca',                     'TUBERCULOS',         'ARROBA',    28,        3800000,    'Aipe',        'aipe',           'ana',    '2026-10-16T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000017', 'Cebolla larga',            'VERDURAS',           'ARROBA',    14,        5500000,    'Algeciras',   'algeciras',      'luis',   '2026-10-17T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000018', 'Aguacate Hass',            'FRUTAS',             'KILOGRAMO', 90.5,       750000,    'Isnos',       'isnos',          'luis',   '2026-10-18T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000019', 'Pimentón',                 'HORTALIZAS',         'LIBRA',     45,         350000,    'Tarqui',      'tarqui',         'ana',    '2026-10-19T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000020', 'Hierbabuena',              'HIERBAS_AROMATICAS', 'MANOJO',    50,         200000,    'Yaguará',     'yaguara',        'ana',    '2026-10-20T14:00:00Z'),
    ('5e1f0c2a-7b3d-4e8f-9a6b-000000000021', 'Mora de Castilla',         'FRUTAS',             'CANASTA',   16,        8500000,    'Gigante',     'gigante',        'ana',    '2026-10-21T14:00:00Z')
)
INSERT INTO catalog.product
    (id, producer_id, producer_name, name, category, unit, quantity, price_cents,
     municipality, municipality_key, status, created_at, updated_at)
SELECT seed.id, producer.producer_id, producer.producer_name, seed.name, seed.category, seed.unit,
       seed.quantity, seed.price_cents, seed.municipality, seed.municipality_key,
       CASE WHEN seed.quantity > 0 THEN 'ACTIVE' ELSE 'OUT_OF_STOCK' END,
       seed.created_at, seed.created_at
FROM seed JOIN producer USING (producer)
ON CONFLICT (id) DO UPDATE SET
    producer_id      = EXCLUDED.producer_id,
    producer_name    = EXCLUDED.producer_name,
    name             = EXCLUDED.name,
    category         = EXCLUDED.category,
    unit             = EXCLUDED.unit,
    quantity         = EXCLUDED.quantity,
    price_cents      = EXCLUDED.price_cents,
    municipality     = EXCLUDED.municipality,
    municipality_key = EXCLUDED.municipality_key,
    status           = EXCLUDED.status,
    created_at       = EXCLUDED.created_at,
    updated_at       = EXCLUDED.updated_at,
    deleted_at       = NULL;
