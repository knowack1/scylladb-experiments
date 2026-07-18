-- ScyllaDB FTS demo — keyspace.
--
-- A full-text (fulltext_index) index REQUIRES the base table's keyspace to use
-- tablets. Creating the index on a vnode keyspace fails with:
--   "Creating a fulltext index requires the base table's keyspace to use tablets."
-- Single-node dev cluster, so replication_factor = 1.

CREATE KEYSPACE IF NOT EXISTS chat WITH replication = {'class': 'NetworkTopologyStrategy', 'replication_factor': 1} AND tablets = {'enabled': true};
