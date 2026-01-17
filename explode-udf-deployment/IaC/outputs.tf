# Outputs for the Explode UDF deployment

output "artifact_id" {
  description = "The ID of the uploaded Flink artifact"
  value       = confluent_flink_artifact.main.id
}

output "artifact_version" {
  description = "The version ID of the uploaded Flink artifact"
  value       = confluent_flink_artifact.main.versions[0].version
}

output "artifact_name" {
  description = "The display name of the Flink artifact"
  value       = confluent_flink_artifact.main.display_name
}

output "create_function_sql" {
  description = "SQL statement to create the EXPLODE function (if not already created by Terraform)"
  value       = "CREATE FUNCTION EXPLODE AS 'io.confluent.udf.ExplodeFunction' USING JAR 'confluent-artifact://${confluent_flink_artifact.main.id}/${confluent_flink_artifact.main.versions[0].version}';"
}

output "usage_example" {
  description = "Example SQL query using the EXPLODE function"
  value       = "SELECT t.sub_string FROM LATERAL TABLE(EXPLODE(ARRAY['ab','bc','cd'])) AS t(sub_string);"
}
