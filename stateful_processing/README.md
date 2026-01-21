# Stateful processing on transaction for Fraud Detection

## SQL Client

* Start SQL Client with 
    ```sh
    $FLINK_HOME/bin/sql-client.sh
    ```
* Set Catalog
    ```sql
    show catalogs;
    use catalog default_catalog;
    show databases;
    ```

* Create a transaction table from the csv data
    ```sql
    use default_database;

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
    ```

* Assess Fraud for 2 tx in same merchat withing 10 minutes
    ```sql
    with tx_ts as (
        select tx_id,account_number, merchant, transaction_type, amount,  to_timestamp_ltz(ts_ms, 'yyyy-MM-dd HH:mm:ss') as ts_ms from transactions
    )
    select 

        window_start,
        window_end,
        account_number,
        sum(amount) as total
    from TABLE(
        TUMBLE(
            TABLE transactions,
            DESCRIPTOR( to_timestamp_ltz(ts_ms, 'yyyy-MM-dd HH:mm:ss')), INTERVAL '10' MINUTES
        ))
    GROUP BY window_start, window_end,         account_number;


    SELECT 
    window_start,
    window_end,
    account_number,
    sum(amount) as total
    FROM TABLE(
        TUMBLE(
            TABLE (
                SELECT 
                    ts_ms,
                    to_timestamp_ltz(ts_ms, 'yyyy-MM-dd HH:mm:ss') as converted_timestamp,
                    account_number,
                    amount
                FROM transactions
            ),
            DESCRIPTOR(converted_timestamp),
            INTERVAL '10' MINUTES
        )
    )
    GROUP BY window_start, window_end, account_number;
    ```


