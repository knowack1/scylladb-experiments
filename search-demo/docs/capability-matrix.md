# ScyllaDB Full-Text Search — Capability Matrix

This is the honest centerpiece of the demo. Every row below was verified against
the actual implementation (the CQL layer in the Scylla FTS branch and the
tantivy-backed vector-store), not against documentation. Roadmap rows quote the
exact `InvalidRequest` the server returns so you can trigger them live.

This demo targets **Milestone 1**. Status legend: ✅ native today · 🛣️ later
milestone (does not work today).

## Query capabilities

| Capability | Customer ask | Status | Mechanism | Proof |
|---|---|---|---|---|
| Global cross-chat search | Primary story | ✅ | `WHERE BM25(message,'scylladb')>0 ORDER BY BM25(...) LIMIT n` | 3 "scylladb" hits across 3 different chats |
| Exact / phrase search | #1 | ✅ | `"scylladb full text search"` | 1 exact-phrase message vs 3 for the bare term |
| Boolean AND / OR / NOT, grouping | — | ✅ | `scylladb AND benchmark`, `scylladb OR database`, `scylladb NOT benchmark`, `(bali OR vacation) AND flights NOT cancelled` | AND→1 row, OR→18 match, NOT→2 rows, mixed→expected message |
| Relevance ranking (BM25) | Primary | ✅ | `ORDER BY BM25(...)` | common term returns many, ranked; high-TF needle ranks first |
| Vector / semantic search | #4 | ✅ (separate ANN query) | `ORDER BY embedding ANN OF [...] LIMIT n` | "planning a trip overseas" → "flights to Bali" (no shared words) |
| Filter + FTS (sender / date) | #3 | 🛣️ later milestone | any extra `WHERE` is rejected | `InvalidRequest: Full-text search queries do not support additional WHERE restrictions` |
| In-chat scoping (partition key) | — | 🛣️ later milestone | partition-key `WHERE` rejected | same restriction error |
| Hybrid FTS + vector | — | 🛣️ later milestone | `BM25(...) ORDER BY ... ANN OF ...` rejected | server rejects mixing BM25 and ANN |

## Text analysis (analyzer)

The analyzer is a simple tokenizer + lowercase + English stop words (**no
stemming**). These behaviors work natively today; each has a runnable scenario.

| Behavior | Status | Mechanism | Proof |
|---|---|---|---|
| Case folding | ✅ | index + query both lowercased | `BM25(message,'SCYLLADB')` returns the same 3 rows as `'scylladb'` (`m1/08_case_folding.cql`) |
| Stop-word removal | ✅ | English stop words dropped from the query | `'the database'` reduces to `'database'` — identical ranked set (`m1/09_stop_words.cql`) |
| Punctuation tokenization | ✅ | punctuation (`-`, `,`, `:`, `!`) is a token delimiter | `'kick'`/`'roll'` each match the `kick-off ... roll-up` fixture (`m1/10_punctuation.cql`) |

## Lucene query syntax (per SEP)

The query string is parsed by Tantivy. What Milestone 1 accepts:

| Lucene syntax | Supported | Notes |
|---|---|---|
| Single term (`database`) | ✅ Yes | |
| Boolean operators (`AND`, `OR`, `NOT`) | ✅ Yes | |
| Phrase queries (`"out of memory"`) | ✅ Yes | |
| Grouping with parentheses | ✅ Yes | |
| Fuzzy queries (`term~N`) | 🛣️ Milestone 3 | |
| Prefix / wildcard (`term*`) | 🛣️ Milestone 3 | Only trailing wildcards; leading wildcards (`*term`) are not supported. |
| Field-scoped queries (`title:database`) | ❌ No | Column selection is done via `MATCH()` arguments, not within the query string. |
| Range queries (`[a TO z]`) | ❌ No | Range predicates use standard CQL `WHERE` clauses on indexed fields. |
| Boosting (`term^2.0`) | ❌ No | Use `field_boosts` in `WITH OPTIONS` for per-column boosting. |
| Regular expressions (`/pattern/`) | ❌ No | |
| Proximity queries (`"term1 term2"~N`) | ❌ No | May be considered in a future milestone. |
| Required / prohibited (`+term`, `-term`) | ❌ No | Use `AND` / `NOT` operators instead. |

## Summary for the customer

Of the four asks, **#1 (exact/phrase) and #4 (semantic) work natively today**.
**#3 (filtered search) is a later milestone** and we prove the gap live rather
than hiding it. Fuzzy and prefix/wildcard matching land in **Milestone 3**.

## Hard limits to state up front

- `LIMIT` is mandatory on every full-text query and must be `<= 1000`.
- The search term must be identical in the `WHERE BM25(...)` and `ORDER BY BM25(...)` clauses.
- No aggregation, no `PER PARTITION LIMIT`; paging emits a warning.
- Index is supported only on `text` / `varchar` / `ascii` columns.
- The base table's keyspace must use **tablets**, and creating the index enables
  **CDC** on the base table (TTL ≥ 24h).
- Analyzer is a simple tokenizer + lowercase + English stop words — **no
  stemming** ("run" does not match "running").
- The tantivy index is **in-memory** and rebuilt by a base-table scan on restart;
  there is a **~3s commit interval**, so freshly written messages become
  searchable a few seconds after insert.

## What each later-milestone item would need

- **Filter + FTS / in-chat scoping**: allow additional `WHERE` predicates
  (partition key, secondary index) to combine with the BM25 clause and be applied
  before or after ranking.
- **Hybrid**: a fusion strategy (e.g. reciprocal rank fusion or weighted scores)
  to combine BM25 and ANN result sets in one query.
- **Fuzzy / prefix (Milestone 3)**: enable fuzzy and prefix term queries in the
  query parser (per-field), then expose an edit-distance option on the index or
  query.
