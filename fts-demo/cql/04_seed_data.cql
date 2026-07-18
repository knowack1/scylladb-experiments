-- ScyllaDB FTS demo — seed data (18 Wikipedia-style articles, no embeddings).
--
-- Hand-authored plain text — this demo is pure full-text search, so there are no
-- embeddings to precompute and the file stays small and editable.
--
-- article_id is a fixed UUID per article, so re-applying is idempotent (same id
-- -> upsert). Article bodies carry the deterministic "needle" terms every query
-- in scenarios/ relies on (photosynthesis, relativity, jupiter, python, ...).
-- A small set of author names (Jane Doe, John Smith, Maria Garcia, Wei Chen,
-- Priya Patel) is reused across articles so author filtering is meaningful.
--
-- Apply after 01_keyspace, 02_tables, and 03_index_fts. The fulltext index picks
-- these rows up via CDC within a few seconds of insertion.

USE wikipedia;

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000001, 'Photosynthesis', 'Jane Doe', 'Photosynthesis is the process by which green plants and some other organisms convert light energy into chemical energy. Using chlorophyll, plants absorb carbon dioxide and water and release oxygen. This process powers nearly all life on Earth and forms the base of the food chain.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000002, 'Theory of relativity', 'John Smith', 'The theory of relativity, developed by Albert Einstein, describes how space and time are linked for objects moving at a constant speed. The general theory of relativity extends this to gravity, explaining it as the curvature of spacetime. Relativity reshaped modern physics and predicted phenomena such as black holes.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000003, 'Quantum mechanics', 'Maria Garcia', 'Quantum mechanics is a fundamental theory in physics that describes nature at the scale of atoms and subatomic particles. It introduces concepts such as wave-particle duality and the uncertainty principle. Unlike classical theory, it predicts probabilities rather than definite outcomes.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000004, 'Jupiter', 'Wei Chen', 'Jupiter is the largest planet in the Solar System, a gas giant composed mainly of hydrogen and helium. Its most famous feature is the Great Red Spot, a giant storm larger than Earth. Jupiter has dozens of moons, including the four large Galilean moons.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000005, 'Saturn', 'Wei Chen', 'Saturn is the sixth planet from the Sun and the second largest in the Solar System. It is best known for its spectacular rings, made of ice and rock. Saturn is a gas giant with a bright set of rings visible from Earth through a small telescope.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000006, 'Python (programming language)', 'Priya Patel', 'Python is a high-level, general-purpose programming language known for its readable syntax. It supports multiple programming paradigms and ships with a large standard library. Python is widely used in web development, data analysis, and machine learning.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000007, 'Python (genus)', 'Jane Doe', 'Python is a genus of large constricting snakes found in Africa, Asia, and Australia. These non-venomous snakes kill prey by constriction rather than venom. The reticulated python is among the longest snakes in the world.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000008, 'ScyllaDB', 'John Smith', 'ScyllaDB is a distributed NoSQL database designed for high-throughput, low-latency workloads. It is a wide-column store compatible with Apache Cassandra, rewritten in C++ for performance. ScyllaDB scales across many nodes and handles large real-time data sets.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000009, 'Apache Cassandra', 'John Smith', 'Apache Cassandra is a distributed database built to handle large amounts of data across many commodity servers. It is a wide-column NoSQL database that offers high availability with no single point of failure. Cassandra uses a peer-to-peer architecture for horizontal scalability.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000010, 'Great Barrier Reef', 'Maria Garcia', 'The Great Barrier Reef is the world''s largest coral reef system, located off the coast of Queensland, Australia. It is composed of thousands of individual reefs and hundreds of islands built by tiny coral polyps. The reef is home to a huge diversity of marine life.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000011, 'Black hole', 'Wei Chen', 'A black hole is a region of spacetime where gravity is so strong that nothing, not even light, can escape. Black holes form when massive stars collapse at the end of their life. Their existence was predicted by the general theory of relativity.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000012, 'Chlorophyll', 'Jane Doe', 'Chlorophyll is the green pigment found in plants, algae, and cyanobacteria that is essential for photosynthesis. It absorbs light most strongly in the blue and red wavelengths and reflects green light. Chlorophyll captures the energy that plants use to make sugars.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000013, 'Isaac Newton', 'Priya Patel', 'Isaac Newton was an English mathematician and physicist who formulated the laws of motion and universal gravitation. His work described how gravity governs the motion of planets and falling objects. Newton is regarded as one of the most influential scientists in history.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000014, 'Albert Einstein', 'John Smith', 'Albert Einstein was a physicist best known for developing relativity theory, one of the pillars of modern physics. He is famous for the mass-energy equivalence formula E = mc squared. Einstein received the Nobel Prize in Physics in 1921.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000015, 'Coral', 'Maria Garcia', 'Coral is a marine invertebrate that typically lives in compact colonies of many identical polyps. Coral reefs are built from the calcium carbonate skeletons secreted by these polyps over thousands of years. Reefs support about a quarter of all known marine species.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000016, 'Guido van Rossum', 'Priya Patel', 'Guido van Rossum is a Dutch programmer best known as the creator of the Python programming language. He first released Python in 1991 and led its development for decades. He described his role in the community as the benevolent dictator for life.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000017, 'Oxygen', 'Wei Chen', 'Oxygen is a chemical element and the third most abundant element in the universe. On Earth, most atmospheric oxygen is produced by photosynthesis in plants and algae. Oxygen is essential for the respiration of most living organisms.');

INSERT INTO articles (article_id, title, author, article) VALUES (a0000000-0000-4000-8000-000000000018, 'Milky Way', 'Maria Garcia', 'The Milky Way is the galaxy that contains our Solar System, with hundreds of billions of stars. Its name describes the faint band of light from distant stars that appears across the night sky. The Milky Way is a barred spiral galaxy roughly one hundred thousand light-years across.');
