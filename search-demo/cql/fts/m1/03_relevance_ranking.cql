-- ScyllaDB FTS demo — relevance ranking.
USE chat;

-- Relevance ranking: a common term returns many rows, BM25-ranked. No score is
-- returned, but the order is legible from the text -- the top rows repeat 'database' most.
SELECT message_id, message FROM messages WHERE BM25(message, 'database') > 0 ORDER BY BM25(message, 'database') LIMIT 10;
