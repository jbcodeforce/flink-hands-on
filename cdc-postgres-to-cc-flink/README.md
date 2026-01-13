

```mermaid
flowchart LR
    subgraph VPC [Existing AWS VPC]
        RDS[(RDS PostgreSQL<br/>customers + transactions)]
    end
    
    subgraph CC [Confluent Cloud]
        CDC[CDC Debezium v2<br/>PostgresCdcSourceV2]
        
        subgraph Topics [Kafka Topics]
            T1[card-tx.public.customers]
            T2[card-tx.public.transactions]
            T3[card-tx-enriched-transactions]
            T4[card-tx-tx-aggregations]
            T5[card-tx-ml-results]
        end
        
        Flink[Flink Compute Pool]
    end
    
    RDS --> CDC
    CDC --> T1
    CDC --> T2
    T1 --> Flink
    T2 --> Flink
    Flink --> T3
    Flink --> T4
    Flink --> T5
```



## Component List

| Component | Description | Resource Naming |
|-----------|-------------|-----------------|
| RDS PostgreSQL | Database with customers and transactions tables | `card-tx-db-{id}` |
| VPC | Existing VPC (passed via terraform variable) | N/A |
| CDC Debezium v2 | Source connector capturing changes from PostgreSQL | `card-tx-cdc-source` |
| Flink Compute Pool | Processing Debezium messages, enrichment, aggregations | `card-tx-compute-pool-{id}` |


