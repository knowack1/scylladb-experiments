-- ScyllaDB FTS demo — boolean mixed with grouping.
USE chat;

-- Boolean mixed — AND / OR / NOT with grouping in one query.
SELECT message_id, message FROM messages WHERE BM25(message, '(bali OR vacation) AND flights NOT cancelled') > 0 ORDER BY BM25(message, '(bali OR vacation) AND flights NOT cancelled') LIMIT 10;
