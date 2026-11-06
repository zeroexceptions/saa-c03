# Database Terminology: Instance, Node, Cluster
 
**Mental model:** `cluster → nodes → one instance per node (typically)`
 
## Databases (e.g., PostgreSQL, MySQL, Oracle, Cassandra)
 
- **Instance:** a running database server process (plus its memory structures) that serves client connections, typically on a port. In Oracle, the instance is distinct from the database files it operates on.
- **Node:** a single server (physical or virtual) participating in a distributed or replicated database deployment, typically running one instance.
- **Cluster:** a group of nodes cooperating (via replication, sharding, or both) to provide one logical database.
  - **Note:** in PostgreSQL, "cluster" instead refers to the set of databases managed by one instance.
 


# Non-Functional Requirements

## Core Requirements

- **Availability:** The system is up and reachable when users need it. *Example: the site is accessible 99.99% of the year, so downtime is under an hour.*
- **Reliability:** The system produces correct results consistently, without failing. *Example: every payment is charged exactly once, with the right amount.*
- **Scalability:** Capacity grows by adding resources instead of rewriting code. *Example: traffic triples on Black Friday, so you add servers behind the load balancer and it keeps working.*
- **Fault tolerance:** The system keeps running when a component breaks. *Example: one of two app servers crashes and users notice nothing because the other takes over.*
- **Performance:** The system responds quickly and handles high throughput (thorughput and latency comes under permformance). *Example: the product page loads in under 200 ms at p95, serving 1,000 requests per second.*

## Related Requirements

- **Resilience:** The system bounces back from failures and degrades gracefully instead of breaking completely. *Example: the recommendations service is down, but users can still browse and check out.*
- **Durability:** Once data is stored, it is not lost. *Example: an uploaded file to S3 survives disk failures because it is replicated across multiple facilities.*
- **Recoverability / disaster recovery:** The system can be restored after a major failure within defined limits. *Example: the region goes down, and you restore service within 1 hour (RTO) with at most 5 minutes of lost data (RPO).*
- **Maintainability:** The system is easy to change, fix, and extend. *Example: a new developer adds a payment method in a day because the code is modular and tested.*
- **Security:** The system protects data and access from unauthorized use. *Example: passwords are hashed, data is encrypted in transit, and users can only see their own orders.*
- **Observability:** You can understand what's happening inside the system from its outputs. *Example: when checkout slows down, logs, metrics, and traces (like X-Ray) show that the payment API call is the bottleneck.*