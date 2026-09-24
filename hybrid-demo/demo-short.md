# ScyllaDB Search — short runbook

Commands only — no files needed, every command is inline. For the full
walkthrough, see [`demo.md`](demo.md).

```bash
cqlsh
```

## Setup

Start clean.

```sql
DROP KEYSPACE IF EXISTS blog;
```

Create the keyspace (tablets).

```sql
CREATE KEYSPACE blog;
```

Switch to it.

```sql
USE blog;
```

Create the table: id, article text, and the article's embedding.

```sql
CREATE TABLE articles (article_id int PRIMARY KEY, article text, embedding vector<float, 16>);
```

Load 22 articles with precomputed 16-dim embeddings — one batch, so it runs only on Enter.

```sql
BEGIN BATCH
  INSERT INTO articles (article_id, article, embedding) VALUES (1, 'ScyllaDB is a distributed database, a NoSQL database built for low-latency workloads at any scale, so the database stays fast as the database grows.', [-0.37, 0.04, -0.30, -0.06, 0.19, 0.12, 0.07, 0.07, 0.19, 0.18, -0.31, -0.18, -0.12, 0.33, -0.09, 0.00]);
  INSERT INTO articles (article_id, article, embedding) VALUES (2, 'A wide-column store is a distributed NoSQL database design: the database groups columns into families and replicates every row, so the database has no single point of failure.', [-0.54, -0.03, -0.10, 0.16, -0.08, 0.03, 0.22, -0.15, -0.24, 0.19, -0.09, -0.02, -0.02, -0.19, 0.02, -0.23]);
  INSERT INTO articles (article_id, article, embedding) VALUES (3, 'A key-value store is a distributed database that is fully managed and serverless, a database that grows automatically with its applications.', [-0.56, 0.01, -0.06, 0.26, -0.17, -0.22, -0.02, -0.06, 0.17, 0.28, 0.09, -0.03, 0.33, -0.16, -0.11, 0.25]);
  INSERT INTO articles (article_id, article, embedding) VALUES (4, 'A document database keeps flexible JSON-like records for modern application development.', [-0.60, 0.09, -0.20, -0.06, -0.15, 0.20, -0.06, 0.17, -0.19, -0.25, 0.35, 0.16, -0.05, 0.06, 0.19, 0.08]);
  INSERT INTO articles (article_id, article, embedding) VALUES (5, 'A relational database is a speedy, powerful engine with strong SQL support and ACID guarantees.', [-0.51, 0.11, -0.11, 0.10, -0.19, 0.11, -0.24, -0.01, 0.05, -0.31, -0.17, -0.13, -0.05, 0.08, -0.07, -0.14]);
  INSERT INTO articles (article_id, article, embedding) VALUES (6, 'Tail latency is the slowest one percent of requests; the p99 decides how responsive a service feels to its users.', [0.29, -0.27, -0.43, -0.15, -0.27, -0.32, -0.12, 0.14, -0.09, -0.13, -0.17, 0.09, -0.28, -0.20, -0.15, 0.18]);
  INSERT INTO articles (article_id, article, embedding) VALUES (7, 'Latency spikes at the tail of the distribution often come from garbage collection pauses and noisy neighbours.', [0.28, -0.14, -0.24, -0.34, -0.12, -0.12, -0.02, 0.03, -0.19, 0.30, -0.18, 0.05, 0.19, 0.05, 0.36, -0.13]);
  INSERT INTO articles (article_id, article, embedding) VALUES (8, 'The shard-per-core architecture pins one thread to each CPU core, so cores never share memory or wait on locks.', [0.22, 0.34, 0.09, 0.24, 0.12, -0.23, -0.21, -0.33, 0.15, -0.06, -0.11, 0.05, -0.12, -0.10, 0.02, -0.15]);
  INSERT INTO articles (article_id, article, embedding) VALUES (9, 'The Linux kernel schedules threads, manages memory, and handles every system call an application makes.', [0.29, 0.49, -0.08, 0.18, 0.14, 0.11, -0.05, 0.04, -0.09, 0.14, 0.07, -0.08, -0.05, -0.15, 0.01, 0.10]);
  INSERT INTO articles (article_id, article, embedding) VALUES (10, 'A GPU kernel is a small function launched across thousands of parallel threads at once.', [0.28, 0.51, -0.04, 0.23, -0.02, -0.06, 0.25, -0.12, -0.03, -0.12, 0.02, -0.10, -0.11, 0.10, 0.28, 0.17]);
  INSERT INTO articles (article_id, article, embedding) VALUES (11, 'Kernel bypass networking moves packets straight from the network card to user space, skipping the operating system.', [0.46, 0.19, 0.12, 0.26, -0.22, 0.11, 0.33, 0.48, -0.10, -0.01, 0.01, -0.06, 0.11, 0.02, -0.21, -0.16]);
  INSERT INTO articles (article_id, article, embedding) VALUES (12, 'TCP guarantees ordered delivery: every lost packet is detected and retransmitted before the stream continues.', [0.30, -0.45, -0.01, 0.17, -0.07, 0.34, -0.21, 0.03, 0.17, -0.04, -0.05, -0.08, 0.04, -0.19, 0.08, -0.08]);
  INSERT INTO articles (article_id, article, embedding) VALUES (13, 'UDP sends each packet once with no handshake and no retransmission, trading reliability for speed.', [0.35, -0.48, -0.01, 0.28, -0.07, 0.26, -0.11, -0.09, 0.21, -0.03, 0.09, -0.02, 0.10, 0.16, 0.10, 0.12]);
  INSERT INTO articles (article_id, article, embedding) VALUES (14, 'Raft is a consensus algorithm for distributed systems: a leader replicates a log to its followers, and a majority must agree before a write commits.', [-0.08, -0.18, -0.13, 0.04, 0.66, -0.04, 0.19, 0.18, -0.00, -0.17, -0.18, 0.21, 0.13, -0.05, -0.01, 0.15]);
  INSERT INTO articles (article_id, article, embedding) VALUES (15, 'Replication keeps several copies of each row on different nodes, so a node failure never makes the row unreachable.', [-0.07, -0.45, 0.44, 0.14, 0.11, 0.09, 0.15, -0.28, -0.40, -0.05, -0.06, 0.08, -0.11, 0.02, -0.07, 0.02]);
  INSERT INTO articles (article_id, article, embedding) VALUES (16, 'Compaction merges immutable SSTables on disk and drops overwritten and deleted rows to reclaim space.', [-0.18, -0.10, 0.43, -0.29, -0.09, 0.08, 0.30, 0.10, 0.39, 0.20, 0.07, 0.05, -0.33, -0.12, 0.09, 0.04]);
  INSERT INTO articles (article_id, article, embedding) VALUES (17, 'An LSM tree absorbs writes in memory, flushes them to sorted files, and merges the files later in the background.', [-0.07, 0.16, 0.19, -0.40, 0.32, 0.06, -0.19, 0.14, 0.03, -0.16, 0.09, -0.24, 0.12, -0.24, 0.04, -0.10]);
  INSERT INTO articles (article_id, article, embedding) VALUES (18, 'A cache keeps hot rows in memory so repeated reads skip the disk entirely.', [0.12, 0.02, 0.33, -0.39, -0.16, -0.03, -0.01, -0.17, -0.19, -0.08, -0.06, -0.32, 0.12, 0.11, -0.12, 0.22]);
  INSERT INTO articles (article_id, article, embedding) VALUES (19, 'Distributed tracing follows a single request across services and shows where each millisecond was spent.', [0.23, -0.22, -0.43, -0.10, 0.22, -0.13, 0.07, -0.17, -0.01, 0.12, 0.50, -0.13, -0.10, 0.11, -0.18, -0.14]);
  INSERT INTO articles (article_id, article, embedding) VALUES (20, 'Consistent hashing places nodes on a ring, so adding a node moves only a small fraction of the keys.', [-0.10, -0.17, 0.39, 0.15, 0.00, -0.62, -0.12, 0.22, 0.08, -0.08, 0.09, 0.04, 0.03, 0.20, 0.08, -0.13]);
  INSERT INTO articles (article_id, article, embedding) VALUES (21, 'NVMe drives expose many parallel hardware queues, cutting storage access time to tens of microseconds.', [0.16, 0.22, -0.08, -0.31, -0.19, 0.07, 0.26, -0.29, 0.23, -0.23, -0.02, 0.34, 0.23, 0.04, -0.13, -0.10]);
  INSERT INTO articles (article_id, article, embedding) VALUES (22, 'Rust checks memory safety at compile time, with no garbage collector to pause the program.', [0.08, 0.31, 0.23, -0.08, 0.04, 0.21, -0.45, 0.08, -0.12, 0.32, 0.02, 0.33, -0.06, 0.13, -0.14, 0.03]);
APPLY BATCH;
```

