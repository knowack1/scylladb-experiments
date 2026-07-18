-- ScyllaDB FTS demo — boolean AND.
USE chat;

-- Boolean AND — both terms required. Narrows the 3 scylladb hits to the one that
-- also mentions 'benchmark'.
SELECT message_id, message FROM messages WHERE BM25(message, 'scylladb AND benchmark') > 0 ORDER BY BM25(message, 'scylladb AND benchmark') LIMIT 10;
