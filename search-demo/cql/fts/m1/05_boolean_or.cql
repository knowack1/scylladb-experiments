-- ScyllaDB FTS demo — boolean OR.
USE chat;

-- Boolean OR — either term. Broadens to every scylladb OR database message (18
-- match; LIMIT caps the display at 10, BM25 ranks the scylladb hits on top).
SELECT message_id, message FROM messages WHERE BM25(message, 'scylladb OR database') > 0 ORDER BY BM25(message, 'scylladb OR database') LIMIT 10;
