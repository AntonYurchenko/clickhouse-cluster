CREATE TABLE IF NOT EXISTS db.data_dist ON CLUSTER docker AS db.data_rep
ENGINE = Distributed(docker, db, data_rep, rand())