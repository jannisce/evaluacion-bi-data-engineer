# Serie I - Transformación de Datos y Modelado

## Descripción

Implementación del esquema Snowflake para el Data Warehouse de Bank Customer Churn

## Instrucciones de Ejecución

### Iniciar SQL Server en Docker

```bash
cd serie_1
docker compose up -d
```

### Interactuar con base de datos

```bash
docker exec -it sqlserver_churn bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -C
```

### Ejecutar los scripts SQL en orden

```bash
# Crear base de datos
docker exec -it sqlserver_churn /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -i /scripts/01_create_database.sql -C

# Crear tabla staging
docker exec -it sqlserver_churn /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -d BankChurnDW -i /scripts/02_create_staging_table.sql -C

# Crear dimensiones
docker exec -it sqlserver_churn /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -d BankChurnDW -i /scripts/03_create_dimension_tables.sql -C

# Crear tabla de hechos
docker exec -it sqlserver_churn /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -d BankChurnDW -i /scripts/04_create_fact_table.sql -C

# Cargar datos de referencia
docker exec -it sqlserver_churn /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -d BankChurnDW -i /scripts/05_load_reference_data.sql -C

# Crear procedimientos almacenados
docker exec -it sqlserver_churn /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -d BankChurnDW -i /scripts/06_stored_procedures.sql -C

# Cargar datos y ejecutar ETL
docker exec -it sqlserver_churn /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -d BankChurnDW \
-Q "EXEC dbo.sp_ETL_Full @FilePath = '/raw_data/Bank Customer Churn Prediction.csv';" -C

# Crear vistas
docker exec -it sqlserver_churn /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -d BankChurnDW -i /scripts/07_views.sql -C

# Consultas de validacion
docker exec -it sqlserver_churn /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -d BankChurnDW -i /scripts/08_validation_queries.sql -C \
> ./results/exec_scripts_08-validation-queries-output.txt
```
