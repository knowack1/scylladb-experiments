# Demo Run-of-Show

Drive this from `cqlsh`: run `USE chat;`, then paste the statements below one at a
time (they are copy-pasteable from the per-scenario files in `cql/fts/m1/`,
`cql/vector/scenarios_vector.cql`, and `cql/fts/m2/` + `cql/fts/m3/`). Open with
the live index-creation phase (section 0b), then walk the numbered steps in order.

## 0. Frame (30 seconds)

> "Everything you'll see is real, running on a ScyllaDB build with full-text
> search. I'll show what works today, and I'll be just as clear about what's
> roadmap — I'll trigger the actual server errors so you see the real boundaries,
> not a slide."

## 0b. Index creation — build the index live

Before any search, show the index being created. Apply `cql/fts/03_index_fts.cql`
and `cql/vector/03_index_vector.cql` (or run the two statements by hand): each
`CREATE CUSTOM INDEX ... USING '...'` statement creates the fulltext or vector
index. The vector-store then notices them via CDC, scans the table, and reports
`SERVING` once the whole corpus is indexed (you can watch the document count climb
on the vector-store's status endpoint).

> "The index isn't magic — it's a CREATE CUSTOM INDEX. The vector-store notices
> it, scans the table over CDC, and once it's SERVING every message is
> searchable. That's the whole corpus being indexed."

## 1. Headline — global cross-chat search

Search `scylladb`. Three results appear from three different chats (a direct chat
and two groups), ranked. This is the customer's core story: "I remember someone
mentioned ScyllaDB — find it." Point out that a single query searched every
personal and group chat at once.

## 2. Exact phrase (ask #1)

Search `"scylladb full text search"` → the single message where those tokens sit
adjacent. Same word as the headline, but the exact phrase narrows 3 cross-chat hits
down to 1 — proving phrase precision. Note that the vector-store returns only
primary keys + BM25 scores; Scylla hydrates those keys back into full rows for the
result you see.

## 3. Ranking

Search `database` → many results, ordered by BM25 relevance. This demonstrates
real relevance ranking across the whole corpus.

## 4. Boolean expressiveness

Build up the operators one at a time against the scylladb set, then combine them:

- `scylladb AND benchmark` — **AND** narrows the 3 scylladb hits to the 1 that also
  mentions "benchmark".
- `scylladb OR database` — **OR** broadens to every scylladb or database message (18
  match; LIMIT caps the display at 10, BM25 keeps the scylladb hits on top).
- `scylladb NOT benchmark` — **NOT** trims the scylladb set down to 2, dropping the
  "benchmark" message.
- `(bali OR vacation) AND flights NOT cancelled` — everything at once: AND/OR/NOT and
  grouping, the query operators supported in Milestone 1.

## 5. Semantic search (ask #4)

The user recalls a conversation about a holiday. Search
`planning a trip overseas for the summer` as full-text → little or nothing (the
target message shares no words with the query). Then run the ANN query from
`cql/vector/scenarios_vector.cql` (the same natural-language query, precomputed into a
384-float vector) → it returns "let's book flights to Bali and spend two weeks on
the beach...". Contrast lexical vs semantic. Clarify this is a **separate ANN
query**, not a hybrid — the server does not combine BM25 and vector search in one
query today.

## 6. Honesty segment — later-milestone gaps, shown live

- **Filter (ask #3)**: `birthday` filtered by `sender_id` (John's), the first
  query in `cql/fts/m2/01_filter_by_sender.cql` → the server returns
  `InvalidRequest: ... do not support additional WHERE restrictions`. "The engine
  rejects any filter alongside search today — a real gap we're tracking."
- Optionally: drop the `LIMIT` from any BM25 query → the mandatory-LIMIT error.
- If asked about typo tolerance or prefix matching: those are **Milestone 3**
  (fuzzy `term~N`, prefix `term*`) and intentionally out of scope for this build.

## 7. Capability matrix

Walk the tables in `docs/capability-matrix.md`: the query capabilities and the
per-SEP Lucene syntax support, each later-milestone row backed by the exact
server error.

## 8. Close

> "Two of your four asks work natively now — exact/phrase and semantic search.
> Filtered search is a later milestone, with a clear path. Fuzzy and prefix
> matching arrive in Milestone 3. And global relevance search across all chats —
> your main use case — is solid today."
