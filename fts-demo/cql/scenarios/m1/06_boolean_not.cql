-- ScyllaDB FTS demo — boolean NOT.
USE wikipedia;

-- Boolean NOT — the classic disambiguation query. 'python' matches both the
-- programming language and the snake genus; excluding 'snake' drops the reptile
-- article, leaving the Python language and Guido van Rossum articles.
SELECT article_id, title FROM articles WHERE BM25(article, 'python NOT snake') > 0 ORDER BY BM25(article, 'python NOT snake') LIMIT 10;
