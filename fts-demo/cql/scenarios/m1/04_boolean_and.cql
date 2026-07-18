-- ScyllaDB FTS demo — boolean AND.
USE wikipedia;

-- Boolean AND — both terms required. Narrows the database articles to the two
-- that also mention 'distributed' (ScyllaDB and Apache Cassandra).
SELECT article_id, title FROM articles WHERE BM25(article, 'database AND distributed') > 0 ORDER BY BM25(article, 'database AND distributed') LIMIT 10;
