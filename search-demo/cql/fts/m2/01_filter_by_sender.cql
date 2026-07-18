-- ScyllaDB FTS demo — Milestone 2: filter by sender (rejected today).
USE chat;

-- Filter + full-text: birthday messages from a specific sender. FAILS:
--   "Full-text search queries do not support additional WHERE restrictions"
-- (sender_id is John's deterministic uuid5(NAMESPACE, 'sender:John').)
SELECT message_id, sender_id, message FROM messages WHERE BM25(message, 'birthday') > 0 AND sender_id = a47e8ef9-b188-5efd-a542-080eee063d39 ORDER BY BM25(message, 'birthday') LIMIT 10;
