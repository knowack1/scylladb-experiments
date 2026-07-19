# ScyllaDB Full-Text Search — rejected today

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

# Rejected today

These combine a filter with the BM25 clause. Both **fail today** with:

> Full-text search queries do not support additional WHERE restrictions

### Filter by author

`relativity` matches three articles (two by John Smith, one by Wei Chen); the
author predicate would narrow them, but it cannot be combined with BM25 today.

```sql
SELECT article FROM articles WHERE BM25(article, 'relativity') > 0 AND author = 'John Smith' ORDER BY BM25(article, 'relativity') LIMIT 10;
```

### Restrict by article id

Scoping to one article by its partition key fails with the same error — the
partition key is no exception. (The id below is the Theory of relativity article.)

```sql
SELECT article FROM articles WHERE BM25(article, 'relativity') > 0 AND article_id = a0000000-0000-4000-8000-000000000002 ORDER BY BM25(article, 'relativity') LIMIT 10;
```

---

## Start over

Drops the blog keyspace and everything in it, so you can re-run from the top.

```sql
DROP INDEX IF EXISTS blog.articles_body_fts;
DROP TABLE IF EXISTS blog.articles;
DROP KEYSPACE IF EXISTS blog;
```
