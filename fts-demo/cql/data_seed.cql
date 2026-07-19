-- ScyllaDB FTS demo — seed data (18 short explainer blog posts, no embeddings).
--
-- Hand-authored plain text — this demo is pure full-text search, so there are no
-- embeddings to precompute and the file stays small and editable.
--
-- article_id is a fixed UUID per article, so re-applying is idempotent (same id
-- -> upsert). Article bodies are one short sentence each and carry the
-- deterministic "needle" terms every query in demo.md relies on (photosynthesis,
-- relativity, jupiter, python, ...). A small set of author names (Jane Doe,
-- John Smith, Maria Garcia, Wei Chen, Priya Patel) is reused across articles so
-- author filtering is meaningful.
--
-- Pulled in from demo.md via cqlsh `SOURCE 'cql/data_seed.cql';` once the
-- blog.articles table exists. The fulltext index picks these rows up via CDC
-- within a few seconds of insertion.

USE blog;

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000001, 'Photosynthesis', 'Jane Doe', 'Photosynthesis lets green plants convert sunlight into chemical energy and release oxygen.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000002, 'Theory of relativity', 'John Smith', 'Einstein''s theory of relativity links space and time and reshaped modern physics.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000003, 'Quantum mechanics', 'Maria Garcia', 'Quantum mechanics describes nature at the scale of atoms and subatomic particles.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000004, 'Jupiter', 'Wei Chen', 'Jupiter is the largest planet in the Solar System, a gas giant of hydrogen.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000005, 'Saturn', 'Wei Chen', 'Saturn is the sixth planet from the Sun, a gas giant famous for its rings.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000006, 'Python (programming language)', 'Priya Patel', 'Python is a high-level, general-purpose programming language with readable syntax.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000007, 'Python (genus)', 'Jane Doe', 'The python is a large constricting snake found in Africa, Asia, and Australia.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000008, 'ScyllaDB', 'John Smith', 'ScyllaDB is a distributed wide-column database built for high-throughput, low-latency workloads.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000009, 'Apache Cassandra', 'John Smith', 'Apache Cassandra is a distributed wide-column NoSQL database with no single point of failure.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000010, 'Great Barrier Reef', 'Maria Garcia', 'The Great Barrier Reef is the world''s largest coral reef system off Queensland, Australia.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000011, 'Black hole', 'Wei Chen', 'A black hole forms when a massive star collapses, as predicted by the theory of relativity.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000012, 'Chlorophyll', 'Jane Doe', 'Chlorophyll is the green pigment in plants that is essential for photosynthesis.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000013, 'Isaac Newton', 'Priya Patel', 'Isaac Newton formulated the laws of motion and universal gravitation.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000014, 'Albert Einstein', 'John Smith', 'Albert Einstein developed relativity theory, a pillar of modern physics.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000015, 'Coral', 'Maria Garcia', 'Coral is a marine invertebrate that lives in compact colonies of many polyps.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000016, 'Guido van Rossum', 'Priya Patel', 'Guido van Rossum created the Python programming language and released it in 1991.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000017, 'Oxygen', 'Wei Chen', 'Most atmospheric oxygen on Earth is produced by photosynthesis in plants and algae.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000018, 'Milky Way', 'Maria Garcia', 'The Milky Way is the barred spiral galaxy that contains our Solar System.');
