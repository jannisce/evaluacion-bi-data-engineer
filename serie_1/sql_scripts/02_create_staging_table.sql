-- =============================================================================
-- Script: 02_create_staging_table.sql
-- Descripción: Creación de tabla staging para carga inicial de datos
-- =============================================================================

USE BankChurnDW;
GO

-- Crear tabla staging para datos en bruto (raw)

-- Eliminar tabla staging si existe
IF OBJECT_ID('staging.CustomerChurn_Raw', 'U') IS NOT NULL
    DROP TABLE staging.CustomerChurn_Raw;
GO

-- Crear tabla staging para datos en bruto (raw)
CREATE TABLE staging.CustomerChurn_Raw
(
    customer_id         NVARCHAR(50) NULL,
    credit_score        NVARCHAR(50) NULL,
    country             NVARCHAR(100) NULL,
    gender              NVARCHAR(50) NULL,
    age                 NVARCHAR(50) NULL,
    tenure              NVARCHAR(50) NULL,
    balance             NVARCHAR(50) NULL,
    products_number     NVARCHAR(50) NULL,
    credit_card         NVARCHAR(50) NULL,
    active_member       NVARCHAR(50) NULL,
    estimated_salary    NVARCHAR(50) NULL,
    churn               NVARCHAR(50) NULL
);
GO

-- Eliminar tabla staging si existe
IF OBJECT_ID('staging.CustomerChurn', 'U') IS NOT NULL
    DROP TABLE staging.CustomerChurn;
GO

-- Crear tabla staging que refleja el dataset original
CREATE TABLE staging.CustomerChurn
(
    customer_id         INT             NOT NULL,
    credit_score        INT             NOT NULL,
    country             NVARCHAR(50)    NOT NULL,
    gender              NVARCHAR(10)    NOT NULL,
    age                 INT             NOT NULL,
    tenure              INT             NOT NULL,
    balance             DECIMAL(18,2)   NOT NULL,
    products_number     INT             NOT NULL,
    credit_card         INT             NOT NULL,
    active_member       INT             NOT NULL,
    estimated_salary    DECIMAL(18,2)   NOT NULL,
    churn               INT             NOT NULL,
    load_date           DATETIME        DEFAULT GETDATE()
);
GO

-- Índice para optimizar búsquedas durante transformación
CREATE NONCLUSTERED INDEX IX_Staging_CustomerChurn_CustomerID
ON staging.CustomerChurn (customer_id);
GO

PRINT 'Tabla staging.CustomerChurn creada exitosamente.';
GO
