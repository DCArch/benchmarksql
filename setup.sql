-- Create DCSim extension in template1 so all new databases inherit it
\c template1
CREATE EXTENSION IF NOT EXISTS dcsim;

-- Now create the benchmarksql database (it will inherit the extension)
\c postgres
CREATE USER benchmarksql WITH ENCRYPTED PASSWORD 'changeme';
CREATE DATABASE benchmarksql OWNER benchmarksql;
GRANT ALL ON SCHEMA public TO benchmarksql;
