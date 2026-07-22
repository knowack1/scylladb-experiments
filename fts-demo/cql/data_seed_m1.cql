-- ScyllaDB FTS demo — seed data for the "native today" (M1) demo (21 short posts).
--
-- Two-column variant of cql/data_seed.cql: the M1 demo's articles table is pure
-- identity + indexed body (article_id, article), so title and author are dropped.
-- The article bodies and article_ids are identical to data_seed.cql so the same
-- needle terms (photosynthesis, relativity, jupiter, python, database, ...) match.
-- Keep the bodies in sync with data_seed.cql if either file changes.
--
-- Pulled into demo-m1.md via cqlsh `SOURCE 'cql/data_seed_m1.cql';` once the
-- blog.articles table exists. The fulltext index picks the rows up via CDC within
-- a few seconds of insertion.

USE blog;

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000001, 'Photosynthesis lets green plants convert sunlight into chemical energy and release oxygen.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000002, 'Einstein''s theory of relativity links space and time and reshaped modern physics.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000003, 'Quantum mechanics describes nature at the scale of atoms and subatomic particles.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000004, 'Jupiter is the largest planet in the Solar System, a gas giant of hydrogen.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000005, 'Saturn is the sixth planet from the Sun, a gas giant famous for its rings.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000006, 'Python is a high-level, general-purpose programming language with readable syntax.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000007, 'The python is a large constricting snake found in Africa, Asia, and Australia.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000008, 'ScyllaDB is a distributed wide-column database, a NoSQL database built for high-throughput, low-latency workloads that keep the database fast as the database scales.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000009, 'Apache Cassandra is a distributed wide-column NoSQL database, an open-source database designed so the database has no single point of failure.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000010, 'The Great Barrier Reef is the world''s largest coral reef system off Queensland, Australia.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000011, 'A black hole forms when a massive star collapses, as predicted by the theory of relativity.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000012, 'Chlorophyll is the green pigment in plants that is essential for photosynthesis.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000013, 'Isaac Newton formulated the laws of motion and universal gravitation.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000014, 'Albert Einstein developed relativity theory, a pillar of modern physics.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000015, 'Coral is a marine invertebrate that lives in compact colonies of many polyps.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000016, 'Guido van Rossum created the Python programming language and released it in 1991.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000017, 'Most atmospheric oxygen on Earth is produced by photosynthesis in plants and algae.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000018, 'The Milky Way is the barred spiral galaxy that contains our Solar System.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000019, 'Amazon DynamoDB is a fully managed key-value database, a serverless database that scales automatically for internet-scale applications.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000020, 'MongoDB is a document-oriented database that stores flexible JSON-like records for modern application development.');

INSERT INTO articles (article_id, article) VALUES (a0000000-0000-4000-8000-000000000021, 'PostgreSQL is a powerful open-source relational database with strong SQL support and ACID guarantees.');
