-- ScyllaDB FTS demo — punctuation tokenization.
USE chat;

-- Punctuation is a token delimiter: 'kick-off call at noon: bring the roll-up, thanks!'
-- tokenizes to kick / off / call / noon / bring / roll / up / thanks.
-- A mid-word hyphen splits, so 'kick' (from 'kick-off') matches the fixture row.
SELECT message_id, message FROM messages WHERE BM25(message, 'kick') > 0 ORDER BY BM25(message, 'kick') LIMIT 10;

-- The other half of a hyphenated word matches too: 'roll' (from 'roll-up').
SELECT message_id, message FROM messages WHERE BM25(message, 'roll') > 0 ORDER BY BM25(message, 'roll') LIMIT 10;

-- Trailing punctuation is stripped: 'thanks' matches 'thanks!' here and 'Thanks!' elsewhere.
SELECT message_id, message FROM messages WHERE BM25(message, 'thanks') > 0 ORDER BY BM25(message, 'thanks') LIMIT 10;
