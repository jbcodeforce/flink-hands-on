# Explode Function UDF for Confluent Cloud Flink

This project implements a User Defined Function (UDF) for Apache Flink that generates a sequence of string as row from a list of string.

## Usage

The EXPLODE function generates a row per string in the list or array of strings provided as input. It can be used in combination with JOIN LATERAL to generate rows in Flink SQL.

### Example Usage with Confluent Cloud Flink


```sql
-- Generate a 
SELECT 
 t.sub_string 
from lateral table(EXPLODE(ARRAY['ab','bc','cd'])) AS t(sub_string);
```

## Building the UDF

To build the UDF JAR file:

```bash
mvn clean package
```

The JAR file will be created in the `target` directory.


## Testing

Run the tests using:

```bash
mvn test
```

## Deploying to Confluent Cloud

[See Confluent cloud product documentation.](https://docs.confluent.io/cloud/current/flink/concepts/user-defined-functions.html)

* Be sure to have a user or service account with FlinkDeveloper RBAC to be able to manage workspaces and artifacts
* Use the Confluent CLI to upload the jar file. Example
    ```sh
    confluent environment list
    # then in your environment
    confluent flink artifact create sequence --artifact-file target/explode-function-1.0-0.jar --cloud aws --region us-west-2 --environment env-nk...
    ```

* Declare the function in the Catalog using SQL and Confluent Cloud Workspace
```sql
CREATE FUNCTION EXPLODE
AS
'io.confluent.udf.ExplodeFunction'
USING JAR 'confluent-artifact://cfa-qj...';
```
