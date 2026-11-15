-- catalog_app is the only user catalog-api connects with (Anexo J.7).
-- It must already exist: market-agri-infra creates it before any migration.
GRANT catalog_writer TO catalog_app;
