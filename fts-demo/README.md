# ScyllaDB Full-Text Search — CQL Demo

A runnable, honest demo of ScyllaDB's full-text search (BM25) over a small
blog of short explainer posts. Everything is plain CQL you apply with `cqlsh` —
no embedding model, no extra tooling. It shows what works natively today and
proves the roadmap gaps live via the real server errors.

This demo is **pure full-text search**. Semantic / vector (ANN) search lives in
its own self-contained `vs-demo/`; the two share nothing.

## Capabilities

✅ native today · 🛣️ later milestone (proven via the live server error).

| Capability                                | Status         |
| ----------------------------------------- | -------------- |
| Exact / phrase search                     | ✅              |
| Relevance ranking (BM25)                  | ✅              |
| Boolean `AND` / `OR` / `NOT`, grouping    | ✅              |
| Filter by author alongside full-text      | 🛣️ Milestone 2 |
| Fuzzy (`term~N`) / prefix (`term*`) match | 🛣️ Milestone 3 |

## Prerequisites

- A running ScyllaDB build with full-text search (the vector-store serves the
  fulltext index).
- `cqlsh` (or any CQL client) pointed at that cluster.

## Quickstart

Open `cqlsh` from this directory and follow [`demo.md`](demo.md) top to bottom,
pasting each block in order — setup, then the seed (`SOURCE 'cql/data_seed.cql';`),
then the index (wait a few seconds for `SERVING`), then the M1 / M2 / M3 scenarios.

```bash
cd fts-demo
cqlsh   # then paste the blocks from demo.md in order
```

## FTS query shape and rules

The only valid full-text query shape is:

```sql
SELECT ... WHERE BM25(col, '<q>') > 0 ORDER BY BM25(col, '<q>') LIMIT <n>;
```

Each rule below, if violated, raises a specific `InvalidRequest`:

- `LIMIT` is mandatory and must be `<= 1000`.
- The search term must be identical in `WHERE` and `ORDER BY`.
- No other `WHERE` restriction is allowed (partition, clustering, or secondary).
- `BM25(...)` cannot appear in the `SELECT` list.

The query string is parsed by Tantivy. Milestone 1 supports single terms,
`AND` / `OR` / `NOT`, `"phrases"`, and `(grouping)`; fuzzy (`term~N`) and prefix
(`term*`) are Milestone 3. The analyzer is a simple tokenizer + lowercase +
English stop words — **no stemming** ("run" does not match "running").

## Interactive queries

Open `cqlsh`, run `USE blog;`, and paste any statement from
[`demo.md`](demo.md), for example:

```sql
SELECT article FROM articles WHERE BM25(article, 'photosynthesis') > 0 ORDER BY BM25(article, 'photosynthesis') LIMIT 10;
SELECT article FROM articles WHERE BM25(article, '"theory of relativity"') > 0 ORDER BY BM25(article, '"theory of relativity"') LIMIT 10;
SELECT article FROM articles WHERE BM25(article, 'python NOT snake') > 0 ORDER BY BM25(article, 'python NOT snake') LIMIT 10;
```

## Layout

- `demo.md` — the step-by-step runbook: teardown → keyspace → table
  (`articles`: `article_id`, `title`, `author`, `article`) → seed → fulltext index,
  then the scenarios:
  - **M1** — native today (global / phrase search, BM25 ranking, boolean
    AND/OR/NOT + grouping, and the analyzer: case folding, stop words, punctuation).
  - **M2** — extra-`WHERE` queries that fail today (filter by author, restrict by
    article id), each with the exact server error.
  - **M3** — fuzzy / prefix (parsed by Tantivy, not enabled today).
- `cql/data_seed.cql` — the 18 articles, pulled in from `demo.md` via
  cqlsh's `SOURCE` (kept as CQL because the `INSERT`s are bulky).

## Operational notes

- The tantivy FTS index is in-memory with a ~3s commit interval, so freshly
  inserted articles are searchable a few seconds later. A vector-store restart
  drops and rebuilds it by scanning the base table — **do not restart the
  vector-store mid-demo**.
- Full-text queries always require a `LIMIT` (`<= 1000`) and cannot carry any
  filter beyond the BM25 clause.
