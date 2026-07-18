-- ScyllaDB FTS demo — Milestone 3: fuzzy match (parsed, not enabled today).
USE chat;

-- Fuzzy (edit distance): 'mesage~1' should match 'message' within one edit. The
-- ~N operator is parsed by Tantivy but not enabled until Milestone 3, so today
-- this matches nothing.
SELECT message_id, message FROM messages WHERE BM25(message, 'mesage~1') > 0 ORDER BY BM25(message, 'mesage~1') LIMIT 10;
