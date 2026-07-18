# ScyllaDB Full-Text Search — CQL Demo

A runnable, honest demo of ScyllaDB's full-text search (BM25) over a small
Wikipedia-style article corpus. Everything is plain CQL you apply with `cqlsh` —
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

Apply the setup, then run the scenarios — wait a few seconds for the index to
reach `SERVING` before querying.

```bash
cqlsh -f cql/00_teardown.cql    # start clean: drops the wikipedia keyspace and everything in it
cqlsh -f cql/01_keyspace.cql
cqlsh -f cql/02_tables.cql
cqlsh -f cql/04_seed_data.cql   # 18 articles

cqlsh -f cql/03_index_fts.cql   # wait for SERVING before the next step
for f in cql/scenarios/m1/*.cql; do cqlsh -f "$f"; done                       # work natively
for f in cql/scenarios/m2/*.cql cql/scenarios/m3/*.cql; do cqlsh -f "$f"; done # FAIL today (later milestones)

cqlsh -f cql/00_teardown.cql    # start over: drops the wikipedia keyspace and everything in it
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

Open `cqlsh`, run `USE wikipedia;`, and paste any statement from the
per-scenario files, for example:

```sql
SELECT article_id, title FROM articles WHERE BM25(article, 'photosynthesis') > 0 ORDER BY BM25(article, 'photosynthesis') LIMIT 10;
SELECT article_id, title FROM articles WHERE BM25(article, '"theory of relativity"') > 0 ORDER BY BM25(article, '"theory of relativity"') LIMIT 10;
SELECT article_id, title FROM articles WHERE BM25(article, 'python NOT snake') > 0 ORDER BY BM25(article, 'python NOT snake') LIMIT 10;
```

## Layout

- `cql/` — setup: `01_keyspace.cql`, `02_tables.cql` (`articles` table:
  `article_id`, `title`, `author`, `article`), `04_seed_data.cql` (18 articles),
  `03_index_fts.cql` (the fulltext index), `00_teardown.cql`.
- `cql/scenarios/` — one file per scenario:
  - `m1/` — native today (`01`–`07` search + boolean; `08`–`10` demonstrate the
    analyzer: case folding, stop words, punctuation).
  - `m2/` — extra-`WHERE` queries that fail today (filter by author, restrict by
    article id), each with the exact server error.
  - `m3/` — fuzzy / prefix (parsed by Tantivy, not enabled today).

## Operational notes

- The tantivy FTS index is in-memory with a ~3s commit interval, so freshly
  inserted articles are searchable a few seconds later. A vector-store restart
  drops and rebuilds it by scanning the base table — **do not restart the
  vector-store mid-demo**.
- Full-text queries always require a `LIMIT` (`<= 1000`) and cannot carry any
  filter beyond the BM25 clause.
