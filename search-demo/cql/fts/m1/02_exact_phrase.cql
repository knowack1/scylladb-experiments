-- ScyllaDB FTS demo — exact phrase search.
USE chat;

-- Exact phrase. Same word as the headline, but the phrase only matches
-- the one message where those tokens are adjacent — not every scylladb mention.
SELECT message_id, chat_id, sender_id, message FROM messages WHERE BM25(message, '"scylladb full text search"') > 0 ORDER BY BM25(message, '"scylladb full text search"') LIMIT 10;