Check the rows.

```sql
SELECT article_id, article FROM articles;
```

Create the fulltext index.

```sql
CREATE CUSTOM INDEX articles_body_fts ON articles(article) USING 'fulltext_index' WITH OPTIONS = {'analyzer': 'standard', 'positions': 'true'};
```

Create the vector index — then wait a few seconds for both indexes to reach `SERVING`.

```sql
CREATE CUSTOM INDEX articles_embedding_ann ON articles(embedding) USING 'vector_index';
```

## Part 1 — Full-text search

One word: five database articles, ranked by how often each says `database`.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'database') > 0 ORDER BY BM25(article, 'database') LIMIT 10;
```

Two words, `OR` by default: any of them matches — seven rows, the distributed databases on top.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed database') > 0 ORDER BY BM25(article, 'distributed database') LIMIT 10;
```

Quoted phrase: the words adjacent and in order — two rows.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, '"distributed database"') > 0 ORDER BY BM25(article, '"distributed database"') LIMIT 10;
```

`AND`: both words anywhere in the article — three rows.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed AND database') > 0 ORDER BY BM25(article, 'distributed AND database') LIMIT 10;
```

One more `AND` term: only ScyllaDB is left.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed AND database AND scale') > 0 ORDER BY BM25(article, 'distributed AND database AND scale') LIMIT 10;
```

`NOT`: distributed, but not a database — tracing and Raft.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, 'distributed NOT database') > 0 ORDER BY BM25(article, 'distributed NOT database') LIMIT 10;
```

