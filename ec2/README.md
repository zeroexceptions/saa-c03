AMI → "I want Ubuntu 22.04" (the OS/software)
Instance type → "I want it to run on a t3.micro" (1 vCPU, 1GB RAM — the hardware)

you can provide a script to ec2 userData to have cloud init automatically run on first boot.




General Purpose
A1, T2, T3, T3a, T4g, M4, M5, M5a, M5n, M6zn, M6g, M6i, Mac
Balance of compute, memory and networking resources
Use-cases: web servers and code repositories

Compute Optimized
C5, C4, C6a, C5n, C6g, C6gn
Ideal for compute bound applications that benefit from high performance processor
Use-cases: scientific modeling, dedicated gaming servers and ad server engines

Memory Optimized
R4, R5, R5a, R5b, R5n, X1, X1e, High Memory, z1d
Fast performance for workloads that process large data sets in memory.
Use-cases: in-memory caches, in-memory databases, real time big data analytics

Accelerated Optimized
P2, P3, P4, G3, G4ad, G4dn, F1, Inf1, VT1
Hardware accelerators, or co-processors
Use-cases: Machine learning, computational finance, seismic analysis, speech recognition

Storage Optimized
I3, I3en, D2, D3, D3en, H1

Explanation of each category

1. General Purpose — The "jack of all trades." No single resource (CPU, memory, network) is heavily favored over another, so it's a safe default when you're unsure of your bottleneck. That's why it fits web servers: request handling is usually balanced across CPU + memory + I/O, not dominated by one factor.

2. Compute Optimized — Prioritizes raw CPU power over memory/storage. Best when your workload is CPU-bound (heavy calculations, simulations). That's why gaming servers (physics calculations, tick rates) and scientific modeling (number-crunching) fit here — they need fast processors more than lots of RAM.

3. Memory Optimized — Prioritizes large RAM capacity relative to CPU. Ideal when your whole dataset needs to live in memory for speed (avoiding slow disk reads). This is why in-memory databases (like Redis) and real-time analytics (processing huge live data streams) fit — they're bottlenecked by how much data fits in RAM, not CPU cycles.

4. Accelerated Computing — Includes specialized hardware beyond a standard CPU — GPUs (P, G families), FPGAs (F family), and inference chips (Inf family). Needed when a task is too specialized/parallel for a regular CPU to handle efficiently. That's why machine learning training (needs massively parallel GPU math) and speech recognition (neural network inference) fit here.

5. Storage Optimized — Prioritizes fast, high-throughput local disk I/O over CPU/memory. Best for workloads reading/writing huge volumes of data quickly (not shown with use-cases in your image, but typically: distributed file systems, data warehousing, and NoSQL databases like Cassandra that need constant fast disk access).

The general pattern to remember: each family sacrifices something to maximize its specialty — General Purpose is the balanced option, and the other four exist because a "balanced" instance would be inefficient/expensive if your actual bottleneck is just one specific resource (compute, memory, accelerators, or storage).


ec2 instance states



An AMI holds the following information:

A template for the root volume for the instance (EBS Snapshot or Instance Store template) — e.g., an operating system, an application server, and applications
Launch permissions that control which AWS accounts can use the AMI to launch instances
A block device mapping that specifies the volumes to attach to the instance when it's launched

A few extra details worth noting:

AMIs are region-specific — the same AMI must be copied to be used in another region, which gives it a new AMI ID.
AMIs also carry basic metadata like architecture (x86_64/arm64), virtualization type (HVM/PV), and root device type (EBS-backed vs instance-store-backed).