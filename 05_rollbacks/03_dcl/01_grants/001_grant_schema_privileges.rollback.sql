ALTER DEFAULT PRIVILEGES IN SCHEMA catalog REVOKE ALL ON TABLES FROM catalog_reader, catalog_writer;
REVOKE ALL ON ALL TABLES IN SCHEMA catalog FROM catalog_reader, catalog_writer;
REVOKE USAGE ON SCHEMA catalog FROM catalog_reader, catalog_writer;
