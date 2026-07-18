-- ScyllaDB FTS demo — Milestone 2: scope to one chat (rejected today).
USE chat;

-- In-chat scoping: restrict a full-text search to one chat (partition key). FAILS
-- with the same "additional WHERE restrictions" error — the partition key is no
-- exception. (chat_id is the deterministic uuid5(NAMESPACE, 'chat:7').)
SELECT message_id, chat_id, message FROM messages WHERE BM25(message, 'birthday') > 0 AND chat_id = f91b6b59-1a19-5514-b3f3-bbf5809b09f9 ORDER BY BM25(message, 'birthday') LIMIT 10;
