CREATE TABLE IF NOT EXISTS db.data_rep ON CLUSTER docker
(
    event_data Date,
    text       String
) ENGINE = ReplicatedMergeTree() PARTITION BY event_data ORDER BY event_data