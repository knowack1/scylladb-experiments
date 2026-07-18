-- ScyllaDB FTS demo — stop-word removal.
USE chat;

-- Stop-word removal. English stop words (the, a, an, on, ...) are dropped by the
-- analyzer, so 'the database' is reduced to 'database' — identical ranked set to
-- the bare 'database' query in 03_relevance_ranking.cql. The added 'the' is noise.
SELECT message_id, chat_id, sender_id, message FROM messages WHERE BM25(message, 'the database') > 0 ORDER BY BM25(message, 'the database') LIMIT 10;
