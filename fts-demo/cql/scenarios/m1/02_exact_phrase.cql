-- ScyllaDB FTS demo — exact phrase search.
USE wikipedia;

-- Exact phrase. 'relativity' alone appears in several physics articles, but the
-- phrase only matches where those three tokens are adjacent — the Theory of
-- relativity and Black hole articles, not the Einstein one ('relativity theory').
SELECT article_id, title, author FROM articles WHERE BM25(article, '"theory of relativity"') > 0 ORDER BY BM25(article, '"theory of relativity"') LIMIT 10;
