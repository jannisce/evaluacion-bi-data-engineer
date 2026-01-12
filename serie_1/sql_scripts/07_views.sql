-- =============================================================================
-- Script: 08_views.sql
-- Vistas para facilitar el análisis y consultas frecuentes
-- =============================================================================

USE BankChurnDW;
GO

-- =============================================================================
-- VISTA: Análisis completo de clientes (desnormalizada para reportes)
-- =============================================================================
IF OBJECT_ID('dbo.vw_CustomerAnalysis', 'V') IS NOT NULL
    DROP VIEW dbo.vw_CustomerAnalysis;
GO

CREATE VIEW dbo.vw_CustomerAnalysis
AS
SELECT
    -- Cliente
    cust.customer_id AS CustomerID,
    cust.customer_name AS CustomerName,

    -- Geografía
    c.country_name AS Country,
    c.continent AS Continent,

    -- Demografía
    gend.gender_description AS Gender,
    d.age AS Age,
    ar.age_range_description AS AgeRange,
    gen.generation_name AS Generation,

    -- Producto
    p.products_number AS ProductsNumber,
    p.product_category AS ProductCategory,

    -- Métricas
    f.credit_score AS CreditScore,
    f.balance AS Balance,
    f.estimated_salary AS EstimatedSalary,
    f.tenure_years AS TenureYears,

    -- Flags
    CASE WHEN f.is_active_member = 1 THEN 'Active' ELSE 'Inactive' END AS MemberStatus,
    CASE WHEN f.has_credit_card = 1 THEN 'Yes' ELSE 'No' END AS HasCreditCard,
    CASE WHEN f.churn_flag = 1 THEN 'Churned' ELSE 'Retained' END AS ChurnStatus,
    f.churn_flag AS ChurnFlag,
    f.is_active_member AS IsActiveMember,
    f.has_credit_card AS HasCreditCardFlag

FROM fact.CustomerStatus f
INNER JOIN dim.Customer cust ON f.customer_key = cust.customer_key
INNER JOIN dim.Geography geo ON f.geography_key = geo.geography_key
INNER JOIN dim.Country c ON geo.country_key = c.country_key
INNER JOIN dim.Demographics d ON f.demographics_key = d.demographics_key
INNER JOIN dim.Gender gend ON d.gender_key = gend.gender_key
INNER JOIN dim.AgeRange ar ON d.age_range_key = ar.age_range_key
INNER JOIN dim.Generation gen ON d.generation_key = gen.generation_key
INNER JOIN dim.Product p ON f.product_key = p.product_key;
GO

-- =============================================================================
-- VISTA: Métricas de Churn por País
-- =============================================================================
IF OBJECT_ID('dbo.vw_ChurnByCountry', 'V') IS NOT NULL
    DROP VIEW dbo.vw_ChurnByCountry;
GO

CREATE VIEW dbo.vw_ChurnByCountry
AS
SELECT
    c.country_name AS Country,
    COUNT(*) AS TotalCustomers,
    SUM(CAST(f.churn_flag AS INT)) AS ChurnedCustomers,
    COUNT(*) - SUM(CAST(f.churn_flag AS INT)) AS RetainedCustomers,
    CAST(100.0 * SUM(CAST(f.churn_flag AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS ChurnRate,
    AVG(f.credit_score) AS AvgCreditScore,
    AVG(f.balance) AS AvgBalance
FROM fact.CustomerStatus f
INNER JOIN dim.Geography geo ON f.geography_key = geo.geography_key
INNER JOIN dim.Country c ON geo.country_key = c.country_key
GROUP BY c.country_name;
GO

-- =============================================================================
-- VISTA: Métricas de Churn por Generación
-- =============================================================================
IF OBJECT_ID('dbo.vw_ChurnByGeneration', 'V') IS NOT NULL
    DROP VIEW dbo.vw_ChurnByGeneration;
GO

CREATE VIEW dbo.vw_ChurnByGeneration
AS
SELECT
    gen.generation_name AS Generation,
    gen.birth_year_start AS BirthYearStart,
    gen.birth_year_end AS BirthYearEnd,
    COUNT(*) AS TotalCustomers,
    SUM(CAST(f.churn_flag AS INT)) AS ChurnedCustomers,
    CAST(100.0 * SUM(CAST(f.churn_flag AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS ChurnRate,
    AVG(f.credit_score) AS AvgCreditScore,
    AVG(f.balance) AS AvgBalance,
    AVG(f.tenure_years) AS AvgTenure
FROM fact.CustomerStatus f
INNER JOIN dim.Demographics d ON f.demographics_key = d.demographics_key
INNER JOIN dim.Generation gen ON d.generation_key = gen.generation_key
GROUP BY gen.generation_name, gen.birth_year_start, gen.birth_year_end;
GO

-- =============================================================================
-- VISTA: Clientes inactivos con tarjeta de crédito
-- =============================================================================
IF OBJECT_ID('dbo.vw_InactiveCustomersWithCreditCard', 'V') IS NOT NULL
    DROP VIEW dbo.vw_InactiveCustomersWithCreditCard;
GO

CREATE VIEW dbo.vw_InactiveCustomersWithCreditCard
AS
SELECT
    cust.customer_id AS CustomerID,
    c.country_name AS Country,
    gend.gender_description AS Gender,
    d.age AS Age,
    gen.generation_name AS Generation,
    f.credit_score AS CreditScore,
    f.balance AS Balance,
    f.tenure_years AS TenureYears,
    CASE WHEN f.churn_flag = 1 THEN 'Churned' ELSE 'At Risk' END AS RiskStatus
FROM fact.CustomerStatus f
INNER JOIN dim.Customer cust ON f.customer_key = cust.customer_key
INNER JOIN dim.Geography geo ON f.geography_key = geo.geography_key
INNER JOIN dim.Country c ON geo.country_key = c.country_key
INNER JOIN dim.Demographics d ON f.demographics_key = d.demographics_key
INNER JOIN dim.Gender gend ON d.gender_key = gend.gender_key
INNER JOIN dim.Generation gen ON d.generation_key = gen.generation_key
WHERE f.is_active_member = 0
  AND f.has_credit_card = 1;
GO

-- =============================================================================
-- VISTA: Resumen por Tenure
-- =============================================================================
IF OBJECT_ID('dbo.vw_TenureSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_TenureSummary;
GO

CREATE VIEW dbo.vw_TenureSummary
AS
SELECT
    f.tenure_years AS TenureYears,
    COUNT(*) AS TotalCustomers,
    SUM(CAST(f.is_active_member AS INT)) AS ActiveCustomers,
    COUNT(*) - SUM(CAST(f.is_active_member AS INT)) AS InactiveCustomers,
    SUM(CAST(f.churn_flag AS INT)) AS ChurnedCustomers,
    CAST(100.0 * SUM(CAST(f.churn_flag AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS ChurnRate,
    AVG(f.credit_score) AS AvgCreditScore,
    AVG(f.balance) AS AvgBalance
FROM fact.CustomerStatus f
GROUP BY f.tenure_years;
GO

PRINT 'Vistas creadas exitosamente.';
GO

-- Verificar vistas creadas
SELECT
    name AS ViewName,
    create_date AS CreatedDate
FROM sys.views
WHERE schema_id = SCHEMA_ID('dbo')
ORDER BY name;
GO
