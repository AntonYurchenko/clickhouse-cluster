# The simple clickhouse cluster on docker containers
Version: `v1.0.0`

## Structure schema
```text

               Zookeeper cluster
          +----+     +----+     +----+ 
          |zoo1| --- |zoo2| --- |zoo3|
          +----+     +----+     +----+

      Clickhouse cluster with replication
        +----------+        +----------+
        |ch_sd1_rp1| <===>  |ch_sd2_rp1|
        +----------+        +----------+
            //                    \\
    +----------+                +----------+
    |ch_sd1_rp2|                |ch_sd2_rp2|
    +----------+                +----------+

```
### Description
The project contains two cluster. Those is Zookeeper cluster which consist of three nodes, and Clickhouse cluster consist of two shards with replication.

## Upping the cluster
You need to have next environments:
* git
* docker
* docker-compose
* bash
* curl
  
After installation of all environments you need to clone this repository and run script `start.sh`
```bash
git clone https://github.com/AntonYurchenko/clickhouse-cluster.git
cd clickhouse-cluster
chmod +x ./start.sh ./stop.sh
./start.sh
```

A script `start.sh` ups all nodes of Zookeeper cluster and, after pause in 20 seconds, ups all nodes of Clickhouse cluster.
After upping of all cluster parts initialization and test of data manipulation will be started.

### Full algorithm of test
```sql
-- Initialization data base and tables
CREATE DATABASE IF NOT EXISTS db ON CLUSTER docker;
DROP TABLE IF EXISTS db.data_dist ON CLUSTER docker;
DROP TABLE IF EXISTS db.data_rep ON CLUSTER docker;

-- Creation of a replicated table for saving data
CREATE TABLE IF NOT EXISTS db.data_rep ON CLUSTER docker
(
    event_data Date,
    text       String
) ENGINE = ReplicatedMergeTree() PARTITION BY event_data ORDER BY event_data;


-- Creation of a distrebuted table on base raplicated table
CREATE TABLE IF NOT EXISTS db.data_dist ON CLUSTER docker AS db.data_rep
ENGINE = Distributed(docker, db, data_rep, rand());

-- Insert data to a target table
INSERT INTO db.data_dist (event_data, text)
VALUES ('2021-01-01', 'text 1'),
       ('2021-01-01', 'text 2'),
       ('2021-01-01', 'text 3'),
       ('2021-01-01', 'text 4'),
       ('2021-01-01', 'text 5'),
       ('2021-01-02', 'text 1'),
       ('2021-01-02', 'text 2'),
       ('2021-01-02', 'text 3'),
       ('2021-01-02', 'text 4'),
       ('2021-01-02', 'text 5'),
       ('2021-01-03', 'text 1'),
       ('2021-01-03', 'text 2'),
       ('2021-01-03', 'text 3'),
       ('2021-01-03', 'text 4'),
       ('2021-01-03', 'text 5');
OPTIMIZE TABLE db.data_rep ON CLUSTER docker FINAL;

-- Target table contains next rows
SELECT event_data, text
FROM db.data_dist
ORDER BY event_data, text 
FORMAT TSVWithNames;

-- Removing a partition 2021-01-01
ALTER TABLE db.data_rep ON CLUSTER docker DROP PARTITION '2021-01-01';

-- Target table contains next rows after removing partition 2021-01-01
SELECT event_data, text
FROM db.data_dist
ORDER BY event_data, text 
FORMAT TSVWithNames;
```

## Downing the cluster
Run `./stop.sh` for stopping of all cluster parts.