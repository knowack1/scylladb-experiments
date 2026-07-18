-- ScyllaDB FTS demo — boolean OR.
USE wikipedia;

-- Boolean OR — either term. Broadens to every article mentioning Jupiter or
-- Saturn (the two gas-giant articles).
SELECT article_id, title FROM articles WHERE BM25(article, 'jupiter OR saturn') > 0 ORDER BY BM25(article, 'jupiter OR saturn') LIMIT 10;
