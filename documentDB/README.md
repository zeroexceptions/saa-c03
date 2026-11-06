# Amazon DocumentDB Ruby connection

Set these environment variables before running `ruby ./main.rb`:

```sh
export DOCDB_URI='mongodb://<your-cluster-endpoint>:27017'
export DOCDB_USER='<database-user>'
export DOCDB_PASSWORD='<database-password>'
ruby ./main.rb
```

The client uses `global-bundle.pem` for TLS verification. DocumentDB is normally
reachable only from within its VPC (or through a configured VPN, peering, or
bastion/SSH tunnel); allowing your IP in the cluster security group alone does
not create a route from the public internet.
