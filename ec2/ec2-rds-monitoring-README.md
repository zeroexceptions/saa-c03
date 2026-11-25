# EC2 and RDS monitoring — SAA-C03 study guide

This guide explains the unique metrics from the Daymark EC2/ASG and RDS PostgreSQL lab. Repeated names in the console list refer to the same metric; `mydb` identifies the database, not another metric.

Study priorities below are recommendations, not an official list of exam questions. Learn what resource is under pressure and which architecture change addresses it before memorizing specialized metric names.

## How to read a CloudWatch graph

- **Metric:** what is measured, such as CPU or available storage.
- **Dimension:** which resource, such as an EC2 instance ID or RDS DB identifier.
- **Period:** time represented by one graph point.
- **Statistic:** how samples in that period are summarized. Average shows typical usage, Maximum exposes peaks, Minimum exposes the lowest remaining capacity, and Sum totals quantities such as transferred bytes.
- **Unit:** percent, bytes, seconds, count, or bytes/second. A byte count is not automatically a rate.

`DiskQueueDepth (Maximum)` is the maximum of the reported queue samples in each selected period. `FreeStorageSpace (Minimum)` is the lowest reported free space in each selected period. These are statistic choices, not separate metrics.

Compare the same time window and time zone across k6, EC2, ALB, and RDS. A brief peak alone does not establish a bottleneck; correlate sustained changes with latency and failures. Missing data does not mean zero or healthy.

## How a request travels through this app

The ports below follow the documented HTTP-only lab setup. This is the runtime request path; ECR and Secrets Manager participate when instances start.

```mermaid
sequenceDiagram
    participant Client as Browser or k6
    participant DNS as DNS resolver
    participant ALB as ALB listener :80
    participant App as EC2 Docker / Puma :3000
    participant Rails as Rails controller and DB pool
    participant DB as RDS PostgreSQL :5432
    Client->>DNS: Resolve the ALB hostname
    DNS-->>Client: ALB IP addresses
    Client->>ALB: GET /
    Note over ALB: Match listener rule and select target
    ALB->>App: Forward request to target private IP
    App->>Rails: Handle request with an available thread
    Rails->>DB: Borrow pooled connection and query tasks
    DB-->>Rails: Rows
    Note over Rails: Return connection to pool; render HTML
    Rails-->>App: HTTP 200 response
    App-->>ALB: Response
    ALB-->>Client: HTTP 200 and HTML
```

1. **DNS lookup:** the client resolves `web-scaling-1-1968462550.us-east-1.elb.amazonaws.com`. DNS answers may be cached; lookup is not required before every request.
2. **ALB listener:** the client connects to the ALB on HTTP port 80. The listener evaluates routing rules and forwards to the configured target group, `mytodo-app`.
3. **Target selection:** the ALB normally selects a healthy registered target, according to the target group's routing algorithm, and connects to its private IP on port 3000. The target group is a configuration/resource grouping, not another server that runs application code. A request goes to one selected target; it is not broadcast to every EC2 instance. [AWS request routing](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html), [listener routing](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
4. **Network access:** the ALB must be reachable by the client; the app security group permits port 3000 from the ALB security group; the RDS security group permits port 5432 from the app security group. These permissions allow connections; the groups do not execute or queue requests.
5. **Container and web server:** the configured Docker port mapping delivers the request to Puma in the running Rails container. Puma assigns application work to an available thread. Excess work can wait and eventually time out when capacity is exhausted.
6. **Rails routing:** `GET /` maps to `TodosController#index`. It loads a bounded task page and uses the brief cache for dashboard counts. A cold/expired count cache also causes an aggregate query.
7. **Connection pool and database:** Rails checks out a PostgreSQL connection from its process's pool, often reusing an existing connection. If the pool is exhausted, the request waits for one or hits its checkout timeout. PostgreSQL runs SQL using indexes/buffers/storage as needed; not every query requires a physical disk read. The connection returns to the pool when Rails releases it, rather than necessarily closing its network connection.
8. **Response:** Rails renders the task rows into HTML. The response returns through Puma and the ALB to the client. A browser can make additional requests for assets; the k6 script only makes the HTTP requests explicitly coded in it.

