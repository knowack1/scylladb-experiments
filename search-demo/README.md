# ScyllaDB Full-Text Search — CQL Demo

A runnable, honest demo of ScyllaDB's full-text search (BM25) and vector search
over a synthetic chat dataset. Everything is plain CQL you apply with `cqlsh`.
Embeddings are precomputed and inlined, so nothing here needs an embedding model
or extra tooling. It shows what works natively today and proves the roadmap gaps
live via the real server errors.

## Capabilities

✅ native today · 🛣️ later milestone (proven via the live server error).

| Capability                                         | Status                 |
| -------------------------------------------------- | ---------------------- |
| Exact / phrase search                              | ✅                      |
| Relevance ranking (BM25)                           | ✅                      |
| Boolean `AND` / `OR` / `NOT`, grouping             | ✅                      |
| Vector / semantic search                           | ✅ (separate ANN query) |
| Filter + full-text (sender, date), in-chat scoping | 🛣️ Milestone 2          |
| Hybrid BM25 + vector in one query                  | 🛣️ Milestone 2          |
| Fuzzy (`term~N`) / prefix (`term*`) matching       | 🛣️ Milestone 3          |

## Prerequisites

- A running ScyllaDB build with full-text search, with the vector-store wired up
  (it serves both the fulltext and vector indexes).
- `cqlsh` (or any CQL client) pointed at that cluster.

## Quickstart

Two tracks share one schema and dataset: full-text (BM25) and vector (semantic
ANN). Apply the shared setup, then run either track — wait a few seconds for the
index to reach `SERVING` before querying.

```bash
# Shared setup (run once)
cqlsh -f cql/01_keyspace.cql
cqlsh -f cql/02_tables.cql
cqlsh -f cql/04_seed_data.cql   # 101 messages, embeddings inlined

# Full-text (BM25) track — wait for SERVING after the index step
cqlsh -f cql/fts/03_index_fts.cql
for f in cql/fts/m1/*.cql; do cqlsh -f "$f"; done                 # work natively
for f in cql/fts/m2/*.cql cql/fts/m3/*.cql; do cqlsh -f "$f"; done # FAIL today (later milestones)

# Vector (semantic) track — wait for SERVING after the index step
cqlsh -f cql/vector/03_index_vector.cql
cqlsh -f cql/vector/scenarios_vector.cql

cqlsh -f cql/99_teardown.cql    # start over: drops indexes, table, keyspace
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

Open `cqlsh`, run `USE chat;`, and paste any statement from the per-scenario
files, for example:

```sql
SELECT message_id, message FROM messages WHERE BM25(message, 'scylladb') > 0 ORDER BY BM25(message, 'scylladb') LIMIT 10;
SELECT message_id, message FROM messages WHERE BM25(message, '"scylladb full text search"') > 0 ORDER BY BM25(message, '"scylladb full text search"') LIMIT 10;
SELECT message_id, message FROM messages WHERE BM25(message, 'scylladb AND benchmark') > 0 ORDER BY BM25(message, 'scylladb AND benchmark') LIMIT 10;
```

## Layout

- `cql/` — shared setup: `01_keyspace.cql` (tablets required for a fulltext
  index), `02_tables.cql` (`messages` table with a text column and
  `vector<float, 384>`), `04_seed_data.cql`, `99_teardown.cql`.
- `cql/fts/` — BM25 track: `03_index_fts.cql`, plus one file per scenario in
  `m1/` (native; `08`–`10` also demonstrate the analyzer), `m2/` (extra-WHERE /
  hybrid queries that fail today, each with the exact server error), and `m3/`
  (fuzzy / prefix, parsed but not enabled).
- `cql/vector/` — semantic track: `03_index_vector.cql` and
  `scenarios_vector.cql` (the runnable ANN query, vector inlined).

## Operational notes

- The tantivy FTS index is in-memory with a ~3s commit interval, so freshly
  inserted messages are searchable a few seconds later. A vector-store restart
  drops and rebuilds it by scanning the base table — **do not restart the
  vector-store mid-demo**.
- Full-text queries always require a `LIMIT` (`<= 1000`) and cannot carry any
  filter beyond the BM25 clause.
