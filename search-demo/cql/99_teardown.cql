-- ScyllaDB FTS demo — teardown.
DROP INDEX IF EXISTS chat.messages_body_fts;
DROP INDEX IF EXISTS chat.messages_vec_ann;
DROP TABLE IF EXISTS chat.messages;
DROP KEYSPACE IF EXISTS chat;
