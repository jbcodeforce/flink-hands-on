INSERT INTO tx_enriched
SELECT 
    t.txn_id,
    TO_TIMESTAMP(REGEXP_REPLACE(COALESCE(`timestamp`, '2000-01-01T00:00:00.000000Z'),'T|Z',' '), 'yyyy-MM-dd HH:mm:SSSSSS') AS `timestamp`,
    t.amount,
    t.currency,
    t.merchant,
    t.location,
    t.status,
    t.transaction_type,
    -- Customer enrichment
    c.account_number,
    c.customer_name,
    c.email AS customer_email,
    c.city AS customer_city
FROM `txp.public.transactions` t
-- Join with customers using temporal join (latest version)
LEFT JOIN `txp.public.customers` as c
    ON t.account_number = c.account_number
