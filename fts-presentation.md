# ScyllaDB Full-Text Search

A CQL demo — BM25 full-text & vector search

---

## Slide 1 — What is FTS (vs. `LIKE`)?

- **FTS** tokenizes and analyzes text (lowercase, stop-word removal, punctuation split) into an **inverted index**, then ranks hits by **BM25 relevance** — best matches first, not row order.
- **`LIKE`** is a raw substring/pattern scan: no tokenization, no ranking, every match is "equal", and it gets slow at scale.
- FTS speaks a query language — `AND` / `OR` / `NOT`, `"exact phrases"`, `(grouping)` — while `LIKE` only offers `%` / `_` wildcards.
- Trade-off: `LIKE` is exact and always current; FTS is ranked and language-aware but **eventually consistent** (index built from CDC). *No stemming in M1: `run` ≠ `running`.*

---

## Slide 2 — Why FTS still matters today (RAG & agentic AI)

- Vector/semantic search wins on **meaning & paraphrase**, but is **blind to tokens with no semantic content**: error codes (`E1102`), surnames, SKUs, UUIDs, config keys, function names — embeddings blur exact identifiers into noise.
- RAG answer quality hinges on **exact-term recall**: "why do I get error E1102?" must retrieve the doc literally containing `E1102`, not the semantically "nearest" paragraph.
- Agentic tools need **deterministic, explainable lookups** — ticket by ID, customer by surname, log line by code — where BM25 keyword match beats cosine similarity.
- Modern retrieval is **hybrid**: BM25 (lexical/exact) + vector (semantic), fused. FTS isn't legacy — it's half of production RAG.

---

## Slide 3 — The demo: CQL I'll run

- **One table, one index** — 18 explainer articles, text column `article` + a custom index; creating it auto-enables CDC, then wait for `SERVING`:
  ```sql
  CREATE CUSTOM INDEX articles_body_fts ON blog.articles(article) USING 'fulltext_index';
  ```
- **The only valid FTS query shape** (term must be identical in both clauses):
  ```sql
  SELECT article_id, title, author FROM articles WHERE BM25(article,'photosynthesis') > 0
  ORDER BY BM25(article,'photosynthesis') LIMIT 10;
  ```
- **Works natively (M1):** global search, `"exact phrase"`, BM25 ranking, `AND`/`OR`/`NOT` + grouping, case-folding, stop-words, punctuation tokenization.
- **Fails live on purpose (roadmap):** `LIMIT` mandatory (≤1000), no extra `WHERE` filter, `BM25()` not allowed in `SELECT` — the M2/M3 files prove the gaps with real server errors.

---

## Slide 4 — Architecture: ScyllaDB ↔ vector-store

```text
 +---------------------+          +------------+
 |  Client (cqlsh/app) | --CQL--> |  ScyllaDB  |
 +---------------------+          +------------+
                                    |      ^
                          HTTP bm25 |      | CQL / CDC
                                    v      |
                        +-------------------------------+
                        |          vector-store         |
                        |  +-------------------------+  |
                        |  | full-text: Tantivy-BM25 |  |
                        |  +-------------------------+  |
                        |  +-------------------------+  |
                        |  | vector: Usearch-HNSW    |  |
                        |  +-------------------------+  |
                        +-------------------------------+
```

- **ScyllaDB owns** CQL parse/execute, base data, CDC, and index **metadata only** — it stores *no* inverted or vector index.
- **vector-store owns the index**: a Rust/axum sidecar that connects back as a CQL client, discovers `CUSTOM` indexes, bootstraps via full table scan, then tails **CDC** to stay current (<3s lag).
- **Query path:** coordinator calls `POST .../bm25`, gets ranked primary keys, then **re-reads authoritative rows from the base table** in rank order (503 until `SERVING`).
