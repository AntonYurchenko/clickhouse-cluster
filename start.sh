#!/bin/bash

up_zoo() {
    docker-compose up -d zoo1 zoo2 zoo3
    sleep 10
}

up_clickhouse() {
    docker-compose up -d ch_sd1_rp1 ch_sd1_rp2 ch_sd2_rp1 ch_sd2_rp2
    sleep 10
}

up_liquibase() {
    docker-compose up liquibase
    sleep 10
}

send() {
    curl -X POST -u 'default:' -d "${1}" localhost:8123
}

up_zoo && up_clickhouse && up_liquibase

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