-- ScyllaDB FTS demo — teardown.
--
-- Dropping the keyspace removes the table and its fulltext index too, but we
-- drop the index and table first so re-running is explicit and order-safe.
DROP INDEX IF EXISTS wikipedia.articles_body_fts;
DROP TABLE IF EXISTS wikipedia.articles;
DROP KEYSPACE IF EXISTS wikipedia;
