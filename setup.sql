CREATE USER benchmarksql WITH ENCRYPTED PASSWORD 'changeme';
CREATE DATABASE benchmarksql OWNER benchmarksql;
GRANT ALL ON SCHEMA public TO benchmarksql;
