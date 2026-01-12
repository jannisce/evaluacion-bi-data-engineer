-- =============================================================================
-- Script: 07_validation_queries.sql
-- Descripción: Consultas de validación del esquema (Ejercicio 1.3)
-- =============================================================================

USE BankChurnDW;
GO

-- =============================================================================
-- CONSULTA 1: Distribución de churn por país
-- =============================================================================
PRINT '=== CONSULTA 1: Distribución de churn por país ===';
PRINT '';

SELECT
    c.country_name AS Pais,
    COUNT(*) AS TotalClientes,
    SUM(CAST(f.churn_flag AS INT)) AS ClientesChurn,
    COUNT(*) - SUM(CAST(f.churn_flag AS INT)) AS ClientesActivos,
    CAST(100.0 * SUM(CAST(f.churn_flag AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS PorcentajeChurn
FROM fact.CustomerStatus f
INNER JOIN dim.Geography g ON f.geography_key = g.geography_key
INNER JOIN dim.Country c ON g.country_key = c.country_key
GROUP BY c.country_name
ORDER BY PorcentajeChurn DESC;
GO

-- =============================================================================
-- CONSULTA 2: Análisis de churn por generación
-- (Baby Boomers, Generation X, Millennials, Generation Z)
-- =============================================================================
PRINT '';
PRINT '=== CONSULTA 2: Análisis de churn por generación ===';
PRINT '';

SELECT
    gen.generation_name AS Generacion,
    gen.birth_year_start AS AnioNacimientoInicio,
    gen.birth_year_end AS AnioNacimientoFin,
    COUNT(*) AS TotalClientes,
    SUM(CAST(f.churn_flag AS INT)) AS ClientesChurn,
    CAST(100.0 * SUM(CAST(f.churn_flag AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS PorcentajeChurn,
    AVG(f.credit_score) AS PromedioScoreCredito,
    AVG(f.balance) AS PromedioBalance
FROM fact.CustomerStatus f
INNER JOIN dim.Demographics d ON f.demographics_key = d.demographics_key
INNER JOIN dim.Generation gen ON d.generation_key = gen.generation_key
WHERE gen.generation_name IN ('Baby Boomers', 'Generation X', 'Millennials', 'Generation Z')
GROUP BY gen.generation_name, gen.birth_year_start, gen.birth_year_end
ORDER BY
    CASE gen.generation_name
        WHEN 'Baby Boomers' THEN 1
        WHEN 'Generation X' THEN 2
        WHEN 'Millennials' THEN 3
        WHEN 'Generation Z' THEN 4
    END;
GO

-- =============================================================================
-- CONSULTA 3: Historial de productos por cliente
-- =============================================================================
PRINT '';
PRINT '=== CONSULTA 3: Historial de productos por cliente ===';
PRINT '';

SELECT
    cust.customer_id AS ClienteID,
    cust.customer_name AS NombreCliente,
    p.products_number AS NumeroProductos,
    p.product_category AS CategoriaProducto,
    p.product_description AS DescripcionProducto,
    f.balance AS Balance,
    f.credit_score AS ScoreCredito,
    CASE WHEN f.churn_flag = 1 THEN 'Sí' ELSE 'No' END AS Abandono
FROM fact.CustomerStatus f
INNER JOIN dim.Customer cust ON f.customer_key = cust.customer_key
INNER JOIN dim.Product p ON f.product_key = p.product_key
ORDER BY cust.customer_id;
GO

-- Resumen de productos por cliente
PRINT '';
PRINT '=== RESUMEN: Distribución de productos ===';

SELECT
    p.products_number AS NumeroProductos,
    p.product_category AS CategoriaProducto,
    COUNT(*) AS TotalClientes,
    SUM(CAST(f.churn_flag AS INT)) AS ClientesChurn,
    CAST(100.0 * SUM(CAST(f.churn_flag AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS PorcentajeChurn
FROM fact.CustomerStatus f
INNER JOIN dim.Product p ON f.product_key = p.product_key
GROUP BY p.products_number, p.product_category
ORDER BY p.products_number;
GO

-- =============================================================================
-- CONSULTA 4: Conteo de clientes totales, activos, por año de tenure
-- =============================================================================
PRINT '';
PRINT '=== CONSULTA 4: Clientes por año de tenure ===';
PRINT '';

SELECT
    f.tenure_years AS AniosTenure,
    COUNT(*) AS TotalClientes,
    SUM(CAST(f.is_active_member AS INT)) AS ClientesActivos,
    COUNT(*) - SUM(CAST(f.is_active_member AS INT)) AS ClientesInactivos,
    CAST(100.0 * SUM(CAST(f.is_active_member AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS PorcentajeActivos,
    SUM(CAST(f.churn_flag AS INT)) AS ClientesChurn,
    CAST(100.0 * SUM(CAST(f.churn_flag AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS PorcentajeChurn
FROM fact.CustomerStatus f
GROUP BY f.tenure_years
ORDER BY f.tenure_years;
GO

-- Resumen total
PRINT '';
PRINT '=== RESUMEN TOTAL DE CLIENTES ===';

SELECT
    COUNT(*) AS TotalClientes,
    SUM(CAST(is_active_member AS INT)) AS TotalActivos,
    COUNT(*) - SUM(CAST(is_active_member AS INT)) AS TotalInactivos,
    CAST(100.0 * SUM(CAST(is_active_member AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS PorcentajeActivos
FROM fact.CustomerStatus;
GO

-- =============================================================================
-- CONSULTA 5: Clientes inactivos con tarjeta de crédito
-- =============================================================================
PRINT '';
PRINT '=== CONSULTA 5: Clientes inactivos con tarjeta de crédito ===';
PRINT '';

SELECT
    cust.customer_id AS ClienteID,
    cust.customer_name AS NombreCliente,
    c.country_name AS Pais,
    gend.gender_description AS Genero,
    d.age AS Edad,
    gen.generation_name AS Generacion,
    f.credit_score AS ScoreCredito,
    f.balance AS Balance,
    f.estimated_salary AS SalarioEstimado,
    f.tenure_years AS AniosTenure,
    CASE WHEN f.churn_flag = 1 THEN 'Sí' ELSE 'No' END AS Abandono
FROM fact.CustomerStatus f
INNER JOIN dim.Customer cust ON f.customer_key = cust.customer_key
INNER JOIN dim.Geography geo ON f.geography_key = geo.geography_key
INNER JOIN dim.Country c ON geo.country_key = c.country_key
INNER JOIN dim.Demographics d ON f.demographics_key = d.demographics_key
INNER JOIN dim.Gender gend ON d.gender_key = gend.gender_key
INNER JOIN dim.Generation gen ON d.generation_key = gen.generation_key
WHERE f.is_active_member = 0
  AND f.has_credit_card = 1
ORDER BY f.balance DESC;
GO

-- Resumen de clientes inactivos con tarjeta
PRINT '';
PRINT '=== RESUMEN: Clientes inactivos con tarjeta de crédito ===';

SELECT
    COUNT(*) AS TotalClientesInactivosConTarjeta,
    SUM(CAST(f.churn_flag AS INT)) AS ChurnEnGrupo,
    CAST(100.0 * SUM(CAST(f.churn_flag AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS PorcentajeChurn,
    AVG(f.balance) AS PromedioBalance,
    AVG(f.credit_score) AS PromedioScoreCredito
FROM fact.CustomerStatus f
WHERE f.is_active_member = 0
  AND f.has_credit_card = 1;
GO

-- =============================================================================
-- CONSULTA 6: Total de clientes activos e inactivos por país, género y rango de edad
-- =============================================================================
PRINT '';
PRINT '=== CONSULTA 6: Clientes por país, género y rango de edad ===';
PRINT '';

SELECT
    c.country_name AS Pais,
    gend.gender_description AS Genero,
    ar.age_range_description AS RangoEdad,
    COUNT(*) AS TotalClientes,
    SUM(CAST(f.is_active_member AS INT)) AS ClientesActivos,
    COUNT(*) - SUM(CAST(f.is_active_member AS INT)) AS ClientesInactivos,
    SUM(CAST(f.churn_flag AS INT)) AS ClientesChurn,
    CAST(100.0 * SUM(CAST(f.churn_flag AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS PorcentajeChurn
FROM fact.CustomerStatus f
INNER JOIN dim.Geography geo ON f.geography_key = geo.geography_key
INNER JOIN dim.Country c ON geo.country_key = c.country_key
INNER JOIN dim.Demographics d ON f.demographics_key = d.demographics_key
INNER JOIN dim.Gender gend ON d.gender_key = gend.gender_key
INNER JOIN dim.AgeRange ar ON d.age_range_key = ar.age_range_key
GROUP BY c.country_name, gend.gender_description, ar.age_range_description, ar.min_age
ORDER BY c.country_name, gend.gender_description, ar.min_age;
GO

-- Pivot por país y género
PRINT '';
PRINT '=== RESUMEN PIVOT: Por país y género ===';

SELECT
    c.country_name AS Pais,
    SUM(CASE WHEN gend.gender_code = 'M' AND f.is_active_member = 1 THEN 1 ELSE 0 END) AS Hombres_Activos,
    SUM(CASE WHEN gend.gender_code = 'M' AND f.is_active_member = 0 THEN 1 ELSE 0 END) AS Hombres_Inactivos,
    SUM(CASE WHEN gend.gender_code = 'F' AND f.is_active_member = 1 THEN 1 ELSE 0 END) AS Mujeres_Activas,
    SUM(CASE WHEN gend.gender_code = 'F' AND f.is_active_member = 0 THEN 1 ELSE 0 END) AS Mujeres_Inactivas,
    COUNT(*) AS Total
FROM fact.CustomerStatus f
INNER JOIN dim.Geography geo ON f.geography_key = geo.geography_key
INNER JOIN dim.Country c ON geo.country_key = c.country_key
INNER JOIN dim.Demographics d ON f.demographics_key = d.demographics_key
INNER JOIN dim.Gender gend ON d.gender_key = gend.gender_key
GROUP BY c.country_name
ORDER BY c.country_name;
GO

-- =============================================================================
-- CONSULTAS ADICIONALES DE VALIDACIÓN
-- =============================================================================
PRINT '';
PRINT '=== VALIDACIONES ADICIONALES ===';
PRINT '';

-- Verificar integridad referencial
SELECT 'Hechos sin cliente válido' AS Validacion,
       COUNT(*) AS Problemas
FROM fact.CustomerStatus f
LEFT JOIN dim.Customer c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL
UNION ALL
SELECT 'Hechos sin geografía válida',
       COUNT(*)
FROM fact.CustomerStatus f
LEFT JOIN dim.Geography g ON f.geography_key = g.geography_key
WHERE g.geography_key IS NULL
UNION ALL
SELECT 'Hechos sin demografía válida',
       COUNT(*)
FROM fact.CustomerStatus f
LEFT JOIN dim.Demographics d ON f.demographics_key = d.demographics_key
WHERE d.demographics_key IS NULL;
GO

-- Resumen general del Data Warehouse
PRINT '';
PRINT '=== RESUMEN GENERAL DEL DATA WAREHOUSE ===';

SELECT
    (SELECT COUNT(*) FROM fact.CustomerStatus) AS TotalHechos,
    (SELECT COUNT(*) FROM dim.Customer) AS TotalClientes,
    (SELECT COUNT(*) FROM dim.Geography) AS TotalGeografias,
    (SELECT COUNT(*) FROM dim.Demographics) AS TotalDemografias,
    (SELECT COUNT(*) FROM dim.Country) AS TotalPaises,
    (SELECT COUNT(*) FROM dim.Generation) AS TotalGeneraciones;
GO

PRINT '';
PRINT '=== FIN DE CONSULTAS DE VALIDACIÓN ===';
GO
