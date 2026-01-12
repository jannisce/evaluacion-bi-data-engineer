-- =============================================================================
-- Script: 05_load_reference_data.sql
-- Carga de datos de referencia en tablas de dimensiones
-- =============================================================================

USE BankChurnDW;
GO

-- =============================================================================
-- CARGAR DATOS DE GÉNEROS
-- =============================================================================
INSERT INTO dim.Gender (gender_code, gender_description)
VALUES
    ('M', 'Male'),
    ('F', 'Female');
GO

-- =============================================================================
-- CARGAR DATOS DE GENERACIONES
-- =============================================================================
INSERT INTO dim.Generation (generation_name, birth_year_start, birth_year_end, generation_description)
VALUES
    ('Baby Boomers', 1946, 1964, 'Nacidos post Segunda Guerra Mundial, actualmente 60-78 años'),
    ('Generation X', 1965, 1980, 'Generación entre Boomers y Millennials, actualmente 44-59 años'),
    ('Millennials', 1981, 1996, 'Generación del milenio, nativos digitales, actualmente 28-43 años'),
    ('Generation Z', 1997, 2012, 'Centennials, generación smartphone, actualmente 12-27 años'),
    ('Silent Generation', 1928, 1945, 'Generación silenciosa, pre-Baby Boomers, 79+ años'),
    ('Unknown', 1900, 1927, 'Generación no clasificada');
GO

-- =============================================================================
-- CARGAR DATOS DE RANGOS DE EDAD
-- =============================================================================
INSERT INTO dim.AgeRange (min_age, max_age, age_range_description)
VALUES
    (18, 25, '18-25 años'),
    (26, 35, '26-35 años'),
    (36, 45, '36-45 años'),
    (46, 55, '46-55 años'),
    (56, 65, '56-65 años'),
    (66, 75, '66-75 años'),
    (76, 85, '76-85 años'),
    (86, 100, '86+ años'),
    (0, 17, 'Menor de edad');
GO

-- =============================================================================
-- CARGAR DATOS DE PAÍSES
-- =============================================================================
INSERT INTO dim.Country (country_code, country_name, continent)
VALUES
    ('FRA', 'France', 'Europe'),
    ('DEU', 'Germany', 'Europe'),
    ('ESP', 'Spain', 'Europe'),
    ('GBR', 'United Kingdom', 'Europe'),
    ('ITA', 'Italy', 'Europe'),
    ('USA', 'United States', 'North America'),
    ('CAN', 'Canada', 'North America'),
    ('MEX', 'Mexico', 'North America'),
    ('BRA', 'Brazil', 'South America'),
    ('ARG', 'Argentina', 'South America'),
    ('CHN', 'China', 'Asia'),
    ('JPN', 'Japan', 'Asia'),
    ('IND', 'India', 'Asia'),
    ('AUS', 'Australia', 'Oceania'),
    ('ZAF', 'South Africa', 'Africa');
GO

-- =============================================================================
-- CARGAR DATOS DE REGIONES
-- =============================================================================
INSERT INTO dim.Region (region_name, region_code)
VALUES
    ('Western Europe', 'WE'),
    ('Eastern Europe', 'EE'),
    ('North America', 'NA'),
    ('South America', 'SA'),
    ('Asia Pacific', 'APAC'),
    ('Middle East', 'ME'),
    ('Africa', 'AF');
GO

-- =============================================================================
-- CARGAR DATOS DE PRODUCTOS
-- =============================================================================
INSERT INTO dim.Product (products_number, product_category, product_description)
VALUES
    (1, 'Basic', 'Cliente con un producto bancario'),
    (2, 'Standard', 'Cliente con dos productos bancarios'),
    (3, 'Premium', 'Cliente con tres productos bancarios'),
    (4, 'VIP', 'Cliente con cuatro productos bancarios');
GO

-- =============================================================================
-- GENERAR DIMENSIÓN DE FECHAS (2020-2030)
-- =============================================================================
DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2030-12-31';
DECLARE @CurrentDate DATE = @StartDate;

WHILE @CurrentDate <= @EndDate
BEGIN
    INSERT INTO dim.Date (
        date_key,
        full_date,
        year,
        quarter,
        month,
        day,
        month_name,
        day_name,
        is_weekend
    )
    VALUES (
        CAST(FORMAT(@CurrentDate, 'yyyyMMdd') AS INT),
        @CurrentDate,
        YEAR(@CurrentDate),
        DATEPART(QUARTER, @CurrentDate),
        MONTH(@CurrentDate),
        DAY(@CurrentDate),
        DATENAME(MONTH, @CurrentDate),
        DATENAME(WEEKDAY, @CurrentDate),
        CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END
    );

    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END
GO

PRINT 'Datos de referencia cargados exitosamente.';
GO

-- Verificar datos cargados
SELECT 'dim.Gender' AS Tabla, COUNT(*) AS Registros FROM dim.Gender
UNION ALL
SELECT 'dim.Generation', COUNT(*) FROM dim.Generation
UNION ALL
SELECT 'dim.AgeRange', COUNT(*) FROM dim.AgeRange
UNION ALL
SELECT 'dim.Country', COUNT(*) FROM dim.Country
UNION ALL
SELECT 'dim.Region', COUNT(*) FROM dim.Region
UNION ALL
SELECT 'dim.Product', COUNT(*) FROM dim.Product
UNION ALL
SELECT 'dim.Date', COUNT(*) FROM dim.Date;
GO
