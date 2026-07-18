-- ScyllaDB FTS demo — relevance ranking.
USE wikipedia;

-- Relevance ranking: a common term returns several rows, BM25-ranked. No score is
-- returned, but the order is legible from the text — the ScyllaDB and Cassandra
-- articles, which repeat 'database' most, rank on top.
SELECT article_id, title FROM articles WHERE BM25(article, 'database') > 0 ORDER BY BM25(article, 'database') LIMIT 10;
