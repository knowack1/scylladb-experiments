-- ScyllaDB FTS demo — global search.
USE wikipedia;

-- Global search: find every article that mentions photosynthesis. Returns the
-- Photosynthesis, Chlorophyll, and Oxygen articles — one query, no partition scan.
SELECT article_id, title, author FROM articles WHERE BM25(article, 'photosynthesis') > 0 ORDER BY BM25(article, 'photosynthesis') LIMIT 10;
