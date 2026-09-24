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
CREATE CUSTOM INDEX articles_body_fts ON articles(article) USING 'fulltext_index' WITH OPTIONS = {'analyzer': 'standard', 'positions': 'true'};
CREATE CUSTOM INDEX articles_embedding_ann ON articles(embedding) USING 'vector_index';
```

## Part 1 — Full-text search

One word: five database articles, ranked by how often each says `database`.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'database') > 0 ORDER BY BM25(article, 'database') LIMIT 10;
```

Two words, `OR` by default: any of them matches — seven rows, the distributed databases on top.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed database') > 0 ORDER BY BM25(article, 'distributed database') LIMIT 10;
```

Quoted phrase: the words adjacent and in order — two rows.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, '"distributed database"') > 0 ORDER BY BM25(article, '"distributed database"') LIMIT 10;
```

`AND`: both words anywhere in the article — three rows.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed AND database') > 0 ORDER BY BM25(article, 'distributed AND database') LIMIT 10;
```

One more `AND` term: only ScyllaDB is left.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed AND database AND scale') > 0 ORDER BY BM25(article, 'distributed AND database AND scale') LIMIT 10;
```

`NOT`: distributed, but not a database — tracing and Raft.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed NOT database') > 0 ORDER BY BM25(article, 'distributed NOT database') LIMIT 10;
```

Grouping: the distributed databases plus the relational one — four rows.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, '(distributed OR relational) AND database') > 0 ORDER BY BM25(article, '(distributed OR relational) AND database') LIMIT 10;
```

Highlighting: matched words wrapped in `<b>…</b>` — the query used in Parts 2 and 3; ScyllaDB ranks first by keywords.

```sql
SELECT article_id, BM25_HIGHLIGHT(article, 'fast database for low-latency workloads') AS excerpt FROM articles WHERE BM25(article, 'fast database for low-latency workloads') > 0 ORDER BY BM25(article, 'fast database for low-latency workloads') LIMIT 5;
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
