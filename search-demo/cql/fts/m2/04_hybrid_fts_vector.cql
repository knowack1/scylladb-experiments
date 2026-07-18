-- ScyllaDB FTS demo — Milestone 2: hybrid FTS + vector (rejected today).
USE chat;

-- Hybrid FTS + vector: rank by BM25 and vector similarity in one query. Rejected —
-- BM25 and ANN cannot be combined; each must be its own query. Shape only (the ANN
-- clause needs a 384-float precomputed vector; see cql/vector/scenarios_vector.cql):
-- SELECT message_id, message FROM messages WHERE BM25(message, 'bali') > 0
-- ORDER BY BM25(message, 'bali'), embedding ANN OF [<384 precomputed floats>] LIMIT 5;
