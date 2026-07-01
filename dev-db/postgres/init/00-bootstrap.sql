\connect querypod_lab

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'querypod') THEN
    CREATE ROLE querypod LOGIN PASSWORD 'querypod';
  END IF;
END $$;

GRANT ALL PRIVILEGES ON DATABASE querypod_lab TO querypod;
