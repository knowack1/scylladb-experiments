# ScyllaDB Full-Text Search — native today

A step-by-step, copy-paste demo of ScyllaDB's full-text search (BM25) over 21
short explainer blog posts. Open `cqlsh` **from the `fts-demo/` directory** and paste
each block below in order. After creating the index, wait a few seconds for it to
reach `SERVING` before running any query.

```bash
cd fts-demo
cqlsh
```

## 1. Start clean

Dropping the keyspace removes the table and its fulltext index too, but we drop the
index and table first so re-running is explicit and order-safe.

```sql
DROP KEYSPACE IF EXISTS blog;
```

## 2. Keyspace

Create the keyspace and select it right away so every command below needs no
keyspace prefix.

```sql
CREATE KEYSPACE blog;
USE blog;
```

## 3. Table

FTS rejects ANY `WHERE` restriction other than the `BM25()` clause itself (no
partition key, clustering key, or secondary-index predicate), so `article_id` is
the sole partition key (pure identity). `article` is the full-text (BM25) indexed
column — the article body itself, which queries return so you can see the matched
text. This demo only ever queries and projects those two columns, so the table
carries nothing else.

```sql
CREATE TABLE articles (article_id uuid PRIMARY KEY, article text);
```

## 4. Seed data (21 articles)

The 21 `INSERT`s live in `cql/data_seed_m1.cql` and are pulled in with cqlsh's `SOURCE`
meta-command. The path resolves relative to the directory cqlsh was launched from,
so start cqlsh from `fts-demo/` (or adjust the path).

```
SOURCE 'cql/data_seed_m1.cql';
```

Confirm the 21 rows loaded — this reads every partition, which is exactly what FTS
lets you avoid later. It also previews all 21 short article bodies.

```sql
SELECT article_id, article FROM articles;
```

## 5. Full-text index

The fulltext index lives on the `article` text column (only supported on
text / varchar / ascii columns). After creation the vector-store discovers the
index via CDC and performs a full base-table scan; the index reports `SERVING` once
that scan completes. Until then, queries return an error (the vector-store returns
503) — **wait a few seconds before the next step.**

```sql
CREATE CUSTOM INDEX articles_body_fts ON articles(article) USING 'fulltext_index';
```

Inspect the created index — this shows its target column, the `fulltext_index`
custom class, and any options it was created with.

```sql
DESCRIBE INDEX articles_body_fts;
```

---

# Native today

### Global search

Find every article that mentions photosynthesis. Returns the Photosynthesis,
Chlorophyll, and Oxygen articles — one query, no partition scan.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'photosynthesis') > 0 ORDER BY BM25(article, 'photosynthesis') LIMIT 10;
```

### Case folding

The analyzer lowercases both the indexed text and the query, so an all-caps query
returns the same articles as the lowercase term in Global search.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'PHOTOSYNTHESIS') > 0 ORDER BY BM25(article, 'PHOTOSYNTHESIS') LIMIT 10;
```

### Exact phrase

`relativity` alone appears in several physics articles, but the phrase only matches
where those three tokens are adjacent — the Theory of relativity and Black hole
articles, not the Einstein one (`relativity theory`).

```sql
SELECT article_id, article FROM articles WHERE BM25(article, '"theory of relativity"') > 0 ORDER BY BM25(article, '"theory of relativity"') LIMIT 10;
```

### Phrase without quotes

Drop the quotation marks and the analyzer treats the input as independent tokens
rather than a phrase — `of` is removed as a stop word (see Stop-word removal),
leaving `theory` and `relativity` matched by position, order and adjacency
ignored. So this returns all three physics articles that mention both terms —
including the Albert Einstein article (`relativity theory`) that the quoted phrase
below excludes precisely because its words are reversed.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'theory of relativity') > 0 ORDER BY BM25(article, 'theory of relativity') LIMIT 10;
```


### Relevance ranking

A common term returns several rows, BM25-ranked — and here relevance reduces to one
visible rule: **how many times each article says the query term.** Five articles
mention `database`; ScyllaDB says it most (four times), then Apache Cassandra
(three), Amazon DynamoDB (two), and MongoDB and PostgreSQL once each — so they come
back in exactly that order. No score is projected; the ranking is legible from the
text.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'database') > 0 ORDER BY BM25(article, 'database') LIMIT 5;
```

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'the database') > 0 ORDER BY BM25(article, 'the database') LIMIT 5;
```

### Boolean AND — narrowing the set

`AND` requires every term, so each term you add can only shrink the result set.
Start from the simple `database` search — the same five articles as Relevance
ranking — and watch it funnel down to one.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'database') > 0 ORDER BY BM25(article, 'database') LIMIT 10;
```

Add `AND distributed`. Only ScyllaDB and Apache Cassandra call themselves
distributed, so DynamoDB, MongoDB and PostgreSQL drop out — five narrows to two.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'database AND distributed') > 0 ORDER BY BM25(article, 'database AND distributed') LIMIT 10;
```

Add `AND scales`. Of those two, only the ScyllaDB article mentions scaling — the
set narrows to one, ScyllaDB alone.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'database AND distributed AND scales') > 0 ORDER BY BM25(article, 'database AND distributed AND scales') LIMIT 10;
```

### Boolean OR — widening the set

`OR` requires only one term to match, so each term you add can only grow the result
set. Start from the simple `jupiter` search — a single planet — and watch it fan
out.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'jupiter') > 0 ORDER BY BM25(article, 'jupiter') LIMIT 10;
```

Add `OR saturn`. Both gas-giant planets now match — one widens to two.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'jupiter OR saturn') > 0 ORDER BY BM25(article, 'jupiter OR saturn') LIMIT 10;
```

### Boolean NOT — narrowing by exclusion

`NOT` narrows from the other direction: it removes matches instead of requiring
them. The classic disambiguation query — `python` matches both the programming
language and the snake genus; excluding `snake` drops the reptile article, leaving
the Python language and Guido van Rossum articles.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'python') > 0 ORDER BY BM25(article, 'python') LIMIT 10;
SELECT article_id, article FROM articles WHERE BM25(article, 'python NOT snake') > 0 ORDER BY BM25(article, 'python NOT snake') LIMIT 10;
```

### Boolean mixed (with grouping)

The capstone: `AND` / `OR` / `NOT` with grouping combined in one query. Of the two
gas giants, keep the one that is a `planet` but excludes `rings` — Saturn is dropped
for its rings, leaving Jupiter.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, '(jupiter OR saturn) AND planet NOT rings') > 0 ORDER BY BM25(article, '(jupiter OR saturn) AND planet NOT rings') LIMIT 10;
```


### Punctuation tokenization

Punctuation is a token delimiter. The ScyllaDB article says `a distributed
wide-column database built for high-throughput, low-latency workloads` — the
hyphens and comma split it into wide / column / high / throughput / low / latency.
A mid-word hyphen splits, so `wide` (from `wide-column`) matches.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'wide') > 0 ORDER BY BM25(article, 'wide') LIMIT 10;
```

The other half of the hyphenated word matches too: `column` (from `wide-column`).

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'column') > 0 ORDER BY BM25(article, 'column') LIMIT 10;
```

Trailing punctuation is stripped: `throughput` matches `high-throughput,`.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'throughput') > 0 ORDER BY BM25(article, 'throughput') LIMIT 10;
```
