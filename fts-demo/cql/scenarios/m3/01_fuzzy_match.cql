-- ScyllaDB FTS demo — Milestone 3: fuzzy match (parsed, not enabled today).
USE wikipedia;

-- Fuzzy (edit distance): 'reletivity~1' should match 'relativity' within one edit.
-- The ~N operator is parsed by Tantivy but not enabled until Milestone 3, so today
-- this matches nothing.
SELECT article_id, title FROM articles WHERE BM25(article, 'reletivity~1') > 0 ORDER BY BM25(article, 'reletivity~1') LIMIT 10;
