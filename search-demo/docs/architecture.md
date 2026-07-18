# Architecture

```
        CQL (BM25 / ANN)                 HTTP  /api/v1/indexes/{ks}/{idx}/{bm25,ann,status}
 client ───────────────▶  ScyllaDB  ───────────────▶  vector-store  ───▶  tantivy (FTS, in-RAM)
                             │   ▲                          │              usearch  (vector)
                             │   │  CDC log stream          │
                             └───┴──────────────────────────┘
```

## Components

- **ScyllaDB** parses the `WHERE BM25(col,'q') > 0 ORDER BY BM25(col,'q') LIMIT n`
  statement, validates the FTS-specific rules, and forwards the query to the
  vector-store over HTTP. It hydrates the returned primary keys into full rows.
- **vector-store** owns the search indexes. For FTS it uses **tantivy** (in a
  standard analyzer: simple tokenizer + lowercase + English stop words). For
  vector search it uses an ANN index. It builds indexes by doing an initial full
  scan of the base table, then keeps them current by consuming the base table's
  **CDC** log.
- **This demo** is pure CQL: you talk to Scylla via `cqlsh` for schema, seed, and
  all searches. The vector-store is contacted only by Scylla itself.

## How the processes run

Scylla and the vector-store must both be running and wired together (Scylla
started with its `--vector-store-primary-uri` pointing at the vector-store, and
the vector-store pointed back at Scylla's CQL address with fulltext indexes
enabled). Once both are up, everything in this repo is applied with `cqlsh`
against Scylla's CQL port — no other client or service is involved.

## Why the schema looks the way it does

FTS rejects any `WHERE` restriction other than the BM25 clause. That removes the
usual reason to design partition keys around access patterns — you cannot filter
by chat, sender, or time alongside a search. So `messages` uses `message_id` as
its sole key and search is always global. The other columns exist purely to
display results.

## Indexing latency

The tantivy index commits on a ~3s interval and lives in memory. Consequences:

- A freshly inserted message is searchable a few seconds later, not instantly.
  After applying `04_seed_data.cql`, wait a few seconds for the fulltext and
  vector indexes to report `SERVING` before querying.
- Restarting the vector-store drops the in-memory index; it rebuilds by scanning
  the base table. Do not restart it mid-demo.

## One table, two indexes

Documents and embeddings share a single `messages` table: `message` carries the
fulltext (BM25) index and `embedding` (`vector<float, 384>`) carries the ANN
index. A lexical hit and a semantic hit therefore resolve to the same row.

Hybrid (BM25 + ANN in a single statement) is still rejected today, so semantic
search is a standalone `ORDER BY embedding ANN OF [...] LIMIT n` statement against
that same table — just a different index, not a different table.

## Embeddings are precomputed, not computed at runtime

Nothing here loads an embedding model. Vectors were precomputed once, offline,
with `all-MiniLM-L6-v2` (384-dim) and inlined directly into the CQL:

- `cql/04_seed_data.cql` — every row's document embedding is inlined into the
  `INSERT`, so seeding needs no model.
- `cql/vector/scenarios_vector.cql` — the semantic query's 384-float query vector
  is inlined into the `ORDER BY ... ANN OF [...]` clause, so the search needs no
  model either.

Because the embeddings are baked into the CQL, applying and querying this demo
depends on nothing beyond `cqlsh` and a running FTS-enabled ScyllaDB.
