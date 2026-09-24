# ScyllaDB Search — full-text, vector and hybrid in one table

A step-by-step, copy-paste demo over 22 short technical articles — databases,
latency, networking, kernels, replication, storage. Each article also carries a
16-dim embedding. One table, two indexes, three ways to search:

1. **Full-text search (BM25)** — lexical matching with the Lucene/Tantivy query
   syntax: terms, phrases, `AND` / `OR` / `NOT`, grouping, highlighting.
2. **Vector search (ANN)** — semantic matching: the query shares no words with the
   article, yet the right article comes back.
3. **Hybrid search (RRF)** — both at once, fused by rank, so each covers the other's
   blind spot.

Open `cqlsh` **from the `hybrid-demo/` directory** (the `SOURCE` paths below are
relative to it) and paste each block in order. After creating the indexes, wait a
few seconds for them to reach `SERVING` before running any query.

```bash
cd hybrid-demo
cqlsh
```

> **Build.** `BM25_HIGHLIGHT()`, `ANN_SCORE()`, `ANN_RANK()`, `BM25_RANK()` and
> `RRF()` come from the `hybrid-search` branch (`m-szymon/hybrid-search`), not yet
> in a release. The plain BM25 and ANN queries run on any build with full-text and
> vector search.

## 1. Start clean

Dropping the keyspace removes the table and both of its indexes.

```sql
DROP KEYSPACE IF EXISTS blog;
```

## 2. Keyspace

Create the keyspace and select it right away so every command below needs no
keyspace prefix. Both indexes need a tablets keyspace — the default here.

```sql
CREATE KEYSPACE blog;
USE blog;
```

## 3. Table

`article_id` is the sole partition key (pure identity) — a full-text or hybrid
query takes no other `WHERE` restriction. `article` is the full-text (BM25) indexed
column, `embedding` the vector (ANN) indexed column: the embedding of the article
text. For readability the demo uses 16-dim vectors — `all-MiniLM-L6-v2`
embeddings (384-dim) compressed with PCA fitted on these 22 articles. A production
application sends the model's full embedding (384 to 1536+ floats).

```sql
CREATE TABLE articles (article_id int PRIMARY KEY, article text, embedding vector<float, 16>);
```

## 4. Seed data (22 articles, embeddings inlined)

The 22 `INSERT`s live in `cql/data_seed.cql` — each carries its precomputed
embedding, so cqlsh needs no model.

```
SOURCE 'cql/data_seed.cql';
```

Confirm the 22 rows loaded (the embeddings are left out of the projection).

```sql
SELECT article_id, article FROM articles;
```

## 5. Indexes

A fulltext index on the `article` text column (default `standard` analyzer: no
stemming) and a vector index on the `embedding` column. After creation the
vector-store discovers each index via CDC and does a full base-table scan; the
index reports `SERVING` once that scan completes. Until then, queries return an
error (the vector-store returns 503) — **wait a few seconds before the next step.**

```sql
CREATE CUSTOM INDEX articles_body_fts ON articles(article) USING 'fulltext_index';
CREATE CUSTOM INDEX articles_embedding_ann ON articles(embedding) USING 'vector_index' WITH OPTIONS = {'similarity_function': 'cosine'};
```

Inspect both indexes.

```sql
DESCRIBE INDEX articles_body_fts;
DESCRIBE INDEX articles_embedding_ann;
```

---

# Part 1 — Full-text search (BM25)

The query shape: the same `BM25(column, '<query>')` in `WHERE ... > 0` and in
`ORDER BY`, and a mandatory `LIMIT`. The query string is parsed by Tantivy with
the Lucene syntax; terms are `OR`-ed by default. The `standard` analyzer is a
simple tokenizer + lowercase + English stop words — **no stemming**.

### One word — relevance ranking

