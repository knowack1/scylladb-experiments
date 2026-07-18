# ScyllaDB Full-Text Search — CQL demo runbook

A step-by-step, copy-paste demo of ScyllaDB's full-text search (BM25) over 18
Wikipedia-style articles. Open `cqlsh` **from the `fts-demo/` directory** and paste
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
DROP INDEX IF EXISTS wikipedia.articles_body_fts;
DROP TABLE IF EXISTS wikipedia.articles;
DROP KEYSPACE IF EXISTS wikipedia;
```

## 2. Keyspace

```sql
CREATE KEYSPACE IF NOT EXISTS wikipedia;
```

## 3. Table

FTS rejects ANY `WHERE` restriction other than the `BM25()` clause itself (no
partition key, clustering key, or secondary-index predicate), so `article_id` is
the sole partition key (pure identity). `title` and `author` are carried for
DISPLAY of results only; `author` also stands in for the filter-alongside-BM25 case
that is rejected today (see M2). `article` is the full-text (BM25) indexed column —
the article body.

```sql
CREATE TABLE IF NOT EXISTS wikipedia.articles (article_id uuid PRIMARY KEY, title text, author text, article text);
```

## 4. Seed data (18 articles)

The 18 `INSERT`s live in `cql/data_seed.cql` and are pulled in with cqlsh's `SOURCE`
meta-command. The path resolves relative to the directory cqlsh was launched from,
so start cqlsh from `fts-demo/` (or adjust the path).

```
SOURCE 'cql/data_seed.cql';
```

## 5. Full-text index

The fulltext index lives on the `article` text column (only supported on
text / varchar / ascii columns). After creation the vector-store discovers the
index via CDC and performs a full base-table scan; the index reports `SERVING` once
that scan completes. Until then, queries return an error (the vector-store returns
503) — **wait a few seconds before the next step.**

```sql
CREATE CUSTOM INDEX IF NOT EXISTS articles_body_fts ON wikipedia.articles(article) USING 'fulltext_index';
```

## 6. Select the keyspace

Run this once so the scenario queries below need no keyspace prefix.

```sql
USE wikipedia;
```

---

# Milestone 1 — native today

### Global search

Find every article that mentions photosynthesis. Returns the Photosynthesis,
Chlorophyll, and Oxygen articles — one query, no partition scan.

```sql
SELECT article_id, title, author FROM articles WHERE BM25(article, 'photosynthesis') > 0 ORDER BY BM25(article, 'photosynthesis') LIMIT 10;
```

### Exact phrase

`relativity` alone appears in several physics articles, but the phrase only matches
where those three tokens are adjacent — the Theory of relativity and Black hole
articles, not the Einstein one (`relativity theory`).

```sql
SELECT article_id, title, author FROM articles WHERE BM25(article, '"theory of relativity"') > 0 ORDER BY BM25(article, '"theory of relativity"') LIMIT 10;
```

### Relevance ranking

A common term returns several rows, BM25-ranked. No score is returned, but the
order is legible from the text — the ScyllaDB and Cassandra articles, which repeat
`database` most, rank on top.

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'database') > 0 ORDER BY BM25(article, 'database') LIMIT 10;
```

### Boolean AND

Both terms required. Narrows the database articles to the two that also mention
`distributed` (ScyllaDB and Apache Cassandra).

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'database AND distributed') > 0 ORDER BY BM25(article, 'database AND distributed') LIMIT 10;
```

### Boolean OR

Either term. Broadens to every article mentioning Jupiter or Saturn (the two
gas-giant articles).

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'jupiter OR saturn') > 0 ORDER BY BM25(article, 'jupiter OR saturn') LIMIT 10;
```

### Boolean NOT

The classic disambiguation query. `python` matches both the programming language
and the snake genus; excluding `snake` drops the reptile article, leaving the
Python language and Guido van Rossum articles.

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'python NOT snake') > 0 ORDER BY BM25(article, 'python NOT snake') LIMIT 10;
```

### Boolean mixed (with grouping)

`AND` / `OR` / `NOT` with grouping in one query. Of the two gas giants, keep the
one that is a `planet` but excludes `rings` — Saturn is dropped for its rings,
leaving Jupiter.

```sql
SELECT article_id, title FROM articles WHERE BM25(article, '(jupiter OR saturn) AND planet NOT rings') > 0 ORDER BY BM25(article, '(jupiter OR saturn) AND planet NOT rings') LIMIT 10;
```

### Case folding

The analyzer lowercases both the indexed text and the query, so an all-caps query
returns the same articles as the lowercase term in Global search.

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'PHOTOSYNTHESIS') > 0 ORDER BY BM25(article, 'PHOTOSYNTHESIS') LIMIT 10;
```

### Stop-word removal

English stop words (the, a, an, of, ...) are dropped by the analyzer, so
`the database` is reduced to `database` — the identical ranked set to the bare
`database` query in Relevance ranking. The added `the` is noise.

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'the database') > 0 ORDER BY BM25(article, 'the database') LIMIT 10;
```

### Punctuation tokenization

Punctuation is a token delimiter. The ScyllaDB article says `a wide-column store
built for high-throughput, low-latency workloads` — the hyphens and comma split it
into wide / column / high / throughput / low / latency. A mid-word hyphen splits,
so `wide` (from `wide-column`) matches.

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'wide') > 0 ORDER BY BM25(article, 'wide') LIMIT 10;
```

The other half of the hyphenated word matches too: `column` (from `wide-column`).

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'column') > 0 ORDER BY BM25(article, 'column') LIMIT 10;
```

Trailing punctuation is stripped: `throughput` matches `high-throughput,`.

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'throughput') > 0 ORDER BY BM25(article, 'throughput') LIMIT 10;
```

---

# Milestone 2 — rejected today

These combine a filter with the BM25 clause. Both **fail today** with:

> Full-text search queries do not support additional WHERE restrictions

### Filter by author

`relativity` matches three articles (two by John Smith, one by Wei Chen); the
author predicate would narrow them, but it cannot be combined with BM25 today.

```sql
SELECT article_id, title, author FROM articles WHERE BM25(article, 'relativity') > 0 AND author = 'John Smith' ORDER BY BM25(article, 'relativity') LIMIT 10;
```

### Restrict by article id

Scoping to one article by its partition key fails with the same error — the
partition key is no exception. (The id below is the Theory of relativity article.)

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'relativity') > 0 AND article_id = a0000000-0000-4000-8000-000000000002 ORDER BY BM25(article, 'relativity') LIMIT 10;
```

---

# Milestone 3 — parsed, not enabled

The `~N` and `*` operators are parsed by Tantivy but not enabled until Milestone 3,
so both queries below **match nothing today**.

### Fuzzy match (edit distance)

`reletivity~1` should match `relativity` within one edit.

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'reletivity~1') > 0 ORDER BY BM25(article, 'reletivity~1') LIMIT 10;
```

### Prefix / wildcard

`photo*` should match photosynthesis, etc. Only trailing wildcards are planned, and
not before Milestone 3.

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'photo*') > 0 ORDER BY BM25(article, 'photo*') LIMIT 10;
```

---

## Start over

Drops the wikipedia keyspace and everything in it, so you can re-run from the top.

```sql
DROP INDEX IF EXISTS wikipedia.articles_body_fts;
DROP TABLE IF EXISTS wikipedia.articles;
DROP KEYSPACE IF EXISTS wikipedia;
```
