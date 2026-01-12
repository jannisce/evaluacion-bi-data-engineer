-- =============================================================================
-- Script: 02_create_staging_table.sql
-- Descripción: Creación de tabla staging para carga inicial de datos
-- =============================================================================

USE BankChurnDW;
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
