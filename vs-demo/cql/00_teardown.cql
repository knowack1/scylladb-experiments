-- ScyllaDB vector-search demo — teardown.
--
-- Dropping the keyspace removes the table and its vector index too, but we drop
-- the index and table first so re-running is explicit and order-safe.
DROP INDEX IF EXISTS wikipedia.articles_vec_ann;
DROP TABLE IF EXISTS wikipedia.articles;
DROP KEYSPACE IF EXISTS wikipedia;
