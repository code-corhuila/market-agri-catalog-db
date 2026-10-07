-- Roles are NOLOGIN: they only carry permissions. The login user catalog_app is
-- created by market-agri-infra (postgres/init/01-instance.sh) from a secret and
-- receives one of these roles in 01_grants. No password lives in this repository.
-- Role names are global to the instance, hence the catalog_ prefix.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'catalog_reader') THEN
        CREATE ROLE catalog_reader NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'catalog_writer') THEN
        CREATE ROLE catalog_writer NOLOGIN;
    END IF;
END
$$;
