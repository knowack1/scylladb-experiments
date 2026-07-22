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
- Modern retrieval is **hybrid**: BM25 (lexical/exact) + vector (semantic), fused. FTS isn't legacy — it's half of production RAG (see M2 hybrid, Slide 6).

---

## Slide 3 — How BM25 scores a match

```text
score(D,Q) = Σ_t∈Q  IDF(t) · tf(t,D)·(k1+1) / ( tf(t,D) + k1·(1 − b + b·|D|/avgdl) )
```

- **Term frequency (TF)** — more occurrences of the term in the document → higher score, but with **saturation** (`k1` ≈ 1.2): the 10th occurrence adds far less than the 1st, so keyword-stuffing doesn't win.
- **Inverse document frequency (IDF)** — terms **rare across the corpus** weigh more; a word appearing in nearly every row (a de-facto stop-word) contributes almost nothing — this is why `E1102` beats `error` in ranking.
- **Document length normalization** — a hit in a short message counts more than the same hit in a long one; `b` ≈ 0.75 scales the penalty by the document's length relative to the **corpus average** (`avgdl`).
- **Multi-term queries just sum per-term scores** — word order and proximity are ignored (only quoted `"phrases"` require adjacency); Tantivy uses the standard defaults `k1 = 1.2`, `b = 0.75`.

---

## Slide 4 — The demo: CQL I'll run

- **One table, one index** — text column `message` + a custom index; creating it auto-enables CDC, then wait for `SERVING`:
  ```sql
  CREATE CUSTOM INDEX messages_body_fts ON chat.messages(message) USING 'fulltext_index';
  ```
- **The only valid FTS query shape** (term must be identical in both clauses):
  ```sql
  SELECT ... FROM messages WHERE BM25(message,'scylladb') > 0
  ORDER BY BM25(message,'scylladb') LIMIT 10;
  ```
- **Works natively (M1):** global search, `"exact phrase"`, BM25 ranking, `AND`/`OR`/`NOT` + grouping, case-folding, stop-words, punctuation tokenization.
- **Fails live on purpose (roadmap):** `LIMIT` mandatory (≤1000), no extra `WHERE` filter, `BM25()` not allowed in `SELECT` — the M2/M3 files prove the gaps with real server errors.

---

## Slide 5 — Architecture: ScyllaDB ↔ vector-store

```mermaid
flowchart LR
  App["Client (cqlsh / app)"] -->|CQL| Coord["ScyllaDB coordinator"]
  Coord -->|"HTTP JSON — POST /api/v1/.../bm25 · /ann"| VS["vector-store (Rust / axum)"]
  VS -->|"CQL — scan system_schema.indexes + base table"| Coord
  VS -->|"CDC log tail (scylla-cdc)"| Coord
  subgraph node["vector-store index node"]
    Tantivy["Tantivy in-RAM inverted index — BM25"]
    USearch["usearch HNSW — vector / ANN"]
  end
  VS --> Tantivy
  VS --> USearch
```

- **ScyllaDB owns** CQL parse/execute, base data, CDC, and index **metadata only** — it stores *no* inverted or vector index.
- **vector-store owns the index**: a Rust/axum sidecar that connects back as a CQL client, discovers `CUSTOM` indexes, bootstraps via full table scan, then tails **CDC** to stay current (<3s lag).
- **Query path:** coordinator calls `POST .../bm25`, gets ranked primary keys, then **re-reads authoritative rows from the base table** in rank order (503 until `SERVING`).

---

## Slide 6 — Future milestones

- **M2 — filtered & scoped FTS:** allow extra `WHERE` beside BM25 — filter by `sender_id`, scope to a `chat_id`, date ranges (the queries that fail today).
- **M2 — hybrid search:** combine BM25 + vector ANN in one query, fused with `USING FUSION = {RRF | WEIGHTED}` — the exact-match + semantic combo RAG needs.
- **M3 — richer matching:** enable fuzzy (`term~N`) and prefix/wildcard (`term*`) — already parsed by Tantivy, not yet served.
- **Hardening:** per-language analyzers & stemming, index durability / faster rebuild (today in-RAM, rebuilt on restart), and read-after-write consistency.
