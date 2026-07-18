# Verification

Run this before the customer call to walk in with a known-green baseline. Apply
the schema and seed, wait for the indexes to report `SERVING`, then confirm each
scenario returns what's expected.

```bash
cqlsh -f cql/01_keyspace.cql
cqlsh -f cql/02_tables.cql
cqlsh -f cql/fts/03_index_fts.cql
cqlsh -f cql/vector/03_index_vector.cql
cqlsh -f cql/04_seed_data.cql
# wait ~a few seconds for the fulltext + vector indexes to reach SERVING
```

## Expected results

Run each from `cqlsh` after `USE chat;` (the native scenarios are in `cql/fts/m1/`,
the semantic query is in `cql/vector/scenarios_vector.cql`, and the later-milestone
failures are in `cql/fts/m2/` and `cql/fts/m3/`).

| Scenario | Query | Expectation |
|---|---|---|
| headline | `BM25(message,'scylladb')` | 3 rows, across 3 distinct chats, a scylladb needle on top |
| phrase | `BM25(message,'"scylladb full text search"')` | exactly 1 row (the phrase needle) |
| ranking | `BM25(message,'database')` | many rows, BM25-ordered |
| boolean_and | `BM25(message,'scylladb AND benchmark')` | exactly 1 row |
| boolean_or | `BM25(message,'scylladb OR database')` | 18 match, LIMIT 10 shown, scylladb hits on top |
| boolean_not | `BM25(message,'scylladb NOT benchmark')` | exactly 2 rows |
| boolean (mixed) | `(bali OR vacation) AND flights NOT cancelled` | the Bali needle present |
| case folding | `BM25(message,'SCYLLADB')` | same 3 rows as the `scylladb` headline |
| stop words | `BM25(message,'the database')` | same ranked set as bare `database` (`the` dropped) |
| punctuation | `BM25(message,'kick')` / `'roll'` | exactly 1 row each (the `kick-off ... roll-up` fixture) |
| semantic (ANN) | `vector/scenarios_vector.cql` | the Bali message ranked #1 |
| filter | `BM25(...) AND sender_id = ...` | error: "additional WHERE restrictions" |
| no_limit | any BM25 query without `LIMIT` | error mentioning `LIMIT` |

## Manual spot checks

If you have access to the vector-store's HTTP API, confirm the indexes are live:

- Vector-store up: `curl -s http://127.0.0.1:6080/api/v1/status`
- Indexes discovered: `curl -s http://127.0.0.1:6080/api/v1/indexes`
- Index serving + count:
  `curl -s http://127.0.0.1:6080/api/v1/indexes/chat/messages_body_fts/status`

Record the console output here during rehearsal so any drift on the day is obvious.

## Note on ANN recall

If the semantic query ever fails to rank the Bali message first, re-seed from a
clean teardown (`cql/99_teardown.cql`, then reapply) — re-seeding on top of an
existing in-RAM vector index can degrade ANN recall.
