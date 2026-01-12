-- =============================================================================
-- Script: 04_create_fact_table.sql
-- Creación de tabla de hechos principal
-- =============================================================================

USE BankChurnDW;
GO

-- Tabla de Hechos - FACT_CUSTOMER_STATUS
IF OBJECT_ID('fact.CustomerStatus', 'U') IS NOT NULL
    DROP TABLE fact.CustomerStatus;
GO

CREATE TABLE fact.CustomerStatus
(
    fact_id             BIGINT IDENTITY(1,1)    PRIMARY KEY,
    customer_key        INT                     NOT NULL,
    geography_key       INT                     NOT NULL,
    demographics_key    INT                     NOT NULL,
    product_key         INT                     NOT NULL,
    date_key            INT                     NOT NULL,

    -- Métricas
    credit_score        INT                     NOT NULL,
    balance             DECIMAL(18,2)           NOT NULL,
    estimated_salary    DECIMAL(18,2)           NOT NULL,
    tenure_years        INT                     NOT NULL,

    -- Flags
    is_active_member    BIT                     NOT NULL,
    has_credit_card     BIT                     NOT NULL,
    churn_flag          BIT                     NOT NULL,

    -- Auditoría
    created_date        DATETIME                DEFAULT GETDATE(),

    -- Foreign Keys
    CONSTRAINT FK_Fact_Customer FOREIGN KEY (customer_key) REFERENCES dim.Customer (customer_key),
    CONSTRAINT FK_Fact_Geography FOREIGN KEY (geography_key) REFERENCES dim.Geography (geography_key),
    CONSTRAINT FK_Fact_Demographics FOREIGN KEY (demographics_key) REFERENCES dim.Demographics (demographics_key),
    CONSTRAINT FK_Fact_Product FOREIGN KEY (product_key) REFERENCES dim.Product (product_key),
    CONSTRAINT FK_Fact_Date FOREIGN KEY (date_key) REFERENCES dim.Date (date_key)
);
GO

-- =============================================================================
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- =============================================================================

-- Índices columnares para análisis OLAP
CREATE NONCLUSTERED COLUMNSTORE INDEX CCI_FactCustomerStatus
ON fact.CustomerStatus (
    customer_key, geography_key, demographics_key, product_key, date_key,
    credit_score, balance, estimated_salary, tenure_years,
    is_active_member, has_credit_card, churn_flag
);
GO

-- Índices para joins frecuentes
CREATE NONCLUSTERED INDEX IX_Fact_CustomerKey ON fact.CustomerStatus (customer_key);
CREATE NONCLUSTERED INDEX IX_Fact_GeographyKey ON fact.CustomerStatus (geography_key);
CREATE NONCLUSTERED INDEX IX_Fact_DemographicsKey ON fact.CustomerStatus (demographics_key);
CREATE NONCLUSTERED INDEX IX_Fact_ProductKey ON fact.CustomerStatus (product_key);
CREATE NONCLUSTERED INDEX IX_Fact_DateKey ON fact.CustomerStatus (date_key);
GO

-- Índice compuesto para consultas de churn
CREATE NONCLUSTERED INDEX IX_Fact_ChurnAnalysis
ON fact.CustomerStatus (churn_flag, geography_key, demographics_key)
INCLUDE (credit_score, balance, is_active_member);
GO

-- Índice para análisis de clientes activos
CREATE NONCLUSTERED INDEX IX_Fact_ActiveMember
ON fact.CustomerStatus (is_active_member, has_credit_card)
INCLUDE (customer_key, geography_key);
GO

PRINT 'Tabla de hechos fact.CustomerStatus creada exitosamente.';
GO
