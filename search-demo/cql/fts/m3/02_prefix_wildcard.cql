-- ScyllaDB FTS demo — Milestone 3: prefix / wildcard (parsed, not enabled today).
USE chat;

-- Prefix / wildcard: 'data*' should match database, dataset, etc. Only trailing
-- wildcards are planned, and not before Milestone 3, so this matches nothing today.
SELECT message_id, message FROM messages WHERE BM25(message, 'data*') > 0 ORDER BY BM25(message, 'data*') LIMIT 10;
