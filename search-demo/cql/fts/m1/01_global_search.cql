-- ScyllaDB FTS demo — global cross-chat search.
USE chat;

-- Global cross-chat search: find the message that mentioned ScyllaDB.
SELECT message_id, chat_id, sender_id, sent_at, message FROM messages WHERE BM25(message, 'ScyllaDB') > 0 ORDER BY BM25(message, 'ScyllaDB') LIMIT 10;
