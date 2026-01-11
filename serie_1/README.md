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
