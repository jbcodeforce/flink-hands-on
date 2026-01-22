# Confluent Flink Offering Hands-on

This repository includes a set of simple demo / hands-on labs with Confluent Flink: Cloud or Platform.

## Pre-requisites

* Get Confluent Cloud access
* Define a tf_runner service account
* Define a Confluent API Key and Secret for the `tf_runner` service account


## Hands-on

The first terraform will create Confluent Cloud Environment, Service Accounts, Kafka Cluster and Schema Registry

1. [x] Create Confluent Environment, Service Account, Kafka Cluster and Schema Registry [1-confluent-cloud-infrastructure/](./1-confluent-cloud-infrastructure/) 
1. [x] Validate CDC source connectors for RDS Postgres. See [cdc-postgres-to-cc-flink/readme](./2-cdc-postgres-to-cc-flink/README.md)
* [x] UDF deployed and executing in CC Flink. See [Explode UDF deployment readme](./explode-udf-deployment/)
* [x] Iceberg Integration with Tableflow. [3-iceberg-tableflow](./3-iceberg-tableflow/)
* [ ] CEP features with relevant use cases: pattern detection, event sequences
* [ ] Stateful Processing: aggregation with windowing for Fraud detection
* [ ] Exactly-Once Semantics and Reconciliation

## Source of knowledge

* [Confluent Cloud Flink](https://docs.confluent.io/cloud/current/flink/overview.html)
* [Confluent cloud Connectors](https://docs.confluent.io/cloud/current/connectors/overview.html)
* [Confluent Cloud RBAC](https://docs.confluent.io/cloud/current/security/access-control/rbac/overview.html)
* [Confluent Terraform Provider](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs)
* [Confluent Terraform Examples](https://github.com/confluentinc/terraform-provider-confluent/tree/master/examples/configurations)
* [Confluent Cloud User Defined Function](https://docs.confluent.io/cloud/current/flink/concepts/user-defined-functions.html)
* [Jerome Boyer's Flink Studies living book](https://jbcodeforce.github.io/flink-studies/) with [stateful processing](https://jbcodeforce.github.io/flink-studies/coding/flink-sql-2/#stateful-aggregations)