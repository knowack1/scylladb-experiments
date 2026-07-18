-- ScyllaDB FTS demo — Milestone 3: prefix / wildcard (parsed, not enabled today).
USE wikipedia;

-- Prefix / wildcard: 'photo*' should match photosynthesis, etc. Only trailing
-- wildcards are planned, and not before Milestone 3, so this matches nothing today.
SELECT article_id, title FROM articles WHERE BM25(article, 'photo*') > 0 ORDER BY BM25(article, 'photo*') LIMIT 10;
