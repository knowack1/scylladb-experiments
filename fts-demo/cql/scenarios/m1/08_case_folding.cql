-- ScyllaDB FTS demo — case folding (case-insensitive search).
USE wikipedia;

-- Case folding. The analyzer lowercases both the indexed text and the query, so
-- an all-caps query returns the same articles as the lowercase term in
-- 01_global_search.cql.
SELECT article_id, title FROM articles WHERE BM25(article, 'PHOTOSYNTHESIS') > 0 ORDER BY BM25(article, 'PHOTOSYNTHESIS') LIMIT 10;
