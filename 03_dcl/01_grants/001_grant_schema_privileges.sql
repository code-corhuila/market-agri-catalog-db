-- Permissions only on the catalog schema (Anexo J.3): no role of this domain
-- receives anything on another schema.
GRANT USAGE ON SCHEMA catalog TO catalog_reader, catalog_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA catalog TO catalog_reader;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA catalog TO catalog_writer;

-- Tables created later by the migrating user (the administrator) inherit the
-- same permissions without a new grant.
ALTER DEFAULT PRIVILEGES IN SCHEMA catalog GRANT SELECT ON TABLES TO catalog_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA catalog GRANT SELECT, INSERT, UPDATE ON TABLES TO catalog_writer;
