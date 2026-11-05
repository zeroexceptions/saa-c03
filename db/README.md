# Database Terminology: Instance, Node, Cluster
 
**Mental model:** `cluster → nodes → one instance per node (typically)`
 
## Databases (e.g., PostgreSQL, MySQL, Oracle, Cassandra)
 
- **Instance:** a running database server process (plus its memory structures) that serves client connections, typically on a port. In Oracle, the instance is distinct from the database files it operates on.
- **Node:** a single server (physical or virtual) participating in a distributed or replicated database deployment, typically running one instance.
- **Cluster:** a group of nodes cooperating (via replication, sharding, or both) to provide one logical database.
  - **Note:** in PostgreSQL, "cluster" instead refers to the set of databases managed by one instance.
 