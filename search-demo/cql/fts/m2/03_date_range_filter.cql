-- ScyllaDB FTS demo — Milestone 2: date-range filter (rejected today).
USE chat;

-- Date range + full-text: a full-text search narrowed to a time window. FAILS with
-- the same restriction error — a range predicate on sent_at is still an extra WHERE.
SELECT message_id, sent_at, message FROM messages WHERE BM25(message, 'birthday') > 0 AND sent_at >= '2026-06-01' ORDER BY BM25(message, 'birthday') LIMIT 10;