Five articles mention `database`. BM25 ranks them by how often each says it —
ScyllaDB (four times), wide-column store (three), key-value store (two), then the
document and relational databases (once each, tied).

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'database') > 0 ORDER BY BM25(article, 'database') LIMIT 10;
```

### Two words — `OR` by default

Unquoted terms are `OR`-ed: an article needs only one of them. The set grows to
seven — the three distributed databases rank first (both words), then the two
other databases (`database` only), then Distributed tracing and Raft
(`distributed` only).

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed database') > 0 ORDER BY BM25(article, 'distributed database') LIMIT 10;
```

### Exact phrase

Quoted, the words must be adjacent and in order. Only ScyllaDB and the key-value
store say `distributed database`; the wide-column store says `distributed NoSQL
database` and drops out — two rows.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, '"distributed database"') > 0 ORDER BY BM25(article, '"distributed database"') LIMIT 10;
```

### Boolean AND — both words, anywhere

`AND` requires every word but not their order or distance, so the wide-column
store is back — three rows: exactly the three distributed databases.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed AND database') > 0 ORDER BY BM25(article, 'distributed AND database') LIMIT 10;
```

### Boolean AND — narrowing further

Each `AND` term can only shrink the set. Of the three distributed databases, only
ScyllaDB mentions `scale` — one row.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed AND database AND scale') > 0 ORDER BY BM25(article, 'distributed AND database AND scale') LIMIT 10;
```

### Boolean NOT — excluding

`NOT` removes matches instead of requiring them: distributed, but not a database —
Distributed tracing and Raft, the two rows the `OR` query added at the bottom.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed NOT database') > 0 ORDER BY BM25(article, 'distributed NOT database') LIMIT 10;
```

### Grouping — all operators in one query

Parentheses combine the operators: an article that is distributed or relational,
and a database. The three distributed databases plus the relational one — four
rows; the document database is the only database left out.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, '(distributed OR relational) AND database') > 0 ORDER BY BM25(article, '(distributed OR relational) AND database') LIMIT 10;
```

### Highlighting

`BM25_HIGHLIGHT()` returns a fragment of up to 150 characters with the matched
terms wrapped in `<b>…</b>` — it shows why the row matched. The markers come back
raw; escaping them is the application's job.

A hyphenated query word becomes a phrase: `low-latency` is parsed as
`"low latency"`, so only ScyllaDB matches it, and every other matched word is
marked too.

```sql
SELECT article_id, BM25_HIGHLIGHT(article, 'fast database for low-latency workloads') AS excerpt FROM articles WHERE BM25(article, 'fast database for low-latency workloads') > 0 ORDER BY BM25(article, 'fast database for low-latency workloads') LIMIT 5;
```

### Where lexical search stops

FTS matches words, not meaning. Ask a question in other words than the articles
use — `software for storing and querying data` — and it returns **no rows**, even
though five articles describe exactly that. This is the gap vector search fills.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'software for storing and querying data') > 0 ORDER BY BM25(article, 'software for storing and querying data') LIMIT 5;
```

---

# Part 2 — Vector search (ANN)

The query shape: order by the nearest neighbours of a query vector. The app embeds
the user's question with the same model as the articles; here the 16-dim query
vector is precomputed by `tools/gen_seed.py` and inlined in the query:

```sql
-- [...] = embedding of the user's original question text
SELECT article_id, ANN_SCORE(embedding, [...]) AS similarity, article FROM articles
  ORDER BY ANN(embedding, [...]) LIMIT 5;
```

`ORDER BY ANN(embedding, [...])` is the same as the standard CQL form
`ORDER BY embedding ANN OF [...]`. `ANN_SCORE()` projects the similarity the index
gave each row.

### Fast database for low-latency workloads

The same text as the highlighting query in Part 1, this time by meaning. ANN
returns what the question is about — databases, fast storage, latency — ranked by
overall similarity: the relational database first, ScyllaDB second, then Tail
latency, the document database, and NVMe drives. No keyword has to match, but the
exact words the user typed (`fast`, `low latency`, `workloads`) do not decide the
order either.

