### Command to create serverless elasticache

```sh
aws elasticache create-serverless-cache \
--serverless-cache-name my-cache-ab-5252 \
 --major-engine-version 7 --engine redis
```

####  I can't connect to elasticache from local, there need to be an aws resource in the same
#### vpc


# Connect to instance

```sh
redis-cli -h my-cache-ab-5252-ehplt6.serverless.cac1.cache.amazonaws.com
```