-- ScyllaDB FTS demo — punctuation tokenization.
USE wikipedia;

-- Punctuation is a token delimiter. The ScyllaDB article says 'a wide-column
-- store built for high-throughput, low-latency workloads' — the hyphens and
-- comma split it into wide / column / high / throughput / low / latency.
-- A mid-word hyphen splits, so 'wide' (from 'wide-column') matches.
SELECT article_id, title FROM articles WHERE BM25(article, 'wide') > 0 ORDER BY BM25(article, 'wide') LIMIT 10;

-- The other half of the hyphenated word matches too: 'column' (from 'wide-column').
SELECT article_id, title FROM articles WHERE BM25(article, 'column') > 0 ORDER BY BM25(article, 'column') LIMIT 10;

-- Trailing punctuation is stripped: 'throughput' matches 'high-throughput,'.
SELECT article_id, title FROM articles WHERE BM25(article, 'throughput') > 0 ORDER BY BM25(article, 'throughput') LIMIT 10;