Grouping: the distributed databases plus the relational one — four rows.

```sql
SELECT article_id, article FROM articles WHERE BM25(article, '(distributed OR relational) AND database') > 0 ORDER BY BM25(article, '(distributed OR relational) AND database') LIMIT 10;
```

Highlighting: matched words wrapped in `<b>…</b>` — the query used in Parts 2 and 3; ScyllaDB ranks first by keywords.

```sql
SELECT article_id, BM25_HIGHLIGHT(article, 'fast database for low-latency workloads') AS excerpt FROM articles WHERE BM25(article, 'fast database for low-latency workloads') > 0 ORDER BY BM25(article, 'fast database for low-latency workloads') LIMIT 5;
```

## Part 2 — Vector search

Search by meaning: the relational database ranks first, ScyllaDB second.
The query vector is the 16-dim embedding of the original text: "fast database for low-latency workloads".

```sql
SELECT article_id, ANN_SCORE(embedding, [-0.15, 0.03, -0.29, -0.11, -0.15, -0.05, -0.06, 0.01, 0.09, -0.14, -0.10, -0.02, -0.07, 0.10, -0.04, -0.08]) AS similarity, article FROM articles ORDER BY ANN(embedding, [-0.15, 0.03, -0.29, -0.11, -0.15, -0.05, -0.06, 0.01, 0.09, -0.14, -0.10, -0.02, -0.07, 0.10, -0.04, -0.08]) LIMIT 5;
```

## Part 3 — Hybrid search

Both searches fused by rank (RRF): ScyllaDB ranks first.
The query vector is the 16-dim embedding of the original text: "fast database for low-latency workloads".

```sql
SELECT article_id, ANN_RANK(embedding, [-0.15, 0.03, -0.29, -0.11, -0.15, -0.05, -0.06, 0.01, 0.09, -0.14, -0.10, -0.02, -0.07, 0.10, -0.04, -0.08]) AS vector_rank, BM25_RANK(article, 'fast database for low-latency workloads') AS text_rank, article FROM articles ORDER BY RRF(ANN(embedding, [-0.15, 0.03, -0.29, -0.11, -0.15, -0.05, -0.06, 0.01, 0.09, -0.14, -0.10, -0.02, -0.07, 0.10, -0.04, -0.08]), BM25(article, 'fast database for low-latency workloads')) LIMIT 5;
```

## Teardown

Drop everything.

```sql
DROP KEYSPACE IF EXISTS blog;
```