For `POST /todos`, Rails validates the CSRF token and task data, inserts the task into RDS, and returns a redirect on success. A browser normally follows the redirect with another GET. Your k6 POST sets `redirects: 0`, so it checks the redirect response without following it automatically.

### What happens separately from each request

- **Health checks:** the ALB periodically requests `/up` to assess targets. This is separate from the user's GET. This app uses the default Rails health action; it does not explicitly run a database-readiness check.
- **ASG:** manages EC2 capacity. CloudWatch metrics and the scaling policy can trigger additional instances; the ASG is not a proxy in the request path. Provisioning and application startup take time. [AWS target tracking](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html)
- **New-instance startup:** the launch template supplies the configuration and user data. The instance role authorizes image pulls from ECR and secret retrieval from Secrets Manager. Docker starts the app with those values. These services are not called again for every todo request in this deployment.
- **Shared database:** different requests can reach different EC2 instances, but all app instances connect to the same RDS database. Adding EC2 capacity does not automatically add RDS capacity.

The current repository defaults to two Puma processes with five threads each, unless runtime environment variables override those values. Each process has a separate Active Record pool, defaulting to five connections here: approximately ten potential application connections per instance. Pool sizes are ceilings, not connections necessarily opened immediately. Five such instances could use about 50 application connections, plus deployment overlap and other clients. This does not mean the fleet can only serve 50 users; connections and threads are reused across requests.

## EC2 metrics

| Console name / CloudWatch name | Meaning | Interpretation in this app |
|---|---|---|
| CPU utilization / `CPUUtilization` | CPU usage percentage across the instance. | Rendering tasks uses CPU. A busy core can be hidden by the instance average. Low CPU does not rule out database or thread waits. |
| Network in / `NetworkIn` | Bytes received across network interfaces during the period. | Includes HTTP requests, database results, and image downloads. |
| Network out / `NetworkOut` | Bytes sent across network interfaces during the period. | Includes HTML responses and outgoing database requests. |
| Network packets in / `NetworkPacketsIn` | Received packet count. | Packets are transport units, not HTTP requests or users; one request can span many packets. |

For byte metrics, use Sum divided by period seconds to obtain bytes/second. Example: 60,000,000 bytes over 60 seconds = 1,000,000 bytes/second, about 8 Mbps. Basic EC2 monitoring generally uses five-minute periods; detailed monitoring generally uses one-minute periods. The packet-count metric above is published at five-minute frequency. [AWS EC2 metrics reference](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/viewing_metrics_with_cloudwatch.html)

For SAA-C03, also remember that guest memory usage and filesystem free space require an agent/custom metric approach. They are not provided by the ordinary default EC2 metrics. [CloudWatch agent metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/metrics-collected-by-CloudWatch-agent.html)

## RDS CPU and burst credits

| Metric | Meaning |
|---|---|
| `CPUUtilization` | Percentage of database-instance CPU in use. |
| `CPUCreditBalance` | Earned CPU credits still available. |
| `CPUCreditUsage` | CPU credits consumed during the measurement interval. |
| `CPUSurplusCreditBalance` | Surplus credits spent in Unlimited mode that have not yet been paid down. |
| `CPUSurplusCreditsCharged` | Surplus credit usage that incurs an additional charge; the unit is credits, not dollars. |

One credit represents one vCPU at 100% for one minute. A hypothetical two-vCPU instance at 50% average for one minute uses one credit. Credits are also earned at the instance's baseline rate; the change in balance depends on both earning and spending. [AWS CPU credit concepts](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-credits-baseline-concepts.html)

