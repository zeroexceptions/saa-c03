# ElastiCache Memcached vs Redis vs MemoryDB (SAA-C03)

All three are in-memory, so the exam tests what the data's role is (a cache or the system of record) and what failure behavior it needs.

## Comparison

| | ElastiCache Memcached | ElastiCache Redis | MemoryDB |
| --- | --- | --- | --- |
| Role | Pure cache | Cache (can also be a light data store) | Primary database |
| Source of truth | The backing database | The backing database | MemoryDB itself |
| Durability | None, data is lost on node failure or restart | Optional (snapshots, AOF), not the intended design | Yes, Multi-AZ transaction log |
| Multi-AZ failover / replicas | No | Yes | Yes |
| Data structures | Simple key-value strings | Rich (sorted sets, lists, hashes, pub/sub) | Rich, Redis-compatible |
| Multi-threaded | Yes | No | No |
| Latency | Sub-millisecond | Sub-millisecond | Microsecond reads, single-digit ms writes |

## Keywords that decide the answer

- Simple caching, multithreaded, scale out by adding nodes, no persistence needed: **Memcached**.
- Cache with high availability, replication, backup, leaderboard, pub/sub, complex data types: **ElastiCache Redis**.
- Redis as the **primary database**, durable, no separate database behind it, ultra-fast: **MemoryDB**.

## Common traps

- Automatic failover or replicas needed: Memcached is wrong, it has neither.
- Data must survive a node failure: Memcached is wrong. If the in-memory store is also the only database, ElastiCache Redis is wrong too and the answer is MemoryDB.
- ElastiCache needs a database behind it and application code that checks the cache first. If the scenario says to replace the database, it is not ElastiCache.
- MemoryDB costs more, so if the goal is only to reduce load on an existing RDS or Aurora database, choose ElastiCache.
- For DynamoDB specifically, the cache is **DAX**, not ElastiCache or MemoryDB.
- Redis persistence on ElastiCache does not make it a database for exam purposes: durable and primary means MemoryDB.