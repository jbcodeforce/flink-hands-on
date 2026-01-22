CREATE TABLE transactions (
    tx_id STRING,
    account_number STRING,
    merchant STRING,
    transaction_type STRING,
    amount DECIMAL(10, 2),
    ts_ms STRING
) WITH (
    'connector' = 'filesystem',
    'path' = '/Users/jerome/Documents/Code/flink-hands-on/stateful_processing/data/tx.csv',
    'format' = 'csv'
);