Credit-based CPU behavior applies to burstable RDS T classes, not every RDS instance. In particular, RDS T3/T4g use Unlimited mode: a zero balance can lead to surplus use and charges rather than an immediate drop to baseline performance. Sustained demand is a reason to evaluate a suitable fixed-performance class. [RDS instance classes and credit behavior](https://aws.amazon.com/rds/instance-types/)

Credit metrics have five-minute frequency. For usage or charged credits over longer windows, use Sum; a balance is a remaining/current amount, so do not sum it across time. [RDS metric definitions](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html)

## RDS connections and active database load

| Metric | Meaning | How to interpret it |
|---|---|---|
| `DatabaseConnections` | Client network connections. | Open connections can be idle; this is not a user count or query rate. |
| `DBLoad` | Active sessions, usually viewed as average active sessions (AAS). | Includes work executing and work waiting. |
| `DBLoadCPU` | Active sessions attributed to CPU. | Compare with vCPU count and CPU utilization to investigate compute pressure. |
| `DBLoadNonCPU` | Active sessions attributed to non-CPU waits. | Inspect wait events for I/O, locks, and other causes. |
| `DBLoadRelativeToNumVCPUs` | DBLoad divided by vCPU count. | A ratio, not CPU percentage. Above 1 requires inspecting the CPU/wait split. |

The load definitions come from [AWS database-load metrics](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.Cloudwatch.html). CPU-attributed load consistently exceeding the available vCPUs is a stronger CPU contention clue than total DBLoad alone. [AWS CPU wait explanation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/ams-waits.cpu.html)

Illustrative example: a two-vCPU DB with DBLoad 6 has a relative load of 3. If most of those sessions are waiting on locks, buying more CPU might not resolve the main wait. Separately, 100 open client connections could coexist with only two active sessions.

### Check connections from PostgreSQL

Run these read-only queries through a database client connected to your RDS PostgreSQL instance:

```sql
SHOW max_connections;

SELECT state, count(*)
FROM pg_stat_activity
WHERE backend_type = 'client backend'
GROUP BY state;
```

`max_connections` is a connection ceiling, not a pool size or throughput target. Some slots are reserved. Rails has a separate pool per process; RDS Proxy provides another pooling layer. CloudWatch connection counts can differ from database-session counts because their inclusion rules differ. [RDS connections and limits](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html)

## RDS memory, storage, and network

| Metric | Meaning |
|---|---|
| `FreeableMemory` | Available RAM, including reclaimable memory. |
| `FreeStorageSpace` | Unused allocated database storage. |
| `DiskQueueDepth` | Outstanding storage I/O requests. |
| `EBSByteBalance%` | Remaining instance EBS throughput burst credits. |
| `EBSIOBalance%` | Remaining instance EBS I/O burst credits. |
| `InstanceEBSIOPSExceededCheck` | 1: attempted IOPS exceeded the DB instance class limit; 0: not exceeded. |
| `InstanceEBSThroughputExceededCheck` | 1: attempted throughput exceeded the DB instance class limit; 0: not exceeded. |
| `NetworkReceiveThroughput` | Incoming DB traffic, including monitoring and replication, in bytes/second. |

Metric availability depends on instance and engine support. The exceeded checks describe the last minute. Low free memory or a rising queue warrants investigation, not an automatic conclusion. [RDS metrics reference](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html)

IOPS means operations per second; throughput means bytes per second. Many small reads can exhaust IOPS while fewer large reads exhaust throughput. An instance's EBS capacity and its volumes' capacity are separate limits. Raising volume IOPS cannot bypass an instance-class ceiling. Pair queue depth with `ReadLatency`, `WriteLatency`, `ReadIOPS`, and `WriteIOPS`. [RDS storage performance](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html)

The two EBS balance metrics describe instance burst capability. Do not confuse them with `BurstBalance`, which describes gp2 volume I/O credits, or with CPU credits. High remaining balances mean burst capacity is available; they do not prove the whole database is healthy. [AWS instance EBS burst explanation](https://aws.amazon.com/blogs/compute/improving-application-performance-and-reducing-costs-with-amazon-ebs-optimized-instance-burst-capability/)

## Specialized PostgreSQL metrics

| Metric | Meaning | Study priority |
|---|---|---|
| `CheckpointLag` | Seconds since the latest checkpoint. | Lower. This is not read-replica lag; periodic rises and resets can be normal. |
| `MaximumUsedTransactionIDs` | Tracks transaction-ID age/usage relevant to wraparound risk. | Lower. It is not the number of active queries or todos. |

A checkpoint provides a recovery position by flushing prior changes to data files; checkpoint age is affected by checkpoint scheduling. Do not expect it to stay at zero. It is not a backup, and committed changes can already be durable in the write-ahead log before checkpointing. [RDS checkpoint metric](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html), [PostgreSQL checkpoint explanation](https://www.postgresql.org/docs/current/wal-configuration.html)

PostgreSQL needs vacuuming/freezing to manage transaction-ID age. Persistent growth in `MaximumUsedTransactionIDs` can indicate that vacuum is falling behind or blocked. Keep autovacuum enabled; investigate rather than treating a larger instance as a universal fix. [RDS autovacuum guidance](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum.html)

## What to prioritize for SAA-C03

These rankings are study guidance for architectural reasoning, not a claim that AWS excludes any metric from the exam.

| Priority | Remember | Connect it to |
|---|---|---|
| First | CPU utilization | Instance sizing, ASG target tracking, horizontal versus vertical scaling. |
| First | Network bytes versus packets versus rate | Traffic volume does not directly measure requests or remaining bandwidth. |
| First | CPU credit balance and Unlimited behavior | Burstable capacity, sustained workloads, extra cost. |
| First | Database connections | Connection ceilings, app pools, RDS Proxy. |
| First | Available memory and free storage | Capacity planning; RAM and disk space are different resources. |
| First | IOPS, throughput, latency, queue depth | Storage performance and instance/volume limits. |
| Next | DBLoad, DBLoadCPU, DBLoadNonCPU | Distinguish CPU execution from waits. |
| Next | EBS balances and exceeded checks | Bursting versus hard capacity ceilings. |
| Next | CPU usage/surplus credit metric names | Diagnose burst consumption and cost. |
| Later | CheckpointLag, MaximumUsedTransactionIDs | PostgreSQL operations and maintenance. |

Architecture choices to connect with monitoring:

- **RDS Proxy:** reuse connections; it does not add database compute capacity. [AWS RDS Proxy concepts](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.howitworks.html)
- **Read replicas:** distribute reads when the app routes reads to them; ordinary read replicas replicate asynchronously. **Traditional Multi-AZ DB instance standby:** availability and failover, not read scaling. Multi-AZ DB clusters are a different deployment type with readable instances. [AWS read replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html), [Multi-AZ DB instances](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZSingleStandby.html)
- **Storage autoscaling:** grows storage capacity; it does not autoscale database CPU or connections. [RDS storage autoscaling](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PIOPS.Autoscaling.html)

## Use these metrics during your load test

These are investigation patterns, not diagnoses of the current deployment:

| Observed together | Investigate next |
|---|---|
| High EC2 CPU, comfortable RDS load | Application compute, per-instance capacity, ASG limits. |
| Low EC2 CPU, high RDS CPU and CPU-attributed load | Database query cost and RDS instance sizing. |
| High non-CPU DB load | Specific waits before choosing a scaling action. |
| High storage latency and growing queue | Volume performance and instance EBS ceilings. |
| Connections approaching usable limit | Pool sizes, connection churn, and whether RDS Proxy fits. |
| Falling free storage | Data growth, retention, and storage capacity. |
| Falling CPU credits with rising surplus | Whether burstable pricing/capacity suits sustained load. |

For the next test, put EC2 CPU, healthy target count, RDS CPU, connections, memory, DB-load split, and storage latency on one aligned dashboard. Compare them with k6 error rate and p95 response time. Your 500-user run demonstrated low errors but p95 around 5.19 seconds; the graphs can help explain where that time is spent. No single graph proves that 5,000 users will succeed.