```sql
-- vector = 16-dim embedding of the original text: "fast database for low-latency workloads"
SELECT article_id, ANN_SCORE(embedding, [-0.15, 0.03, -0.29, -0.11, -0.15, -0.05, -0.06, 0.01, 0.09, -0.14, -0.10, -0.02, -0.07, 0.10, -0.04, -0.08]) AS similarity, article FROM articles ORDER BY ANN(embedding, [-0.15, 0.03, -0.29, -0.11, -0.15, -0.05, -0.06, 0.01, 0.09, -0.14, -0.10, -0.02, -0.07, 0.10, -0.04, -0.08]) LIMIT 5;
```

### Always `LIMIT` rows — no relevance cut-off

ANN always returns the `LIMIT` nearest rows, relevant or not, and the similarity
drops off after the real matches. BM25 only returns rows that match. The two
answers are complementary: BM25 knows which article has the exact words, ANN knows
which articles are about the same thing. Hybrid uses both.

---

# Part 3 — Hybrid search (RRF)

One query, both indexes: ScyllaDB asks the vector index and the fulltext index in
parallel, takes the union of the rows they return, and orders it by **Reciprocal
Rank Fusion** — `sum(1 / (60 + rank))` over the searches that found the row. It
fuses **ranks**, not scores: a BM25 score of 3.5 and a cosine similarity of 0.9 are
not on one scale, but "first" and "third" are.

```sql
-- [...] = embedding of '<text>', the user's original question text
SELECT article_id,
       ANN_RANK(embedding, [...]) AS vector_rank,
       BM25_RANK(article, '<text>') AS text_rank,
       article
  FROM articles
  ORDER BY RRF(ANN(embedding, [...]), BM25(article, '<text>')) LIMIT 5;
```

- Both legs get the **same user text**: embedded for `ANN()`, verbatim for `BM25()`.
- No `WHERE BM25(...) > 0` — a hybrid query takes no `WHERE` clause.
- `vector_rank` / `text_rank` show what each leg said about the row; `null` means
  that leg did not return it. Each leg is asked for `LIMIT` rows, and `LIMIT`
  cuts the fused order.

### Fast database for low-latency workloads — fused

The same text a third time. Part 1 ranked ScyllaDB first by keywords, Part 2
ranked the relational database first by meaning. The hybrid query runs both legs
and fuses their ranks:

```sql
-- vector = 16-dim embedding of the original text: "fast database for low-latency workloads"
SELECT article_id, ANN_RANK(embedding, [-0.15, 0.03, -0.29, -0.11, -0.15, -0.05, -0.06, 0.01, 0.09, -0.14, -0.10, -0.02, -0.07, 0.10, -0.04, -0.08]) AS vector_rank, BM25_RANK(article, 'fast database for low-latency workloads') AS text_rank, article FROM articles ORDER BY RRF(ANN(embedding, [-0.15, 0.03, -0.29, -0.11, -0.15, -0.05, -0.06, 0.01, 0.09, -0.14, -0.10, -0.02, -0.07, 0.10, -0.04, -0.08]), BM25(article, 'fast database for low-latency workloads')) LIMIT 5;
```

- ScyllaDB (vector 2nd, text 1st) comes out on top, ahead of the relational
  database (vector 1st, text 4th–5th).
- ScyllaDB wins the text leg because it is the only article with `fast`,
  `low latency` and `workloads` (see the highlighting query in Part 1); the other
  databases match only `database`.
- A row found by the vector leg alone has `text_rank` `null`.

### Current limitations of the hybrid build

- **No `WHERE` clause** in a hybrid query — the vector index prefilters and the
  fulltext index does not, and how to combine the two is not decided
  (`InvalidRequest: A query running several searches does not support a WHERE clause`).
- **RRF only.** A weighted fusion such as
  `ORDER BY 0.7 * ANN_SCORE(...) + 0.3 * BM25_SCORE(...)` is planned; the grammar
  does not accept an arithmetic `ORDER BY` yet.
- **Each leg is asked for exactly `LIMIT` rows**, so the fusion only chooses among
  those; over-fetching is a follow-up.
- **No rescoring vector index** (`'rescoring': 'true'`) in a hybrid query — its
  reordered rows have no index rank to fuse.

---

## Teardown

```sql
DROP KEYSPACE IF EXISTS blog;
```
