# ScyllaDB Full-Text Search — CQL Demo

A runnable, honest demo of ScyllaDB's full-text search (BM25) and vector search,
built around a synthetic chat dataset. Everything is plain CQL you apply with
`cqlsh` — schema, seed data (embeddings inlined), and copy-pasteable scenario
queries. It shows what works natively today and proves the roadmap gaps live via
the real server errors.

## What the customer asked for, and what actually works

| Ask | Status |
|---|---|
| Exact / phrase search | ✅ native |
| Filter + full-text (sender, date) | 🛣️ later milestone (proven via server error live) |
| Vector / semantic search | ✅ native, as a separate ANN query |

Fuzzy (`term~N`) and prefix (`term*`) matching are **Milestone 3** and out of
scope for this build.

Full detail with the exact server errors is in
[docs/capability-matrix.md](docs/capability-matrix.md).

## Prerequisites

- A running ScyllaDB build with full-text search (the vector-store must be wired
  up, since the fulltext and vector indexes are served by it). See
  [docs/architecture.md](docs/architecture.md) for how the pieces fit together.
- `cqlsh` (or any CQL client) pointed at that cluster.

Embeddings are precomputed and inlined into `cql/04_seed_data.cql` and
`cql/vector/scenarios_vector.cql`, so nothing here needs an embedding model,
Python, or extra tooling.

## Quickstart

The demo is split into two tracks that share one schema and dataset: `cql/fts/`
(full-text BM25) and `cql/vector/` (semantic ANN). Apply the shared setup, then
pick a track (or run both) and wait a few seconds for the index to report
`SERVING` before querying:

```bash
# Shared setup (run once)
cqlsh -f cql/01_keyspace.cql
cqlsh -f cql/02_tables.cql

# Full-text (BM25) track
cqlsh -f cql/fts/03_index_fts.cql
cqlsh -f cql/04_seed_data.cql
# wait ~a few seconds for CDC to build the fulltext index, then:
for f in cql/fts/m1/*.cql; do cqlsh -f "$f"; done                 # BM25 scenarios that work natively
for f in cql/fts/m2/*.cql cql/fts/m3/*.cql; do cqlsh -f "$f"; done # later-milestone queries that FAIL today

# Vector (semantic) track
cqlsh -f cql/vector/03_index_vector.cql
cqlsh -f cql/04_seed_data.cql             # same shared seed; skip if already applied
# wait ~a few seconds for CDC to build the vector index, then:
cqlsh -f cql/vector/scenarios_vector.cql  # vector (semantic) ANN query
```

To start over: `cqlsh -f cql/99_teardown.cql` drops the indexes, table, and
keyspace.

## Interactive queries

Open `cqlsh`, run `USE chat;`, and paste any statement from the per-scenario
files in `cql/fts/m1/`, for example:

```sql
SELECT message_id, message FROM messages WHERE BM25(message, 'scylladb') > 0 ORDER BY BM25(message, 'scylladb') LIMIT 10;
SELECT message_id, message FROM messages WHERE BM25(message, '"scylladb full text search"') > 0 ORDER BY BM25(message, '"scylladb full text search"') LIMIT 10;
SELECT message_id, message FROM messages WHERE BM25(message, 'scylladb AND benchmark') > 0 ORDER BY BM25(message, 'scylladb AND benchmark') LIMIT 10;
SELECT message_id, message FROM messages WHERE BM25(message, '(bali OR vacation) AND flights NOT cancelled') > 0 ORDER BY BM25(message, '(bali OR vacation) AND flights NOT cancelled') LIMIT 10;
```

The vector (semantic) query and the roadmap failures are in their own files so you
can run them deliberately.

## Layout

- `cql/` — everything you run:
  - Shared setup (both tracks):
    - `01_keyspace.cql` — keyspace (tablets required for a fulltext index).
    - `02_tables.cql` — one `messages` table (text column + `vector<float, 384>`).
    - `04_seed_data.cql` — 101 messages with embeddings inlined (cqlsh-loadable);
      the last row is an analyzer fixture with no embedding (FTS-only).
    - `99_teardown.cql` — drop everything (both indexes, table, keyspace).
  - `fts/` — full-text (BM25) track:
    - `03_index_fts.cql` — the `fulltext_index`.
    - `query_rules.cql` — the valid FTS query shape, its rules, and track pointers.
    - `m1/` — one file per BM25 scenario that works natively (Milestone 1);
      files `08`–`10` also demonstrate the analyzer itself (case folding,
      stop-word removal, punctuation tokenization).
    - `m2/` — one file per extra-WHERE / hybrid query that fails today (Milestone 2),
      each with the exact server error to expect.
    - `m3/` — one file per fuzzy / prefix query, parsed but not enabled (Milestone 3).
  - `vector/` — vector (semantic) track:
    - `03_index_vector.cql` — the `vector_index`.
    - `scenarios_vector.cql` — the runnable ANN (semantic) query, vector inlined.
- `docs/` — capability matrix, run-of-show, architecture, verification.

## Important operational notes

- The tantivy FTS index is in-memory with a ~3s commit interval. Freshly inserted
  messages are searchable a few seconds later; a vector-store restart drops the
  index and rebuilds it by scanning the base table. Do not restart the
  vector-store mid-demo.
- Full-text queries always require a `LIMIT` (≤ 1000) and cannot carry any filter
  beyond the BM25 clause. See [docs/architecture.md](docs/architecture.md).
