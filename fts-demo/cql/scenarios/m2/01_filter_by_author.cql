-- ScyllaDB FTS demo — Milestone 2: filter by author (rejected today).
USE wikipedia;

-- Filter + full-text: relativity articles written by one author. FAILS with:
--   "Full-text search queries do not support additional WHERE restrictions"
-- 'relativity' matches three articles (two by John Smith, one by Wei Chen); the
-- author predicate would narrow them, but it cannot be combined with BM25 today.
SELECT article_id, title, author FROM articles WHERE BM25(article, 'relativity') > 0 AND author = 'John Smith' ORDER BY BM25(article, 'relativity') LIMIT 10;
