-- ScyllaDB FTS demo — boolean NOT.
USE chat;

-- Boolean NOT — exclude a term. The scylladb messages minus the 'benchmark' one.
SELECT message_id, message FROM messages WHERE BM25(message, 'scylladb NOT benchmark') > 0 ORDER BY BM25(message, 'scylladb NOT benchmark') LIMIT 10;
