-- ScyllaDB FTS demo — case folding (case-insensitive search).
USE chat;

-- Case folding. The analyzer lowercases both the indexed text and the query,
-- so an all-caps query returns the same rows as the lowercase headline.
SELECT message_id, chat_id, sender_id, message FROM messages WHERE BM25(message, 'SCYLLADB') > 0 ORDER BY BM25(message, 'SCYLLADB') LIMIT 10;
