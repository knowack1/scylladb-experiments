-- ScyllaDB FTS demo — stop-word removal.
USE wikipedia;

-- Stop-word removal. English stop words (the, a, an, of, ...) are dropped by the
-- analyzer, so 'the database' is reduced to 'database' — the identical ranked set
-- to the bare 'database' query in 03_relevance_ranking.cql. The added 'the' is noise.
SELECT article_id, title FROM articles WHERE BM25(article, 'the database') > 0 ORDER BY BM25(article, 'the database') LIMIT 10;
