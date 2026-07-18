-- ScyllaDB FTS demo — boolean mixed with grouping.
USE wikipedia;

-- Boolean mixed — AND / OR / NOT with grouping in one query. Of the two gas
-- giants, keep the one that is a 'planet' but excludes 'rings' — Saturn is
-- dropped for its rings, leaving Jupiter.
SELECT article_id, title FROM articles WHERE BM25(article, '(jupiter OR saturn) AND planet NOT rings') > 0 ORDER BY BM25(article, '(jupiter OR saturn) AND planet NOT rings') LIMIT 10;
