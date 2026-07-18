-- ScyllaDB FTS demo — full-text index.
--
-- The fulltext index lives on the `article` text column of wikipedia.articles.
-- It is only supported on text / varchar / ascii columns.
--
-- After creation the vector-store discovers the index via CDC and performs a
-- full base-table scan; the index reports SERVING once that scan completes.
-- Until SERVING, queries return an error (the vector-store returns 503).

CREATE CUSTOM INDEX IF NOT EXISTS articles_body_fts ON wikipedia.articles(article) USING 'fulltext_index';
