-- ScyllaDB FTS demo — Milestone 2: restrict by article id (rejected today).
USE wikipedia;

-- Scoping to one article by its partition key. FAILS with the same "additional
-- WHERE restrictions" error — the partition key is no exception. (The id below is
-- the Theory of relativity article.)
SELECT article_id, title FROM articles WHERE BM25(article, 'relativity') > 0 AND article_id = a0000000-0000-4000-8000-000000000002 ORDER BY BM25(article, 'relativity') LIMIT 10;
