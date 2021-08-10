#!/bin/bash

up_zoo() {
    docker-compose up -d zoo1 zoo2 zoo3
    sleep 20
}

up_clickhouse() {
    docker-compose up -d
    sleep 20
}

send() {
    curl -X POST -u 'default:' -d "${1}" localhost:8123
}

up_zoo && up_clickhouse

send "SELECT '[INFO] Initialization data base and tables'"
send "CREATE DATABASE IF NOT EXISTS db ON CLUSTER docker"
send "DROP TABLE IF EXISTS db.data_dist ON CLUSTER docker"
send "DROP TABLE IF EXISTS db.data_rep ON CLUSTER docker"

send "SELECT '[INFO] Creation of a replicated table for saving data'"
send "
CREATE TABLE IF NOT EXISTS db.data_rep ON CLUSTER docker
(
    event_data Date,
    text       String
) ENGINE = ReplicatedMergeTree() PARTITION BY event_data ORDER BY event_data
"

send "SELECT '[INFO] Creation of a distrebuted table on base raplicated table'"
send "
CREATE TABLE IF NOT EXISTS db.data_dist ON CLUSTER docker AS db.data_rep
ENGINE = Distributed(docker, db, data_rep, rand())
"

send "SELECT '[INFO] Insert data to a target table'"
send "
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
       ('2021-01-03', 'text 5')
"
send "OPTIMIZE TABLE db.data_rep ON CLUSTER docker FINAL"

send "SELECT '[INFO] Target table contains next rows'"
send "
SELECT event_data, text
FROM db.data_dist
ORDER BY event_data, text 
FORMAT TSVWithNames
"

send "SELECT '[INFO] Removing a partition 2021-01-01'"
send "ALTER TABLE db.data_rep ON CLUSTER docker DROP PARTITION '2021-01-01'"

send "SELECT '[INFO] Target table contains next rows after removing partition 2021-01-01'"
send "
SELECT event_data, text
FROM db.data_dist
ORDER BY event_data, text 
FORMAT TSVWithNames
"

send "SELECT '[INFO] Initialization has been successful finished'"