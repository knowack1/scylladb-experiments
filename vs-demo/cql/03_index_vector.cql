-- ScyllaDB vector-search demo — vector (ANN) index.
--
-- The vector index lives on the `embedding` column of wikipedia.articles. It is
-- only supported on a fixed-dimension vector column (here vector<float, 384>).
--
-- After creation the vector-store discovers the index via CDC and performs a
-- full base-table scan; the index reports SERVING once that scan completes.
-- Until SERVING, queries return an error (the vector-store returns 503).

CREATE CUSTOM INDEX IF NOT EXISTS articles_vec_ann ON wikipedia.articles(embedding) USING 'vector_index';
