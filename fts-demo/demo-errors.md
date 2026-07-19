# ScyllaDB Full-Text Search — invalid queries

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
the sole partition key (pure identity). `title` and `author` are kept in the schema
but no longer projected — queries return the `article` body itself so you can see
the matched text; `author` remains for the filter-alongside-BM25 case that is
rejected today. `article` is the full-text (BM25) indexed column — the
article body.

```sql
CREATE TABLE articles (article_id uuid PRIMARY KEY, title text, author text, article text);
```

## 4. Seed data (21 articles)

The 21 `INSERT`s live in `cql/data_seed.cql` and are pulled in with cqlsh's `SOURCE`
meta-command. The path resolves relative to the directory cqlsh was launched from,
so start cqlsh from `fts-demo/` (or adjust the path).

```
SOURCE 'cql/data_seed.cql';
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

# Invalid queries

Every valid full-text query has exactly one shape:

```sql
SELECT ... WHERE BM25(col, '<q>') > 0 ORDER BY BM25(col, '<q>') LIMIT <n>;
```

The queries below each break that shape in one way, so each is rejected with an
`InvalidRequest` (except where noted). These are validation failures — malformed
by construction — not the roadmap gaps shown in the other files.

### Non-zero score threshold

The predicate is fixed at `> 0` — the marker that says "return every scored match".
Raising it to `> 5` asks for a raw BM25 score cutoff the query layer does not honor.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'photosynthesis') > 5 ORDER BY BM25(article, 'photosynthesis') LIMIT 10;
```

> `<!-- TODO: paste exact server error from cqlsh — verify live: is this rejected as InvalidRequest, or silently score-filtered to fewer/zero rows? -->`

### Missing ORDER BY

Without `ORDER BY BM25(...)` the engine has a match predicate but no ranking to
apply, so the query no longer matches the required shape.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'photosynthesis') > 0 LIMIT 10;
```

> `<!-- TODO: paste exact server error from cqlsh -->`

### Missing WHERE

The mirror case: an `ORDER BY BM25(...)` with no `WHERE BM25(...)` to select the
matching rows. Ranking with nothing to rank is rejected.

```sql
SELECT article_id, article FROM articles ORDER BY BM25(article, 'photosynthesis') LIMIT 10;
```

> `<!-- TODO: paste exact server error from cqlsh -->`

### Mismatched WHERE / ORDER BY terms

The search term must be identical in both clauses. Here `WHERE` matches
`photosynthesis` but `ORDER BY` ranks by `chlorophyll` — two different queries, so
the server refuses to run it.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'photosynthesis') > 0 ORDER BY BM25(article, 'chlorophyll') LIMIT 10;
```

> `<!-- TODO: paste exact server error from cqlsh -->`

### Missing / oversized LIMIT

`LIMIT` is mandatory on a full-text query — omitting it is rejected outright.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'photosynthesis') > 0 ORDER BY BM25(article, 'photosynthesis');
```

> `<!-- TODO: paste exact server error from cqlsh -->`

And when present it must be `<= 1000`; `1001` is over the cap.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'photosynthesis') > 0 ORDER BY BM25(article, 'photosynthesis') LIMIT 1001;
```

> `<!-- TODO: paste exact server error from cqlsh -->`

### BM25 in the SELECT list

`BM25(...)` is a query operator, not a projectable column — it cannot appear in the
`SELECT` list, so asking to return the score alongside the body is rejected.

```sql
SELECT article, BM25(article, 'photosynthesis') FROM articles WHERE BM25(article, 'photosynthesis') > 0 ORDER BY BM25(article, 'photosynthesis') LIMIT 10;
```

> `<!-- TODO: paste exact server error from cqlsh -->`

---

## Start over

Drops the blog keyspace and everything in it, so you can re-run from the top.

```sql
DROP INDEX IF EXISTS blog.articles_body_fts;
DROP TABLE IF EXISTS blog.articles;
DROP KEYSPACE IF EXISTS blog;
```
