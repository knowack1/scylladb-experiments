# ScyllaDB Search — short runbook

Commands only. Run `cqlsh` from the `hybrid-demo/` directory. For the full
walkthrough, see [`demo.md`](demo.md).

```bash
cd hybrid-demo
cqlsh
```

## Setup

Start clean.

```sql
DROP KEYSPACE IF EXISTS blog;
```

Create the keyspace (tablets) and switch to it.

```sql
CREATE KEYSPACE blog;
USE blog;
```

Create the table: id, article text, and the article's embedding.

```sql
CREATE TABLE articles (article_id uuid PRIMARY KEY, article text, embedding vector<float, 384>);
```

Load 22 articles with precomputed embeddings.

```
SOURCE 'cql/data_seed.cql';
```

Check the rows.

```sql
SELECT article_id, article FROM articles;
```

Create the fulltext and vector indexes — wait a few seconds for `SERVING`.

```sql
CREATE CUSTOM INDEX articles_body_fts ON articles(article) USING 'fulltext_index';
CREATE CUSTOM INDEX articles_embedding_ann ON articles(embedding) USING 'vector_index' WITH OPTIONS = {'similarity_function': 'cosine'};
```

## Part 1 — Full-text search

Term search: every article that mentions `latency`.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'latency') > 0 ORDER BY BM25(article, 'latency') LIMIT 10;
```

Case folding: `LATENCY` returns the same rows.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'LATENCY') > 0 ORDER BY BM25(article, 'LATENCY') LIMIT 10;
```

Exact phrase: words adjacent and in order — one row.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, '"tail latency"') > 0 ORDER BY BM25(article, '"tail latency"') LIMIT 10;
```

Loose terms: any of the words — three rows.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'tail latency') > 0 ORDER BY BM25(article, 'tail latency') LIMIT 10;
```

Relevance ranking: more mentions of `database`, higher rank.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'database') > 0 ORDER BY BM25(article, 'database') LIMIT 5;
```

`AND` narrows: 5 → 2 → 1 (ScyllaDB).

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'database AND distributed') > 0 ORDER BY BM25(article, 'database AND distributed') LIMIT 10;
SELECT article_id, article FROM articles WHERE BM25(article, 'database AND distributed AND scales') > 0 ORDER BY BM25(article, 'database AND distributed AND scales') LIMIT 10;
```

`OR` widens: 1 → 2.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'tcp') > 0 ORDER BY BM25(article, 'tcp') LIMIT 10;
SELECT article_id, article FROM articles WHERE BM25(article, 'tcp OR udp') > 0 ORDER BY BM25(article, 'tcp OR udp') LIMIT 10;
```

`NOT` excludes: three kinds of `kernel`, minus the GPU one.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'kernel') > 0 ORDER BY BM25(article, 'kernel') LIMIT 10;
SELECT article_id, article FROM articles WHERE BM25(article, 'kernel NOT gpu') > 0 ORDER BY BM25(article, 'kernel NOT gpu') LIMIT 10;
```

Grouping: all operators in one query — TCP only.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, '(tcp OR udp) AND packet NOT handshake') > 0 ORDER BY BM25(article, '(tcp OR udp) AND packet NOT handshake') LIMIT 10;
```

Highlighting: matched words wrapped in `<b>…</b>`.

```sql
SELECT article_id, BM25_HIGHLIGHT(article, 'tail latency') AS excerpt FROM articles WHERE BM25(article, 'tail latency') > 0 ORDER BY BM25(article, 'tail latency') LIMIT 10;
```

Highlighting the query used in Parts 2 and 3: ScyllaDB ranks first by keywords.

```sql
SELECT article_id, BM25_HIGHLIGHT(article, 'fast database for low-latency workloads') AS excerpt FROM articles WHERE BM25(article, 'fast database for low-latency workloads') > 0 ORDER BY BM25(article, 'fast database for low-latency workloads') LIMIT 5;
```

No shared words, no rows — the gap vector search fills.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'software for storing and querying data') > 0 ORDER BY BM25(article, 'software for storing and querying data') LIMIT 5;
```

## Part 2 — Vector search

Search by meaning: the relational database ranks first, ScyllaDB second.

```
-- [...] = embedding of the original text: "fast database for low-latency workloads"
SOURCE 'cql/vector/01_low_latency_database.cql';
```

## Part 3 — Hybrid search

Both searches fused by rank (RRF), with highlighting: ScyllaDB ranks first.

```
-- [...] = embedding of the original text: "fast database for low-latency workloads"
SOURCE 'cql/hybrid/01_low_latency_database.cql';
```

## Teardown

Drop everything.

```sql
DROP KEYSPACE IF EXISTS blog;
```
