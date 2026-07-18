-- ScyllaDB vector-search demo — articles table (Wikipedia-style corpus).
--
-- This demo is pure semantic search: `embedding` is the ANN-indexed column, an
-- all-MiniLM-L6-v2 (384-dim) vector of the article text. `title` is carried for
-- DISPLAY of results only. article_id is the sole partition key (pure identity).
CREATE TABLE IF NOT EXISTS wikipedia.articles (article_id uuid PRIMARY KEY, title text, article text, embedding vector<float, 384>);
