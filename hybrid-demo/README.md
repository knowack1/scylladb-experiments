# ScyllaDB Search — FTS + Vector + Hybrid CQL Demo

One table, two indexes, three kinds of search over 22 short technical articles
(databases, latency, networking, kernels, replication, storage). ScyllaDB is the
only product named. Each article also carries a precomputed 384-dim
`all-MiniLM-L6-v2` embedding, so `cqlsh` needs no embedding model.

| Part | Search            | Query shape                                                        |
| ---- | ----------------- | ------------------------------------------------------------------ |
| 1    | Full-text (BM25)  | `WHERE BM25(article, 'q') > 0 ORDER BY BM25(article, 'q') LIMIT n` |
| 2    | Vector (ANN)      | `ORDER BY ANN(embedding, [...]) LIMIT n`                           |
| 3    | Hybrid (RRF)      | `ORDER BY RRF(ANN(embedding, [...]), BM25(article, 'q')) LIMIT n`  |

## Prerequisites

- A ScyllaDB build from the `hybrid-search` branch (`m-szymon/hybrid-search`) —
  it adds `RRF()`, `BM25_HIGHLIGHT()`, `ANN_SCORE()` / `ANN_RANK()` and
  `BM25_RANK()`. The plain BM25 and ANN queries run on any build with full-text
  and vector search.
- A vector-store serving both the fulltext and the vector index.
- `cqlsh` pointed at that cluster.
- Only to **regenerate** the seed: `pip install sentence-transformers`.

## Quickstart

Open `cqlsh` from this directory and follow [`demo.md`](demo.md) top to bottom.

```bash
cd hybrid-demo
cqlsh   # then paste the blocks from demo.md in order
```

## Layout

- `demo.md` — the runbook: keyspace → table (`article_id`, `article`,
  `embedding vector<float, 384>`) → seed → fulltext + vector index, then
  Part 1 (FTS, Lucene syntax), Part 2 (vector), Part 3 (hybrid).
- `cql/data_seed.cql` — the 22 articles with embeddings (generated).
- `cql/vector/*.cql` — one ANN query per scenario, query vector inlined (generated).
- `cql/hybrid/*.cql` — one RRF query per scenario, query vector inlined (generated).
- `tools/gen_seed.py` — the generator; the corpus and all query texts live here.

## Regenerating the seed

```bash
pip install sentence-transformers
python tools/gen_seed.py
```

The scenarios in `demo.md` depend on the exact wording of the articles (term
counts for ranking, `distributed` / `scales` for the `AND` funnel, `kernel` for
`NOT`) — re-check them after editing the corpus.

## Operational notes

- Both indexes are discovered via CDC and do a full base-table scan before
  reporting `SERVING`; queries return an error (503) until then. The FTS index
  commits every ~3s, so fresh writes become searchable a few seconds later.
- **Do not restart the vector-store mid-demo** — it rebuilds both indexes by
  rescanning the base table.
