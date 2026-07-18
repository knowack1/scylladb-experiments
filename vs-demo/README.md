# ScyllaDB Vector Search — CQL Demo

A runnable demo of ScyllaDB's vector (ANN) search over a small Wikipedia-style
article corpus. Each article carries a precomputed 384-dim `all-MiniLM-L6-v2`
embedding, so `cqlsh` needs no embedding model at query time.

This demo is **pure semantic search**. Lexical / full-text (BM25) search lives
in its own self-contained `fts-demo/`; the two share nothing.

## Capabilities

✅ native today.

| Capability                              | Status                 |
| --------------------------------------- | ---------------------- |
| Semantic / nearest-neighbour (ANN)      | ✅ (`ORDER BY … ANN OF`) |

## Prerequisites

- A running ScyllaDB build with the vector-store wired up (it serves the vector
  index).
- `cqlsh` (or any CQL client) pointed at that cluster.
- Only to **regenerate** the seed: `pip install sentence-transformers`.

## Quickstart

Apply the setup, then run the scenarios — wait a few seconds for the index to
reach `SERVING` before querying.

```bash
cqlsh -f cql/00_teardown.cql    # start clean: drops the wikipedia keyspace and everything in it
cqlsh -f cql/01_keyspace.cql
cqlsh -f cql/02_tables.cql
cqlsh -f cql/04_seed_data.cql   # 15 articles, embeddings inlined

cqlsh -f cql/03_index_vector.cql   # wait for SERVING before the next step
for f in cql/scenarios/*.cql; do cqlsh -f "$f"; done

cqlsh -f cql/00_teardown.cql    # start over: drops the wikipedia keyspace and everything in it
```

## Query shape

Semantic search orders rows by approximate nearest neighbour against the query
vector:

```sql
SELECT article_id, title FROM articles ORDER BY embedding ANN OF [<384 floats>] LIMIT 5;
```

Lexically the query text often shares no words with the target article, yet ANN
returns the semantically closest articles — that is the point of the demo.

## Regenerating the seed

The article corpus and the natural-language queries are defined in
`tools/gen_seed.py`. It embeds each with `all-MiniLM-L6-v2` and writes
`cql/04_seed_data.cql` and `cql/scenarios/*.cql` with the vectors inlined. The
emitted CQL is checked in, so this is a one-time build step:

```bash
pip install sentence-transformers
python tools/gen_seed.py
```

## Layout

- `cql/` — setup: `01_keyspace.cql`, `02_tables.cql` (`articles` table:
  `article_id`, `title`, `article`, `embedding vector<float, 384>`),
  `04_seed_data.cql` (generated), `03_index_vector.cql` (the vector index),
  `00_teardown.cql`.
- `cql/scenarios/` — one file per semantic query (generated), each with the
  natural-language query in a comment and its embedding inlined.
- `tools/gen_seed.py` — the seed generator (corpus + queries live here).

## Operational notes

- The vector index is discovered via CDC and does a full base-table scan before
  reporting `SERVING`; queries return an error (503) until then. A vector-store
  restart rebuilds it by rescanning the base table — **do not restart the
  vector-store mid-demo**.
